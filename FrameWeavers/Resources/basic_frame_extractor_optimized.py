import cv2
import os
import numpy as np
from typing import List, Dict, Optional, Tuple, Union
import time
from datetime import datetime
import logging
import json
from collections import deque

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
# 常量定义 - 将所有硬编码值提取为常量
# =============================================================================

class FrameExtractorConfig:
    """抽帧器配置常量"""
    
    # 支持的文件格式
    SUPPORTED_VIDEO_FORMATS = {'.mp4', '.avi', '.mov', '.mkv', '.wmv', '.flv', '.webm', '.m4v'}
    SUPPORTED_IMAGE_FORMATS = {'.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.tif', '.webp'}
    
    # 默认配置
    DEFAULT_OUTPUT_DIR = "frames"
    DEFAULT_MAX_FILE_SIZE_MB = 500
    DEFAULT_QUALITY = 95
    DEFAULT_SHARPNESS_THRESHOLD = 100.0
    DEFAULT_SIMILARITY_THRESHOLD = 15.0
    DEFAULT_MAX_BASE_FRAMES = 80
    DEFAULT_SCENE_SENSITIVITY = 'high'
    
    # 时间间隔配置（秒）
    INTERVAL_ULTRA_SHORT = 0.2    # ≤3秒视频
    INTERVAL_SHORT = 0.5          # ≤10秒视频
    INTERVAL_MEDIUM_SHORT = 0.8   # ≤30秒视频
    INTERVAL_MEDIUM = 1.0         # ≤120秒视频
    INTERVAL_LONG = 1.5           # ≤300秒视频
    INTERVAL_VERY_LONG = 2.0      # ≤600秒视频
    INTERVAL_EXTRA_LONG = 2.5     # ≤1800秒视频
    INTERVAL_HOUR = 3.0           # ≤3600秒视频
    INTERVAL_SUPER_LONG = 4.0     # >3600秒视频
    
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
    MAX_FRAME_PERCENTAGE = 0.5  # 最多提取总帧数的50%
    MEMORY_CLEANUP_INTERVAL = 1000  # 每处理1000帧清理一次内存
    COMPARE_FRAME_SIZE = (160, 90)  # 用于比较的帧缩略图尺寸
    
    # 文件大小单位
    BYTES_TO_KB = 1024
    BYTES_TO_MB = 1024 * 1024


