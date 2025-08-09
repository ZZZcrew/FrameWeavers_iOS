import cv2
import os
import numpy as np
import asyncio
import psutil
import threading
import concurrent.futures
from typing import List, Dict, Optional, Tuple, Union, Callable, Awaitable
import time
from datetime import datetime
import logging
import json
from collections import deque
import gc
import weakref

# 配置日志
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# 确保OpenCV使用CPU后端，优化CPU性能
cv2.setUseOptimized(True)
cv2.setNumThreads(0)

# 无头环境配置
os.environ['OPENCV_IO_ENABLE_OPENEXR'] = '0'
os.environ['OPENCV_IO_ENABLE_JASPER'] = '0'

# =============================================================================
# 设备性能检测模块
# =============================================================================

class DevicePerformanceDetector:
    """设备性能检测器"""
    
    def __init__(self):
        self.cpu_count = psutil.cpu_count(logical=False)  # 物理CPU核心数
        self.logical_cpu_count = psutil.cpu_count(logical=True)  # 逻辑CPU核心数
        self.total_memory = psutil.virtual_memory().total
        self.available_memory = psutil.virtual_memory().available
        
    def get_performance_profile(self) -> Dict[str, any]:
        """获取设备性能档案"""
        try:
            # CPU信息
            cpu_percent = psutil.cpu_percent(interval=1)
            memory_info = psutil.virtual_memory()
            disk_info = psutil.disk_usage('/')
            
            # 基于硬件配置计算性能等级
            performance_level = self._calculate_performance_level()
            
            # 根据性能等级调整并发参数
            concurrency_config = self._get_concurrency_config(performance_level)
            
            profile = {
                'cpu_cores_physical': self.cpu_count,
                'cpu_cores_logical': self.logical_cpu_count,
                'cpu_usage_percent': cpu_percent,
                'memory_total_gb': round(self.total_memory / (1024**3), 2),
                'memory_available_gb': round(memory_info.available / (1024**3), 2),
                'memory_usage_percent': memory_info.percent,
                'disk_free_gb': round(disk_info.free / (1024**3), 2),
                'performance_level': performance_level,
                'concurrency_config': concurrency_config,
                'recommended_batch_size': concurrency_config['batch_size'],
                'max_workers': concurrency_config['max_workers']
            }
            
            logger.info(f"🔍 设备性能检测完成 - 性能等级: {performance_level}")
            return profile
            
        except Exception as e:
            logger.warning(f"性能检测失败: {e}, 使用默认配置")
            return self._get_default_profile()
    
    def _calculate_performance_level(self) -> str:
        """计算性能等级"""
        memory_gb = self.total_memory / (1024**3)
        
        # 根据CPU核心数和内存判断性能等级
        if self.cpu_count >= 8 and memory_gb >= 16:
            return "high"
        elif self.cpu_count >= 4 and memory_gb >= 8:
            return "medium"
        elif self.cpu_count >= 2 and memory_gb >= 4:
            return "low"
        else:
            return "minimal"
    
    def _get_concurrency_config(self, performance_level: str) -> Dict[str, int]:
        """根据性能等级获取并发配置"""
        configs = {
            "high": {
                "max_workers": min(self.cpu_count * 2, 16),
                "batch_size": 8,
                "memory_buffer_mb": 2048,
                "io_workers": 4
            },
            "medium": {
                "max_workers": min(self.cpu_count + 2, 8),
                "batch_size": 4,
                "memory_buffer_mb": 1024,
                "io_workers": 2
            },
            "low": {
                "max_workers": min(self.cpu_count, 4),
                "batch_size": 2,
                "memory_buffer_mb": 512,
                "io_workers": 1
            },
            "minimal": {
                "max_workers": 2,
                "batch_size": 1,
                "memory_buffer_mb": 256,
                "io_workers": 1
            }
        }
        return configs.get(performance_level, configs["low"])
    
    def _get_default_profile(self) -> Dict[str, any]:
        """获取默认性能档案"""
        return {
            'cpu_cores_physical': 4,
            'cpu_cores_logical': 8,
            'cpu_usage_percent': 50.0,
            'memory_total_gb': 8.0,
            'memory_available_gb': 4.0,
            'memory_usage_percent': 50.0,
            'disk_free_gb': 10.0,
            'performance_level': 'medium',
            'concurrency_config': {
                'max_workers': 4,
                'batch_size': 2,
                'memory_buffer_mb': 512,
                'io_workers': 1
            },
            'recommended_batch_size': 2,
            'max_workers': 4
        }

# =============================================================================
# 异步抽帧器配置
# =============================================================================

class AsyncFrameExtractorConfig:
    """异步抽帧器配置常量"""
    
    # 继承所有原始配置
    SUPPORTED_VIDEO_FORMATS = {'.mp4', '.avi', '.mov', '.mkv', '.wmv', '.flv', '.webm', '.m4v'}
    SUPPORTED_IMAGE_FORMATS = {'.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.tif', '.webp'}
    
    DEFAULT_OUTPUT_DIR = "async_frames"
    DEFAULT_MAX_FILE_SIZE_MB = 500
    DEFAULT_QUALITY = 95
    DEFAULT_SHARPNESS_THRESHOLD = 100.0
    DEFAULT_SIMILARITY_THRESHOLD = 15.0
    DEFAULT_MAX_BASE_FRAMES = 80
    DEFAULT_SCENE_SENSITIVITY = 'high'
    
    # 异步处理配置
    DEFAULT_TIMEOUT_SECONDS = 3600  # 1小时超时
    PROGRESS_UPDATE_INTERVAL = 0.5  # 进度更新间隔（秒）
    MEMORY_CHECK_INTERVAL = 100     # 每处理100帧检查内存
    MAX_MEMORY_USAGE_PERCENT = 80   # 最大内存使用率
    
    # 时间间隔配置（秒）
    INTERVAL_ULTRA_SHORT = 0.2
    INTERVAL_SHORT = 0.5
    INTERVAL_MEDIUM_SHORT = 0.8
    INTERVAL_MEDIUM = 1.0
    INTERVAL_LONG = 1.5
    INTERVAL_VERY_LONG = 2.0
    INTERVAL_EXTRA_LONG = 2.5
    INTERVAL_HOUR = 3.0
    INTERVAL_SUPER_LONG = 4.0
    
    # 时长分类阈值（秒）
    DURATION_ULTRA_SHORT = 3
    DURATION_SHORT = 10
    DURATION_MEDIUM_SHORT = 30
    DURATION_MEDIUM = 120
    DURATION_LONG = 300
    DURATION_VERY_LONG = 600
    DURATION_EXTRA_LONG = 1800
    DURATION_HOUR = 3600
    
    # 帧率分类阈值
    FPS_LOW = 15
    FPS_STANDARD = 30
    FPS_HIGH = 60
    
    # 帧率修正因子
    FPS_FACTOR_LOW = 0.8
    FPS_FACTOR_STANDARD_HIGH = 1.15
    FPS_FACTOR_HIGH = 1.3
    
    # 质量评分权重
    QUALITY_WEIGHT_SHARPNESS = 0.5
    QUALITY_WEIGHT_CONTRAST = 0.3
    QUALITY_WEIGHT_BRIGHTNESS = 0.2
    
    # 场景检测阈值配置
    SCENE_THRESHOLDS = {
        'low': {
            'pixel_threshold': 40.0,
            'histogram_threshold': 1000.0,
            'structural_threshold': 15.0,
            'edge_threshold': 25.0,
            'color_threshold': 800.0
        },
        'medium': {
            'pixel_threshold': 25.0,
            'histogram_threshold': 500.0,
            'structural_threshold': 10.0,
            'edge_threshold': 15.0,
            'color_threshold': 400.0
        },
        'high': {
            'pixel_threshold': 15.0,
            'histogram_threshold': 200.0,
            'structural_threshold': 8.0,
            'edge_threshold': 10.0,
            'color_threshold': 200.0
        },
        'ultra': {
            'pixel_threshold': 10.0,
            'histogram_threshold': 100.0,
            'structural_threshold': 5.0,
            'edge_threshold': 8.0,
            'color_threshold': 100.0
        }
    }
    
    # 变化强度阈值
    INTENSITY_THRESHOLDS = {
        'low': 15.0,
        'medium': 25.0,
        'high': 40.0,
        'ultra': 60.0
    }
    
    # 其他配置
    MIN_FRAME_COUNT = 5
    MAX_FRAME_PERCENTAGE = 0.5
    MEMORY_CLEANUP_INTERVAL = 1000
    COMPARE_FRAME_SIZE = (160, 90)
    
    # 文件大小单位
    BYTES_TO_KB = 1024
    BYTES_TO_MB = 1024 * 1024

# =============================================================================
# 异步进度监控
# =============================================================================

class AsyncProgressMonitor:
    """异步进度监控器"""
    
    def __init__(self, total_files: int, update_interval: float = 0.5):
        self.total_files = total_files
        self.completed_files = 0
        self.current_file = ""
        self.current_progress = 0.0
        self.start_time = time.time()
        self.update_interval = update_interval
        self.callbacks = []
        self._lock = threading.Lock()
    
    def add_callback(self, callback: Callable[[Dict[str, any]], Awaitable[None]]):
        """添加进度回调函数"""
        self.callbacks.append(callback)
    
    async def update_file_progress(self, filename: str, progress: float):
        """更新当前文件进度"""
        with self._lock:
            self.current_file = filename
            self.current_progress = progress
        await self._notify_callbacks()
    
    async def complete_file(self, filename: str):
        """完成一个文件"""
        with self._lock:
            self.completed_files += 1
            self.current_file = filename
            self.current_progress = 100.0
        await self._notify_callbacks()
    
    async def _notify_callbacks(self):
        """通知所有回调函数"""
        if not self.callbacks:
            return
        
        progress_data = self.get_progress_data()
        
        # 异步执行所有回调
        tasks = []
        for callback in self.callbacks:
            tasks.append(asyncio.create_task(callback(progress_data)))
        
        if tasks:
            await asyncio.gather(*tasks, return_exceptions=True)
    
    def get_progress_data(self) -> Dict[str, any]:
        """获取进度数据"""
        elapsed_time = time.time() - self.start_time
        overall_progress = (self.completed_files / self.total_files * 100) if self.total_files > 0 else 0
        
        return {
            'total_files': self.total_files,
            'completed_files': self.completed_files,
            'current_file': self.current_file,
            'current_file_progress': self.current_progress,
            'overall_progress': overall_progress,
            'elapsed_time': elapsed_time,
            'estimated_remaining': self._estimate_remaining_time(elapsed_time, overall_progress)
        }
    
    def _estimate_remaining_time(self, elapsed: float, progress: float) -> float:
        """估算剩余时间"""
        if progress <= 0:
            return 0
        total_estimated = elapsed * 100 / progress
        return max(0, total_estimated - elapsed)

# =============================================================================
# 异步抽帧器主类
# =============================================================================