class OptimizedFrameExtractor:
    """优化后的基础视频抽帧器"""
    
    def __init__(self, output_dir: str = None, max_file_size_mb: int = None):
        """初始化抽帧器"""
        self.output_dir = output_dir or FrameExtractorConfig.DEFAULT_OUTPUT_DIR
        self.max_file_size_mb = max_file_size_mb or FrameExtractorConfig.DEFAULT_MAX_FILE_SIZE_MB
        self.max_file_size_bytes = self.max_file_size_mb * FrameExtractorConfig.BYTES_TO_MB
        
        os.makedirs(self.output_dir, exist_ok=True)
        
        # 所有支持的格式
        self.supported_formats = (FrameExtractorConfig.SUPPORTED_VIDEO_FORMATS | 
                                 FrameExtractorConfig.SUPPORTED_IMAGE_FORMATS)
        
        logger.info(f"✓ 优化抽帧器初始化完成 - 输出目录: {self.output_dir}")
    
    def generate_task_id(self, device_id: str) -> str:
        """生成任务ID"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")[:-3]
        return f"{timestamp}_{device_id}"
    
    def create_task_output_dir(self, task_id: str) -> str:
        """创建任务输出目录"""
        task_output_dir = os.path.join(self.output_dir, task_id)
        os.makedirs(task_output_dir, exist_ok=True)
        return task_output_dir
    
    def validate_file(self, file_path: str) -> Dict[str, any]:
        """统一的文件验证方法"""
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
                result['error'] = f"文件过大: {file_size/FrameExtractorConfig.BYTES_TO_MB:.1f}MB"
                return result
            
            # 判断文件类型并获取信息
            if file_ext in FrameExtractorConfig.SUPPORTED_VIDEO_FORMATS:
                return self._validate_video(file_path, file_size, file_ext)
            else:
                return self._validate_image(file_path, file_size, file_ext)
                
        except Exception as e:
            result['error'] = f"验证出错: {str(e)}"
            return result
    
    def _validate_video(self, file_path: str, file_size: int, file_ext: str) -> Dict[str, any]:
        """验证视频文件"""
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
                'file_size_mb': file_size / FrameExtractorConfig.BYTES_TO_MB,
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
    
    def _validate_image(self, file_path: str, file_size: int, file_ext: str) -> Dict[str, any]:
        """验证图片文件"""
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
            'file_size_mb': file_size / FrameExtractorConfig.BYTES_TO_MB,
            'file_extension': file_ext,
            'file_type': 'image',
            'width': width,
            'height': height,
            'channels': channels,
            'resolution': f"{width}x{height}"
        }
        
        return result
    
    def calculate_optimal_frame_count(self, duration: float, fps: float, total_frames: int) -> Dict[str, any]:
        """优化的抽帧数量计算"""
        # 根据时长确定间隔和策略
        if duration <= FrameExtractorConfig.DURATION_ULTRA_SHORT:
            interval = FrameExtractorConfig.INTERVAL_ULTRA_SHORT
            strategy = "极短视频超密集采样"
        elif duration <= FrameExtractorConfig.DURATION_SHORT:
            interval = FrameExtractorConfig.INTERVAL_SHORT
            strategy = "短视频密集采样"
        elif duration <= FrameExtractorConfig.DURATION_MEDIUM_SHORT:
            interval = FrameExtractorConfig.INTERVAL_MEDIUM_SHORT
            strategy = "中短视频密集采样"
        elif duration <= FrameExtractorConfig.DURATION_MEDIUM:
            interval = FrameExtractorConfig.INTERVAL_MEDIUM
            strategy = "中等视频标准采样"
        elif duration <= FrameExtractorConfig.DURATION_LONG:
            interval = FrameExtractorConfig.INTERVAL_LONG
            strategy = "长视频密集采样"
        elif duration <= FrameExtractorConfig.DURATION_VERY_LONG:
            interval = FrameExtractorConfig.INTERVAL_VERY_LONG
            strategy = "超长视频采样"
        elif duration <= FrameExtractorConfig.DURATION_EXTRA_LONG:
            interval = FrameExtractorConfig.INTERVAL_EXTRA_LONG
            strategy = "30分钟视频采样"
        elif duration <= FrameExtractorConfig.DURATION_HOUR:
            interval = FrameExtractorConfig.INTERVAL_HOUR
            strategy = "1小时视频采样"
        else:
            interval = FrameExtractorConfig.INTERVAL_SUPER_LONG
            strategy = "超长视频采样"
        
        optimal_frames = max(FrameExtractorConfig.MIN_FRAME_COUNT, int(duration / interval))
        
        # 帧率修正
        fps_factor = 1.0
        if fps < FrameExtractorConfig.FPS_LOW:
            fps_factor = FrameExtractorConfig.FPS_FACTOR_LOW
        elif fps > FrameExtractorConfig.FPS_HIGH:
            fps_factor = FrameExtractorConfig.FPS_FACTOR_HIGH
        elif fps > FrameExtractorConfig.FPS_STANDARD:
            fps_factor = FrameExtractorConfig.FPS_FACTOR_STANDARD_HIGH
        
        optimal_frames = int(optimal_frames * fps_factor)
        
        # 总帧数限制
        max_allowed = min(total_frames, int(total_frames * FrameExtractorConfig.MAX_FRAME_PERCENTAGE))
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
        """计算帧质量指标"""
        # 转换为灰度图
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY) if len(frame.shape) == 3 else frame
        
        # 清晰度（拉普拉斯方差）
        sharpness = cv2.Laplacian(gray, cv2.CV_64F).var()
        
        # 亮度和对比度
        brightness = np.mean(gray)
        contrast = np.std(gray)
        
        # 综合质量分
        quality_score = (
            sharpness * FrameExtractorConfig.QUALITY_WEIGHT_SHARPNESS +
            contrast * FrameExtractorConfig.QUALITY_WEIGHT_CONTRAST +
            min(brightness / 128.0, 1.0) * FrameExtractorConfig.QUALITY_WEIGHT_BRIGHTNESS
        )
        
        return {
            'sharpness': sharpness,
            'brightness': brightness,
            'contrast': contrast,
            'quality_score': quality_score
        }
    
    def detect_scene_change(self, frame1: np.ndarray, frame2: np.ndarray, 
                          sensitivity: str = 'high') -> Dict[str, any]:
        """简化的场景变化检测"""
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
        thresholds = FrameExtractorConfig.SCENE_THRESHOLDS.get(sensitivity, 
                                                             FrameExtractorConfig.SCENE_THRESHOLDS['high'])
        
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
        """调整帧分辨率"""
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
    
    def extract_frames_optimized(self, video_path: str, **kwargs) -> Dict[str, any]:
        """优化的视频抽帧方法"""
        logger.info(f"🎬 开始抽帧: {os.path.basename(video_path)}")
        start_time = time.time()
        
        # 获取参数
        quality = kwargs.get('quality', FrameExtractorConfig.DEFAULT_QUALITY)
        max_resolution = kwargs.get('max_resolution')
        sharpness_threshold = kwargs.get('sharpness_threshold', FrameExtractorConfig.DEFAULT_SHARPNESS_THRESHOLD)
        similarity_threshold = kwargs.get('similarity_threshold', FrameExtractorConfig.DEFAULT_SIMILARITY_THRESHOLD)
        scene_sensitivity = kwargs.get('scene_sensitivity', FrameExtractorConfig.DEFAULT_SCENE_SENSITIVITY)
        max_base_frames = kwargs.get('max_base_frames', FrameExtractorConfig.DEFAULT_MAX_BASE_FRAMES)
        
        # 验证文件
        validation = self.validate_file(video_path)
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
        
        # 开始抽帧
        cap = cv2.VideoCapture(video_path)
        if not cap.isOpened():
            return {'success': False, 'error': '无法打开视频'}
        
        try:
            frame_paths = []
            frame_count = 0
            extracted_count = 0
            previous_frame = None
            
            jpeg_params = [cv2.IMWRITE_JPEG_QUALITY, quality]
            frame_interval = calc_result['frame_interval']
            
            while True:
                ret, frame = cap.read()
                if not ret:
                    break
                
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
                            previous_frame = cv2.resize(processed_frame, FrameExtractorConfig.COMPARE_FRAME_SIZE)
                            extracted_count += 1
                            
                            # 达到最大帧数则退出
                            if extracted_count >= max_base_frames:
                                break
                
                frame_count += 1
                
                # 定期内存清理
                if frame_count % FrameExtractorConfig.MEMORY_CLEANUP_INTERVAL == 0:
                    import gc
                    gc.collect()
        
        finally:
            cap.release()
        
        processing_time = time.time() - start_time
        
        logger.info(f"✅ 抽帧完成: {len(frame_paths)} 帧, 耗时 {processing_time:.2f}秒")
        
        return {
            'success': True,
            'video_info': video_info,
            'frame_paths': frame_paths,
            'processing_time': processing_time,
            'calculation_result': calc_result
        }
    
    def _should_keep_frame(self, frame: np.ndarray, previous_frame: Optional[np.ndarray], 
                          quality_metrics: Dict[str, float], sharpness_threshold: float,
                          similarity_threshold: float, scene_sensitivity: str) -> bool:
        """判断是否保留帧"""
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
            intensity_threshold = FrameExtractorConfig.INTENSITY_THRESHOLDS.get(scene_sensitivity, 40.0)
            return scene_result['change_intensity'] >= intensity_threshold
        
        # 如果没有场景变化，检查像素差异
        return scene_result['pixel_difference'] >= similarity_threshold
    
    def process_image_file(self, image_path: str, **kwargs) -> Dict[str, any]:
        """处理图片文件"""
        quality = kwargs.get('quality', FrameExtractorConfig.DEFAULT_QUALITY)
        max_resolution = kwargs.get('max_resolution')
        
        # 验证图片
        validation = self.validate_file(image_path)
        if not validation['valid']:
            return {'success': False, 'error': validation['error']}
        
        file_info = validation['file_info']
        if file_info['file_type'] != 'image':
            return {'success': False, 'error': '不是图片文件'}
        
        # 读取和处理图片
        image = cv2.imread(image_path)
        processed_image = self.resize_frame(image, max_resolution)
        quality_metrics = self.calculate_frame_quality(processed_image)
        
        # 生成输出文件名
        base_name = os.path.splitext(file_info['file_name'])[0]
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
    
    def process_mixed_inputs(self, input_paths: List[str], device_id: str = None, 
                           task_id: str = None, **kwargs) -> Dict[str, any]:
        """处理混合输入（视频和图片）"""
        # 处理任务ID
        if task_id is None:
            device_id = device_id or "default_device"
            task_id = self.generate_task_id(device_id)
        
        # 创建任务目录
        task_output_dir = self.create_task_output_dir(task_id)
        original_output_dir = self.output_dir
        self.output_dir = task_output_dir
        
        logger.info(f"🚀 开始混合处理 {len(input_paths)} 个文件 - 任务ID: {task_id}")
        start_time = time.time()
        
        try:
            all_frame_paths = []
            success_count = 0
            failed_count = 0
            
            for file_path in input_paths:
                try:
                    validation = self.validate_file(file_path)
                    if not validation['valid']:
                        failed_count += 1
                        continue
                    
                    if validation['file_info']['file_type'] == 'video':
                        result = self.extract_frames_optimized(file_path, **kwargs)
                    else:
                        result = self.process_image_file(file_path, **kwargs)
                    
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
                        
                except Exception as e:
                    logger.error(f"处理文件失败 {file_path}: {str(e)}")
                    failed_count += 1
            
            # 如果超过最大帧数限制，按质量排序保留
            max_base_frames = kwargs.get('max_base_frames', FrameExtractorConfig.DEFAULT_MAX_BASE_FRAMES)
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
                except:
                    pass
            
            processing_time = time.time() - start_time
            
            return {
                'success': success_count > 0,
                'task_id': task_id,
                'device_id': device_id,
                'task_output_dir': task_output_dir,
                'total_files': len(input_paths),
                'success_count': success_count,
                'failed_count': failed_count,
                'frame_paths': all_frame_paths,
                'batch_processing_time': processing_time
            }
            
        finally:
            self.output_dir = original_output_dir
    
    def format_output(self, processing_result: Dict[str, any], save_json: bool = True) -> Dict[str, any]:
        """格式化输出结果"""
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
                           if os.path.exists(f['path'])) / FrameExtractorConfig.BYTES_TO_MB
        
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
                'processing_time_seconds': round(processing_result.get('batch_processing_time', 0), 2)
            },
            'storage_info': {
                'task_output_directory': processing_result.get('task_output_dir', ''),
                'total_size_mb': round(total_size_mb, 2),
                'frame_format': 'JPEG'
            },
            'metadata': {
                'extraction_timestamp': datetime.now().isoformat(),
                'extractor_version': '2.0.0-optimized'
            }
        }
        
        # 保存JSON结果
        if save_json:
            json_path = self._save_json_result(formatted_result)
            if json_path:
                formatted_result['storage_info']['json_result_path'] = json_path
        
        return formatted_result
    
    def _save_json_result(self, formatted_result: Dict[str, any]) -> Optional[str]:
        """保存JSON结果"""
        try:
            task_output_dir = formatted_result['storage_info']['task_output_directory']
            task_id = formatted_result['task_id']
            
            json_filename = f"base_frames_result_{task_id}.json"
            json_path = os.path.join(task_output_dir, json_filename)
            
            with open(json_path, 'w', encoding='utf-8') as f:
                json.dump(formatted_result, f, ensure_ascii=False, indent=2, default=str)
            
            return json_path
        except Exception as e:
            logger.error(f"保存JSON失败: {str(e)}")
            return None
    
    def process_and_format_base_frames(self, input_paths: List[str], device_id: str = None, 
                                     task_id: str = None, save_json: bool = True, **kwargs) -> Dict[str, any]:
        """一键处理并格式化输出"""
        try:
            # 处理混合输入
            processing_result = self.process_mixed_inputs(input_paths, device_id, task_id, **kwargs)
            
            # 格式化输出
            formatted_output = self.format_output(processing_result, save_json)
            
            if formatted_output['success']:
                logger.info(f"✅ 一键处理完成: {len(formatted_output['base_frame_paths'])} 帧")
            
            return formatted_output
            
        except Exception as e:
            logger.error(f"一键处理异常: {str(e)}")
            return {
                'success': False,
                'error': f"处理异常: {str(e)}",
                'device_id': device_id,
                'task_id': task_id,
                'base_frame_paths': []
            }


def main():
    """示例用法"""
    print("=== 优化版智能视频抽帧系统 ===\n")
    
    extractor = OptimizedFrameExtractor(output_dir="optimized_frames")
    
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
    
    # 测试一键处理
    device_id = "test_device_001"
    result = extractor.process_and_format_base_frames(
        input_paths=test_files,
        device_id=device_id,
        quality=90,
        max_resolution=(1920, 1080),
        scene_sensitivity='high'
    )
    
    if result['success']:
        print(f"✅ 处理成功:")
        print(f"  任务ID: {result['task_id']}")
        print(f"  基础帧数: {len(result['base_frame_paths'])}")
        print(f"  处理时间: {result['processing_summary']['processing_time_seconds']}秒")
    else:
        print(f"❌ 处理失败: {result.get('error', '未知错误')}")


if __name__ == '__main__':
    main()