class AsyncFrameExtractor:
    """异步视频抽帧器"""
    
    def __init__(self, output_dir: str = None, max_file_size_mb: int = None, 
                 auto_detect_performance: bool = True):
        """初始化异步抽帧器"""
        self.output_dir = output_dir or AsyncFrameExtractorConfig.DEFAULT_OUTPUT_DIR
        self.max_file_size_mb = max_file_size_mb or AsyncFrameExtractorConfig.DEFAULT_MAX_FILE_SIZE_MB
        self.max_file_size_bytes = self.max_file_size_mb * AsyncFrameExtractorConfig.BYTES_TO_MB
        
        os.makedirs(self.output_dir, exist_ok=True)
        
        # 所有支持的格式
        self.supported_formats = (AsyncFrameExtractorConfig.SUPPORTED_VIDEO_FORMATS | 
                                 AsyncFrameExtractorConfig.SUPPORTED_IMAGE_FORMATS)
        
        # 设备性能检测
        self.performance_detector = DevicePerformanceDetector()
        if auto_detect_performance:
            self.performance_profile = self.performance_detector.get_performance_profile()
        else:
            self.performance_profile = self.performance_detector._get_default_profile()
        
        # 线程池和资源管理
        self.thread_pool = None
        self.semaphore = None
        self._setup_resources()
        
        logger.info(f"✓ 异步抽帧器初始化完成 - 输出目录: {self.output_dir}")
        logger.info(f"🔧 性能配置: {self.performance_profile['performance_level']} | "
                   f"最大工作线程: {self.performance_profile['max_workers']} | "
                   f"批处理大小: {self.performance_profile['recommended_batch_size']}")
    
    def _setup_resources(self):
        """设置资源管理"""
        config = self.performance_profile['concurrency_config']
        
        # 创建线程池
        self.thread_pool = concurrent.futures.ThreadPoolExecutor(
            max_workers=config['max_workers'],
            thread_name_prefix="FrameExtractor"
        )
        
        # 创建信号量限制并发
        self.semaphore = asyncio.Semaphore(config['batch_size'])
    
    async def __aenter__(self):
        """异步上下文管理器入口"""
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """异步上下文管理器出口"""
        await self.cleanup()
    
    async def cleanup(self):
        """清理资源"""
        if self.thread_pool:
            self.thread_pool.shutdown(wait=True)
            self.thread_pool = None
        
        # 强制垃圾回收
        gc.collect()
        logger.info("🧹 资源清理完成")
    
    def generate_task_id(self, device_id: str) -> str:
        """生成任务ID"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")[:-3]
        return f"{timestamp}_{device_id}"
    
    def create_task_output_dir(self, task_id: str) -> str:
        """创建任务输出目录"""
        task_output_dir = os.path.join(self.output_dir, task_id)
        os.makedirs(task_output_dir, exist_ok=True)
        return task_output_dir
    
    async def validate_file(self, file_path: str) -> Dict[str, any]:
        """异步文件验证"""
        def _sync_validate():
            result = {'valid': False, 'error': None, 'file_info': {}}
            
            try:
                # 基础检查
                if not os.path.exists(file_path):
                    result['error'] = f"文件不存在: {file_path}"
                    return result
                
                file_ext = os.path.splitext(file_path)[1].lower()
                if file_ext not in self.supported_formats:
                    result['error'] = f"不支持的文件格式: {file_ext}"
                    return result
                
                file_size = os.path.getsize(file_path)
                if file_size > self.max_file_size_bytes:
                    result['error'] = f"文件过大: {file_size/AsyncFrameExtractorConfig.BYTES_TO_MB:.1f}MB"
                    return result
                
                # 判断文件类型并获取信息
                if file_ext in AsyncFrameExtractorConfig.SUPPORTED_VIDEO_FORMATS:
                    return self._validate_video_sync(file_path, file_size, file_ext)
                else:
                    return self._validate_image_sync(file_path, file_size, file_ext)
                    
            except Exception as e:
                result['error'] = f"验证出错: {str(e)}"
                return result
        
        # 在线程池中执行同步验证
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(self.thread_pool, _sync_validate)
    
    def _validate_video_sync(self, file_path: str, file_size: int, file_ext: str) -> Dict[str, any]:
        """同步验证视频文件"""
        result = {'valid': False, 'error': None, 'file_info': {}}
        
        cap = cv2.VideoCapture(file_path)
        if not cap.isOpened():
            result['error'] = "无法打开视频文件"
            return result
        
        try:
            total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
            fps = cap.get(cv2.CAP_PROP_FPS)
            width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
            height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
            
            if total_frames <= 0 or fps <= 0 or width <= 0 or height <= 0:
                result['error'] = "视频参数异常"
                return result
            
            result['valid'] = True
            result['file_info'] = {
                'file_path': file_path,
                'file_name': os.path.basename(file_path),
                'file_size_mb': file_size / AsyncFrameExtractorConfig.BYTES_TO_MB,
                'file_extension': file_ext,
                'file_type': 'video',
                'total_frames': total_frames,
                'fps': fps,
                'width': width,
                'height': height,
                'duration_seconds': total_frames / fps,
                'resolution': f"{width}x{height}"
            }
            
        finally:
            cap.release()
            
        return result
    
    def _validate_image_sync(self, file_path: str, file_size: int, file_ext: str) -> Dict[str, any]:
        """同步验证图片文件"""
        result = {'valid': False, 'error': None, 'file_info': {}}
        
        image = cv2.imread(file_path)
        if image is None:
            result['error'] = "无法读取图片文件"
            return result
        
        height, width = image.shape[:2]
        channels = image.shape[2] if len(image.shape) == 3 else 1
        
        if width <= 0 or height <= 0:
            result['error'] = "图片尺寸异常"
            return result
        
        result['valid'] = True
        result['file_info'] = {
            'file_path': file_path,
            'file_name': os.path.basename(file_path),
            'file_size_mb': file_size / AsyncFrameExtractorConfig.BYTES_TO_MB,
            'file_extension': file_ext,
            'file_type': 'image',
            'width': width,
            'height': height,
            'channels': channels,
            'resolution': f"{width}x{height}"
        }
        
        return result
    
    def calculate_optimal_frame_count(self, duration: float, fps: float, total_frames: int) -> Dict[str, any]:
        """优化的抽帧数量计算（同步方法）"""
        # 根据时长确定间隔和策略
        if duration <= AsyncFrameExtractorConfig.DURATION_ULTRA_SHORT:
            interval = AsyncFrameExtractorConfig.INTERVAL_ULTRA_SHORT
            strategy = "极短视频超密集采样"
        elif duration <= AsyncFrameExtractorConfig.DURATION_SHORT:
            interval = AsyncFrameExtractorConfig.INTERVAL_SHORT
            strategy = "短视频密集采样"
        elif duration <= AsyncFrameExtractorConfig.DURATION_MEDIUM_SHORT:
            interval = AsyncFrameExtractorConfig.INTERVAL_MEDIUM_SHORT
            strategy = "中短视频密集采样"
        elif duration <= AsyncFrameExtractorConfig.DURATION_MEDIUM:
            interval = AsyncFrameExtractorConfig.INTERVAL_MEDIUM
            strategy = "中等视频标准采样"
        elif duration <= AsyncFrameExtractorConfig.DURATION_LONG:
            interval = AsyncFrameExtractorConfig.INTERVAL_LONG
            strategy = "长视频密集采样"
        elif duration <= AsyncFrameExtractorConfig.DURATION_VERY_LONG:
            interval = AsyncFrameExtractorConfig.INTERVAL_VERY_LONG
            strategy = "超长视频采样"
        elif duration <= AsyncFrameExtractorConfig.DURATION_EXTRA_LONG:
            interval = AsyncFrameExtractorConfig.INTERVAL_EXTRA_LONG
            strategy = "30分钟视频采样"
        elif duration <= AsyncFrameExtractorConfig.DURATION_HOUR:
            interval = AsyncFrameExtractorConfig.INTERVAL_HOUR
            strategy = "1小时视频采样"
        else:
            interval = AsyncFrameExtractorConfig.INTERVAL_SUPER_LONG
            strategy = "超长视频采样"
        
        optimal_frames = max(AsyncFrameExtractorConfig.MIN_FRAME_COUNT, int(duration / interval))
        
        # 帧率修正
        fps_factor = 1.0
        if fps < AsyncFrameExtractorConfig.FPS_LOW:
            fps_factor = AsyncFrameExtractorConfig.FPS_FACTOR_LOW
        elif fps > AsyncFrameExtractorConfig.FPS_HIGH:
            fps_factor = AsyncFrameExtractorConfig.FPS_FACTOR_HIGH
        elif fps > AsyncFrameExtractorConfig.FPS_STANDARD:
            fps_factor = AsyncFrameExtractorConfig.FPS_FACTOR_STANDARD_HIGH
        
        optimal_frames = int(optimal_frames * fps_factor)
        
        # 总帧数限制
        max_allowed = min(total_frames, int(total_frames * AsyncFrameExtractorConfig.MAX_FRAME_PERCENTAGE))
        optimal_frames = min(optimal_frames, max_allowed)
        
        frame_interval = max(1, total_frames // optimal_frames)
        real_interval = duration / optimal_frames if optimal_frames > 0 else interval
        
        return {
            'optimal_frames': optimal_frames,
            'frame_interval': frame_interval,
            'real_time_interval': real_interval,
            'strategy': strategy
        }
    
    def calculate_frame_quality(self, frame: np.ndarray) -> Dict[str, float]:
        """计算帧质量指标（同步方法）"""
        # 转换为灰度图
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY) if len(frame.shape) == 3 else frame
        
        # 清晰度（拉普拉斯方差）
        sharpness = cv2.Laplacian(gray, cv2.CV_64F).var()
        
        # 亮度和对比度
        brightness = np.mean(gray)
        contrast = np.std(gray)
        
        # 综合质量分
        quality_score = (
            sharpness * AsyncFrameExtractorConfig.QUALITY_WEIGHT_SHARPNESS +
            contrast * AsyncFrameExtractorConfig.QUALITY_WEIGHT_CONTRAST +
            min(brightness / 128.0, 1.0) * AsyncFrameExtractorConfig.QUALITY_WEIGHT_BRIGHTNESS
        )
        
        return {
            'sharpness': sharpness,
            'brightness': brightness,
            'contrast': contrast,
            'quality_score': quality_score
        }
    
    def detect_scene_change(self, frame1: np.ndarray, frame2: np.ndarray, 
                          sensitivity: str = 'high') -> Dict[str, any]:
        """简化的场景变化检测（同步方法）"""
        # 转换为灰度图并确保尺寸一致
        gray1 = cv2.cvtColor(frame1, cv2.COLOR_BGR2GRAY) if len(frame1.shape) == 3 else frame1
        gray2 = cv2.cvtColor(frame2, cv2.COLOR_BGR2GRAY) if len(frame2.shape) == 3 else frame2
        
        if gray1.shape != gray2.shape:
            gray2 = cv2.resize(gray2, (gray1.shape[1], gray1.shape[0]))
        
        # 计算像素差异
        pixel_diff = np.mean(cv2.absdiff(gray1, gray2))
        
        # 计算直方图差异
        hist1 = cv2.calcHist([gray1], [0], None, [256], [0, 256])
        hist2 = cv2.calcHist([gray2], [0], None, [256], [0, 256])
        hist_diff = cv2.compareHist(hist1, hist2, cv2.HISTCMP_CHISQR)
        
        # 获取阈值
        thresholds = AsyncFrameExtractorConfig.SCENE_THRESHOLDS.get(sensitivity, 
                                                             AsyncFrameExtractorConfig.SCENE_THRESHOLDS['high'])
        
        # 判断场景变化
        pixel_change = pixel_diff > thresholds['pixel_threshold']
        hist_change = hist_diff > thresholds['histogram_threshold']
        
        # 综合判断
        is_scene_change = pixel_change or hist_change
        
        # 计算变化强度
        change_intensity = (
            pixel_diff / thresholds['pixel_threshold'] * 0.6 +
            hist_diff / thresholds['histogram_threshold'] * 0.4
        )
        
        return {
            'is_scene_change': is_scene_change,
            'change_intensity': change_intensity,
            'pixel_difference': pixel_diff,
            'histogram_difference': hist_diff
        }
    
    def resize_frame(self, frame: np.ndarray, max_resolution: tuple) -> np.ndarray:
        """调整帧分辨率（同步方法）"""
        if max_resolution is None:
            return frame
            
        height, width = frame.shape[:2]
        max_width, max_height = max_resolution
        
        scale = min(max_width / width, max_height / height, 1.0)
        
        if scale < 1.0:
            new_width = int(width * scale)
            new_height = int(height * scale)
            frame = cv2.resize(frame, (new_width, new_height), interpolation=cv2.INTER_AREA)
        
        return frame
    
    async def extract_frames_async(self, video_path: str, progress_monitor: AsyncProgressMonitor = None, **kwargs) -> Dict[str, any]:
        """异步视频抽帧方法"""
        async with self.semaphore:  # 限制并发
            logger.info(f"🎬 开始异步抽帧: {os.path.basename(video_path)}")
            start_time = time.time()
            
            # 获取参数
            quality = kwargs.get('quality', AsyncFrameExtractorConfig.DEFAULT_QUALITY)
            max_resolution = kwargs.get('max_resolution')
            sharpness_threshold = kwargs.get('sharpness_threshold', AsyncFrameExtractorConfig.DEFAULT_SHARPNESS_THRESHOLD)
            similarity_threshold = kwargs.get('similarity_threshold', AsyncFrameExtractorConfig.DEFAULT_SIMILARITY_THRESHOLD)
            scene_sensitivity = kwargs.get('scene_sensitivity', AsyncFrameExtractorConfig.DEFAULT_SCENE_SENSITIVITY)
            max_base_frames = kwargs.get('max_base_frames', AsyncFrameExtractorConfig.DEFAULT_MAX_BASE_FRAMES)
            
            # 验证文件
            validation = await self.validate_file(video_path)
            if not validation['valid']:
                return {'success': False, 'error': validation['error']}
            
            video_info = validation['file_info']
            if video_info['file_type'] != 'video':
                return {'success': False, 'error': '不是视频文件'}
            
            # 计算抽帧参数
            calc_result = self.calculate_optimal_frame_count(
                video_info['duration_seconds'], 
                video_info['fps'], 
                video_info['total_frames']
            )
            
            # 在线程池中执行实际的帧提取
            def _extract_frames():
                return self._extract_frames_sync(
                    video_path, video_info, calc_result, quality, max_resolution,
                    sharpness_threshold, similarity_threshold, scene_sensitivity,
                    max_base_frames, progress_monitor
                )
            
            loop = asyncio.get_event_loop()
            result = await loop.run_in_executor(self.thread_pool, _extract_frames)
            
            processing_time = time.time() - start_time
            
            if result['success']:
                logger.info(f"✅ 异步抽帧完成: {len(result['frame_paths'])} 帧, 耗时 {processing_time:.2f}秒")
                result['processing_time'] = processing_time
                result['calculation_result'] = calc_result
            
            return result
    
    def _extract_frames_sync(self, video_path: str, video_info: Dict, calc_result: Dict,
                           quality: int, max_resolution: tuple, sharpness_threshold: float,
                           similarity_threshold: float, scene_sensitivity: str,
                           max_base_frames: int, progress_monitor: AsyncProgressMonitor = None) -> Dict[str, any]:
        """同步帧提取核心逻辑"""
        cap = cv2.VideoCapture(video_path)
        if not cap.isOpened():
            return {'success': False, 'error': '无法打开视频'}
        
        try:
            frame_paths = []
            frame_count = 0
            extracted_count = 0
            previous_frame = None
            last_progress_update = 0
            
            jpeg_params = [cv2.IMWRITE_JPEG_QUALITY, quality]
            frame_interval = calc_result['frame_interval']
            total_frames = video_info['total_frames']
            
            while True:
                ret, frame = cap.read()
                if not ret:
                    break
                
                # 更新进度
                if progress_monitor and time.time() - last_progress_update > AsyncFrameExtractorConfig.PROGRESS_UPDATE_INTERVAL:
                    progress = (frame_count / total_frames) * 100
                    # 注意：这里不能直接调用异步方法，需要在外层处理
                    last_progress_update = time.time()
                
                # 均匀抽帧
                if frame_count % frame_interval == 0:
                    # 调整分辨率
                    processed_frame = self.resize_frame(frame, max_resolution)
                    
                    # 质量评估
                    quality_metrics = self.calculate_frame_quality(processed_frame)
                    
                    # 判断是否保留
                    should_keep = self._should_keep_frame(
                        processed_frame, previous_frame, quality_metrics,
                        sharpness_threshold, similarity_threshold, scene_sensitivity
                    )
                    
                    if should_keep:
                        # 保存帧
                        timestamp = frame_count / video_info['fps']
                        filename = f"frame_{extracted_count:04d}_{timestamp:.2f}s.jpg"
                        filepath = os.path.join(self.output_dir, filename)
                        
                        if cv2.imwrite(filepath, processed_frame, jpeg_params):
                            frame_info = {
                                'path': filepath,
                                'filename': filename,
                                'frame_number': frame_count,
                                'timestamp': timestamp,
                                'extracted_index': extracted_count,
                                'quality_metrics': quality_metrics,
                                'source_type': 'video',
                                'source_file': os.path.basename(video_path)
                            }
                            frame_paths.append(frame_info)
                            
                            # 更新前一帧用于比较
                            previous_frame = cv2.resize(processed_frame, AsyncFrameExtractorConfig.COMPARE_FRAME_SIZE)
                            extracted_count += 1
                            
                            # 达到最大帧数则退出
                            if extracted_count >= max_base_frames:
                                break
                
                frame_count += 1
                
                # 定期内存检查
                if frame_count % AsyncFrameExtractorConfig.MEMORY_CHECK_INTERVAL == 0:
                    memory_percent = psutil.virtual_memory().percent
                    if memory_percent > AsyncFrameExtractorConfig.MAX_MEMORY_USAGE_PERCENT:
                        logger.warning(f"内存使用率过高 ({memory_percent:.1f}%), 执行垃圾回收")
                        gc.collect()
        
        finally:
            cap.release()
        
        return {
            'success': True,
            'video_info': video_info,
            'frame_paths': frame_paths
        }
    
    def _should_keep_frame(self, frame: np.ndarray, previous_frame: Optional[np.ndarray], 
                          quality_metrics: Dict[str, float], sharpness_threshold: float,
                          similarity_threshold: float, scene_sensitivity: str) -> bool:
        """判断是否保留帧（同步方法）"""
        # 第一帧总是保留
        if previous_frame is None:
            return True
        
        # 清晰度检查
        if quality_metrics['sharpness'] < sharpness_threshold:
            return False
        
        # 场景变化检测
        scene_result = self.detect_scene_change(previous_frame, frame, scene_sensitivity)
        
        # 如果发生场景变化，检查变化强度
        if scene_result['is_scene_change']:
            intensity_threshold = AsyncFrameExtractorConfig.INTENSITY_THRESHOLDS.get(scene_sensitivity, 40.0)
            return scene_result['change_intensity'] >= intensity_threshold
        
        # 如果没有场景变化，检查像素差异
        return scene_result['pixel_difference'] >= similarity_threshold
    
    async def process_image_file_async(self, image_path: str, **kwargs) -> Dict[str, any]:
        """异步处理图片文件"""
        async with self.semaphore:  # 限制并发
            def _process_image():
                quality = kwargs.get('quality', AsyncFrameExtractorConfig.DEFAULT_QUALITY)
                max_resolution = kwargs.get('max_resolution')
                
                # 读取和处理图片
                image = cv2.imread(image_path)
                if image is None:
                    return {'success': False, 'error': '无法读取图片文件'}
                
                processed_image = self.resize_frame(image, max_resolution)
                quality_metrics = self.calculate_frame_quality(processed_image)
                
                # 生成输出文件名
                base_name = os.path.splitext(os.path.basename(image_path))[0]
                output_filename = f"image_{base_name}.jpg"
                output_path = os.path.join(self.output_dir, output_filename)
                
                # 保存图片
                jpeg_params = [cv2.IMWRITE_JPEG_QUALITY, quality]
                if cv2.imwrite(output_path, processed_image, jpeg_params):
                    return {
                        'success': True,
                        'file_type': 'image',
                        'output_info': {
                            'path': output_path,
                            'filename': output_filename,
                            'quality_metrics': quality_metrics
                        }
                    }
                else:
                    return {'success': False, 'error': '保存图片失败'}
            
            # 验证图片
            validation = await self.validate_file(image_path)
            if not validation['valid']:
                return {'success': False, 'error': validation['error']}
            
            file_info = validation['file_info']
            if file_info['file_type'] != 'image':
                return {'success': False, 'error': '不是图片文件'}
            
            # 在线程池中处理图片
            loop = asyncio.get_event_loop()
            return await loop.run_in_executor(self.thread_pool, _process_image)
    
    async def process_multiple_files_async(self, input_paths: List[str], device_id: str = None, 
                                         task_id: str = None, progress_callback: Callable = None,
                                         **kwargs) -> Dict[str, any]:
        """异步处理多个文件（核心并行处理方法）"""
        # 处理任务ID
        if task_id is None:
            device_id = device_id or "async_device"
            task_id = self.generate_task_id(device_id)
        
        # 创建任务目录
        task_output_dir = self.create_task_output_dir(task_id)
        original_output_dir = self.output_dir
        self.output_dir = task_output_dir
        
        # 设置进度监控
        progress_monitor = AsyncProgressMonitor(len(input_paths))
        if progress_callback:
            progress_monitor.add_callback(progress_callback)
        
        logger.info(f"🚀 开始异步并行处理 {len(input_paths)} 个文件 - 任务ID: {task_id}")
        logger.info(f"⚙️ 并行配置: 最大工作线程 {self.performance_profile['max_workers']}, "
                   f"批处理大小 {self.performance_profile['recommended_batch_size']}")
        
        start_time = time.time()
        
        try:
            all_frame_paths = []
            success_count = 0
            failed_count = 0
            
            # 创建处理任务
            async def process_single_file(file_path: str) -> Tuple[str, Dict[str, any]]:
                """处理单个文件的异步包装"""
                try:
                    await progress_monitor.update_file_progress(os.path.basename(file_path), 0)
                    
                    validation = await self.validate_file(file_path)
                    if not validation['valid']:
                        await progress_monitor.complete_file(os.path.basename(file_path))
                        return file_path, {'success': False, 'error': validation['error']}
                    
                    if validation['file_info']['file_type'] == 'video':
                        result = await self.extract_frames_async(file_path, progress_monitor, **kwargs)
                    else:
                        result = await self.process_image_file_async(file_path, **kwargs)
                    
                    await progress_monitor.complete_file(os.path.basename(file_path))
                    return file_path, result
                    
                except Exception as e:
                    logger.error(f"处理文件异常 {file_path}: {str(e)}")
                    await progress_monitor.complete_file(os.path.basename(file_path))
                    return file_path, {'success': False, 'error': str(e)}
            
            # 并行处理所有文件
            batch_size = self.performance_profile['recommended_batch_size']
            
            for i in range(0, len(input_paths), batch_size):
                batch = input_paths[i:i + batch_size]
                
                # 创建当前批次的任务
                tasks = [process_single_file(file_path) for file_path in batch]
                
                # 等待当前批次完成
                results = await asyncio.gather(*tasks, return_exceptions=True)
                
                # 处理结果
                for file_path, result in results:
                    if isinstance(result, Exception):
                        logger.error(f"处理文件异常 {file_path}: {str(result)}")
                        failed_count += 1
                        continue
                    
                    if result['success']:
                        success_count += 1
                        if 'frame_paths' in result:
                            all_frame_paths.extend(result['frame_paths'])
                        elif 'output_info' in result:
                            # 转换图片结果为帧格式
                            frame_info = {
                                'path': result['output_info']['path'],
                                'filename': result['output_info']['filename'],
                                'frame_number': 0,
                                'timestamp': 0.0,
                                'extracted_index': len(all_frame_paths),
                                'quality_metrics': result['output_info']['quality_metrics'],
                                'source_type': 'image',
                                'source_file': os.path.basename(file_path)
                            }
                            all_frame_paths.append(frame_info)
                    else:
                        failed_count += 1
                
                # 批次间的短暂休息，允许系统回收资源
                if i + batch_size < len(input_paths):
                    await asyncio.sleep(0.1)
                    gc.collect()
            
            # 如果超过最大帧数限制，按质量排序保留
            max_base_frames = kwargs.get('max_base_frames', AsyncFrameExtractorConfig.DEFAULT_MAX_BASE_FRAMES)
            if len(all_frame_paths) > max_base_frames:
                all_frame_paths.sort(key=lambda x: x['quality_metrics']['quality_score'], reverse=True)
                
                # 删除多余文件
                for frame_info in all_frame_paths[max_base_frames:]:
                    try:
                        if os.path.exists(frame_info['path']):
                            os.remove(frame_info['path'])
                    except:
                        pass
                
                all_frame_paths = all_frame_paths[:max_base_frames]
            
            # 重新命名文件确保顺序
            await self._rename_frames_async(all_frame_paths)
            
            processing_time = time.time() - start_time
            
            logger.info(f"✅ 异步并行处理完成: 成功 {success_count}, 失败 {failed_count}, 耗时 {processing_time:.2f}秒")
            
            return {
                'success': success_count > 0,
                'task_id': task_id,
                'device_id': device_id,
                'task_output_dir': task_output_dir,
                'total_files': len(input_paths),
                'success_count': success_count,
                'failed_count': failed_count,
                'frame_paths': all_frame_paths,
                'batch_processing_time': processing_time,
                'performance_profile': self.performance_profile
            }
            
        finally:
            self.output_dir = original_output_dir
    
    async def _rename_frames_async(self, all_frame_paths: List[Dict]):
        """异步重新命名帧文件"""
        def _rename_files():
            for i, frame_info in enumerate(all_frame_paths):
                old_path = frame_info['path']
                clean_name = os.path.splitext(frame_info['source_file'])[0]
                new_filename = f"frame_{i:04d}_{frame_info['source_type']}_{clean_name}.jpg"
                new_path = os.path.join(self.output_dir, new_filename)
                
                try:
                    if old_path != new_path and os.path.exists(old_path):
                        if os.path.exists(new_path):
                            os.remove(new_path)
                        os.rename(old_path, new_path)
                        frame_info['path'] = new_path
                        frame_info['filename'] = new_filename
                        frame_info['extracted_index'] = i
                except Exception as e:
                    logger.warning(f"重命名文件失败 {old_path}: {e}")
        
        # 在线程池中执行文件重命名
        loop = asyncio.get_event_loop()
        await loop.run_in_executor(self.thread_pool, _rename_files)
    
    def format_output(self, processing_result: Dict[str, any], save_json: bool = True) -> Dict[str, any]:
        """格式化输出结果（同步方法）"""
        if not processing_result.get('success', False):
            return {
                'success': False,
                'error': processing_result.get('error', '处理失败'),
                'device_id': processing_result.get('device_id'),
                'task_id': processing_result.get('task_id'),
                'base_frame_paths': []
            }
        
        # 构建基础帧路径数组
        base_frame_paths = []
        for frame_info in processing_result.get('frame_paths', []):
            frame_data = {
                'file_path': frame_info['path'],
                'filename': frame_info['filename'],
                'source_type': frame_info.get('source_type', 'unknown'),
                'source_file': frame_info.get('source_file', 'unknown'),
                'extracted_index': frame_info.get('extracted_index', 0),
                'timestamp': frame_info.get('timestamp', 0.0),
                'quality_metrics': {
                    'sharpness': round(frame_info['quality_metrics']['sharpness'], 2),
                    'brightness': round(frame_info['quality_metrics']['brightness'], 2),
                    'contrast': round(frame_info['quality_metrics']['contrast'], 2),
                    'quality_score': round(frame_info['quality_metrics']['quality_score'], 2)
                }
            }
            base_frame_paths.append(frame_data)
        
        # 计算统计信息
        total_size_mb = sum(os.path.getsize(f['path']) for f in processing_result['frame_paths'] 
                           if os.path.exists(f['path'])) / AsyncFrameExtractorConfig.BYTES_TO_MB
        
        formatted_result = {
            'success': True,
            'device_id': processing_result.get('device_id', 'unknown'),
            'task_id': processing_result.get('task_id', 'unknown'),
            'base_frame_paths': base_frame_paths,
            'processing_summary': {
                'total_input_files': processing_result.get('total_files', 0),
                'success_files': processing_result.get('success_count', 0),
                'failed_files': processing_result.get('failed_count', 0),
                'final_frame_count': len(base_frame_paths),
                'processing_time_seconds': round(processing_result.get('batch_processing_time', 0), 2),
                'performance_profile': processing_result.get('performance_profile', {})
            },
            'storage_info': {
                'task_output_directory': processing_result.get('task_output_dir', ''),
                'total_size_mb': round(total_size_mb, 2),
                'frame_format': 'JPEG'
            },
            'metadata': {
                'extraction_timestamp': datetime.now().isoformat(),
                'extractor_version': '3.0.0-async',
                'async_processing': True,
                'parallel_batches': True
            }
        }
        
        # 保存JSON结果
        if save_json:
            json_path = self._save_json_result(formatted_result)
            if json_path:
                formatted_result['storage_info']['json_result_path'] = json_path
        
        return formatted_result
    
    def _save_json_result(self, formatted_result: Dict[str, any]) -> Optional[str]:
        """保存JSON结果（同步方法）"""
        try:
            task_output_dir = formatted_result['storage_info']['task_output_directory']
            task_id = formatted_result['task_id']
            
            json_filename = f"async_frames_result_{task_id}.json"
            json_path = os.path.join(task_output_dir, json_filename)
            
            with open(json_path, 'w', encoding='utf-8') as f:
                json.dump(formatted_result, f, ensure_ascii=False, indent=2, default=str)
            
            return json_path
        except Exception as e:
            logger.error(f"保存JSON失败: {str(e)}")
            return None
    
    async def process_and_format_async(self, input_paths: List[str], device_id: str = None, 
                                     task_id: str = None, save_json: bool = True, 
                                     progress_callback: Callable = None, **kwargs) -> Dict[str, any]:
        """一键异步处理并格式化输出"""
        try:
            # 处理多个文件
            processing_result = await self.process_multiple_files_async(
                input_paths, device_id, task_id, progress_callback, **kwargs
            )
            
            # 格式化输出
            formatted_output = self.format_output(processing_result, save_json)
            
            if formatted_output['success']:
                logger.info(f"✅ 一键异步处理完成: {len(formatted_output['base_frame_paths'])} 帧")
            
            return formatted_output
            
        except Exception as e:
            logger.error(f"一键异步处理异常: {str(e)}")
            return {
                'success': False,
                'error': f"处理异常: {str(e)}",
                'device_id': device_id,
                'task_id': task_id,
                'base_frame_paths': []
            }

# =============================================================================
# 示例和测试
# =============================================================================

async def example_progress_callback(progress_data: Dict[str, any]):
    """示例进度回调函数"""
    print(f"📊 处理进度: {progress_data['overall_progress']:.1f}% | "
          f"当前文件: {progress_data['current_file']} ({progress_data['current_file_progress']:.1f}%) | "
          f"已完成: {progress_data['completed_files']}/{progress_data['total_files']} | "
          f"预计剩余: {progress_data['estimated_remaining']:.1f}秒")

async def main():
    """异步示例用法"""
    print("=== 异步并行智能视频抽帧系统 ===\n")
    
    # 使用异步上下文管理器
    async with AsyncFrameExtractor(output_dir="async_frames") as extractor:
        
        # 查找测试文件
        test_files = []
        for filename in os.listdir('.'):
            file_ext = os.path.splitext(filename)[1].lower()
            if file_ext in extractor.supported_formats:
                test_files.append(filename)
        
        if not test_files:
            print("❌ 未找到测试文件")
            return
        
        print(f"📁 发现 {len(test_files)} 个文件")
        print(f"🔧 设备性能: {extractor.performance_profile['performance_level']}")
        print(f"⚙️ 并行配置: 最大工作线程 {extractor.performance_profile['max_workers']}, "
              f"批处理大小 {extractor.performance_profile['recommended_batch_size']}\n")
        
        # 测试异步一键处理
        device_id = "async_test_device_001"
        result = await extractor.process_and_format_async(
            input_paths=test_files,
            device_id=device_id,
            quality=90,
            max_resolution=(1920, 1080),
            scene_sensitivity='high',
            progress_callback=example_progress_callback
        )
        
        if result['success']:
            print(f"\n✅ 异步处理成功:")
            print(f"  任务ID: {result['task_id']}")
            print(f"  基础帧数: {len(result['base_frame_paths'])}")
            print(f"  处理时间: {result['processing_summary']['processing_time_seconds']}秒")
            print(f"  性能等级: {result['processing_summary']['performance_profile']['performance_level']}")
            print(f"  成功文件: {result['processing_summary']['success_files']}")
            print(f"  失败文件: {result['processing_summary']['failed_files']}")
        else:
            print(f"❌ 异步处理失败: {result.get('error', '未知错误')}")

if __name__ == '__main__':
    # 运行异步主函数
    asyncio.run(main())