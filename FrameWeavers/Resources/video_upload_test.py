#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
视频上传测试脚本 - 专门解决上传阻塞问题
"""

import requests
import json
import time
import os
import uuid
import threading
from typing import Dict, Any, Optional

class VideoUploadTester:
    """视频上传测试器 - 防阻塞版本"""
    
    def __init__(self, base_url: str = "https://frame-api.zeabur.app"):
        self.base_url = base_url
        self.device_id = f"test_device_{uuid.uuid4().hex[:8]}"
        self.upload_cancelled = False
        
    def log(self, message: str, level: str = "INFO"):
        """打印日志"""
        timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
        print(f"[{timestamp}] [{level}] {message}")
    
    def check_file_info(self, video_path: str) -> Dict[str, Any]:
        """检查视频文件信息"""
        if not os.path.exists(video_path):
            return {"exists": False, "error": f"文件不存在: {video_path}"}
        
        try:
            file_size = os.path.getsize(video_path)
            file_size_mb = file_size / (1024 * 1024)
            
            return {
                "exists": True,
                "path": video_path,
                "size_bytes": file_size,
                "size_mb": file_size_mb,
                "name": os.path.basename(video_path)
            }
        except Exception as e:
            return {"exists": False, "error": f"获取文件信息失败: {str(e)}"}
    
    def upload_with_timeout_control(self, video_path: str, timeout: int = 120) -> Dict[str, Any]:
        """
        带超时控制的视频上传
        
        Args:
            video_path: 视频文件路径
            timeout: 超时时间（秒）
            
        Returns:
            上传结果
        """
        self.log("=== 防阻塞视频上传测试 ===")
        
        # 检查文件
        file_info = self.check_file_info(video_path)
        if not file_info.get("exists"):
            return {"success": False, "error": file_info.get("error")}
        
        self.log(f"文件: {file_info['name']}")
        self.log(f"大小: {file_info['size_mb']:.2f} MB")
        
        # 根据文件大小调整超时时间
        if file_info['size_mb'] > 50:
            timeout = max(timeout, int(file_info['size_mb'] * 3))
            self.log(f"大文件检测，调整超时时间为: {timeout} 秒")
        
        # 准备上传数据
        upload_data = {
            'device_id': self.device_id
        }
        
        result = {"success": False}
        
        def upload_worker():
            """上传工作线程"""
            nonlocal result
            try:
                with open(video_path, 'rb') as video_file:
                    files = {
                        'videos': (file_info['name'], video_file, 'video/mp4')
                    }
                    
                    self.log("开始上传...")
                    start_time = time.time()
                    
                    # 设置较短的连接超时，较长的读取超时
                    response = requests.post(
                        f'{self.base_url}/api/upload/videos',
                        files=files,
                        data=upload_data,
                        timeout=(timeout+10),  # (连接超时, 读取超时)
                        stream=False  # 不使用流式传输
                    )
                    
                    upload_time = time.time() - start_time
                    
                    if response.status_code == 200:
                        response_data = response.json()
                        if response_data.get('success'):
                            result = {
                                "success": True,
                                "task_id": response_data.get('task_id'),
                                "video_path": response_data.get('video_path'),
                                "upload_time": upload_time,
                                "uploaded_files": response_data.get('uploaded_files', 0),
                                "files_info": response_data.get('files', [])
                            }
                            self.log(f"上传成功！耗时: {upload_time:.2f} 秒")
                        else:
                            result = {
                                "success": False,
                                "error": response_data.get('message', '上传失败')
                            }
                    else:
                        result = {
                            "success": False,
                            "error": f"HTTP {response.status_code}: {response.text[:200]}"
                        }
                        
            except requests.exceptions.Timeout:
                result = {
                    "success": False,
                    "error": f"上传超时（超过 {timeout} 秒）"
                }
            except requests.exceptions.ConnectionError as e:
                result = {
                    "success": False,
                    "error": f"连接错误: {str(e)}"
                }
            except Exception as e:
                result = {
                    "success": False,
                    "error": f"上传异常: {str(e)}"
                }
        
        # 创建上传线程
        upload_thread = threading.Thread(target=upload_worker)
        upload_thread.daemon = True
        upload_thread.start()
        
        # 监控上传进度
        start_time = time.time()
        last_log_time = start_time
        
        while upload_thread.is_alive():
            current_time = time.time()
            elapsed = current_time - start_time
            
            # 每10秒打印一次进度
            if current_time - last_log_time >= 10:
                self.log(f"上传进行中... 已耗时: {elapsed:.1f} 秒")
                last_log_time = current_time
            
            # 检查是否超时
            if elapsed > timeout + 10:  # 额外10秒缓冲
                self.log("上传超时，强制终止", "ERROR")
                self.upload_cancelled = True
                break
            
            time.sleep(1)
        
        # 等待线程结束
        upload_thread.join(timeout=5)
        
        if self.upload_cancelled:
            return {"success": False, "error": "上传被强制终止"}
        
        return result
    
    def test_server_connection(self) -> bool:
        """测试服务器连接"""
        self.log("测试服务器连接...")
        
        try:
            # 尝试访问根路径或上传端点来测试连接
            response = requests.get(f"{self.base_url}/", timeout=60)
            if response.status_code in [200, 404, 405]:  # 这些都表示服务器在运行
                self.log("✓ 服务器连接正常")
                return True
            else:
                self.log(f"✗ 服务器响应异常: {response.status_code}", "WARNING")
                return False
        except Exception as e:
            self.log(f"✗ 服务器连接失败: {str(e)}", "ERROR")
            return False
    
    def verify_upload_result(self, task_id: str) -> Dict[str, Any]:
        """验证上传结果"""
        if not task_id:
            return {"success": False, "error": "无效的任务ID"}
        
        self.log(f"验证上传结果，任务ID: {task_id}")
        
        try:
            response = requests.get(f"{self.base_url}/api/task/status/{task_id}", timeout=60)
            
            if response.status_code == 200:
                status_data = response.json()
                if status_data.get('success'):
                    status = status_data.get('status')
                    message = status_data.get('message')
                    files = status_data.get('files', [])
                    
                    self.log(f"任务状态: {status}")
                    self.log(f"状态消息: {message}")
                    self.log(f"文件数量: {len(files)}")
                    
                    return {
                        "success": True,
                        "status": status,
                        "message": message,
                        "files_count": len(files)
                    }
                else:
                    return {
                        "success": False,
                        "error": status_data.get('message', '状态查询失败')
                    }
            else:
                return {
                    "success": False,
                    "error": f"HTTP {response.status_code}"
                }
                
        except Exception as e:
            return {
                "success": False,
                "error": f"验证失败: {str(e)}"
            }
    
    def run_upload_test(self, video_path: str = "测试视频3.mp4") -> bool:
        """运行完整的上传测试"""
        self.log("🚀 开始视频上传测试")
        self.log(f"设备ID: {self.device_id}")
        self.log(f"服务器: {self.base_url}")
        
        # 1. 测试服务器连接（可选，失败也继续）
        connection_ok = self.test_server_connection()
        if not connection_ok:
            self.log("服务器连接测试失败，但继续尝试上传", "WARNING")
        
        # 2. 执行上传
        upload_result = self.upload_with_timeout_control(video_path)
        
        if not upload_result.get("success"):
            self.log(f"❌ 上传失败: {upload_result.get('error')}", "ERROR")
            return False
        
        # 3. 验证上传结果
        task_id = upload_result.get("task_id")
        verify_result = self.verify_upload_result(task_id)
        
        if verify_result.get("success"):
            self.log("✅ 上传测试完成！")
            self.log(f"任务ID: {task_id}")
            self.log(f"上传时间: {upload_result.get('upload_time', 0):.2f} 秒")
            self.log(f"文件数量: {upload_result.get('uploaded_files', 0)}")
            return True
        else:
            self.log(f"⚠️ 上传成功但验证失败: {verify_result.get('error')}", "WARNING")
            return True  # 上传成功就算通过
    
    def run_stress_test(self, video_path: str = "测试视频3.mp4", test_count: int = 3):
        """运行压力测试"""
        self.log(f"🔥 开始压力测试 ({test_count} 次上传)")
        
        success_count = 0
        total_time = 0
        
        for i in range(test_count):
            self.log(f"\n--- 第 {i+1}/{test_count} 次测试 ---")
            
            # 重新生成设备ID
            self.device_id = f"stress_test_{uuid.uuid4().hex[:8]}"
            
            start_time = time.time()
            if self.run_upload_test(video_path):
                success_count += 1
                test_time = time.time() - start_time
                total_time += test_time
                self.log(f"✅ 第 {i+1} 次测试成功，耗时: {test_time:.2f} 秒")
            else:
                self.log(f"❌ 第 {i+1} 次测试失败", "ERROR")
            
            # 测试间隔
            if i < test_count - 1:
                self.log("等待 5 秒后进行下一次测试...")
                time.sleep(5)
        
        # 统计结果
        self.log(f"\n📊 压力测试结果:")
        self.log(f"成功率: {success_count}/{test_count} ({success_count/test_count*100:.1f}%)")
        if success_count > 0:
            avg_time = total_time / success_count
            self.log(f"平均上传时间: {avg_time:.2f} 秒")


def main():
    """主函数"""
    print("🎬 视频上传防阻塞测试工具")
    print("=" * 50)
    
    # 默认配置
    base_url = "https://frame-api.zeabur.app"
    video_path = "测试视频3.mp4"
    
    # 创建测试器
    tester = VideoUploadTester(base_url)
    
    print(f"使用默认配置:")
    print(f"服务器地址: {base_url}")
    print(f"测试视频: {video_path}")
    print()
    
    # 直接运行单次上传测试
    print("执行单次上传测试...")
    tester.run_upload_test(video_path)
    
    print("\n测试完成！")

def interactive_main():
    """交互式主函数"""
    print("🎬 视频上传防阻塞测试工具")
    print("=" * 50)
    
    # 配置
    base_url = input("请输入服务器地址 (默认: https://frame-api.zeabur.app): ").strip()
    if not base_url:
        base_url = "https://frame-api.zeabur.app"
    
    video_path = input("请输入视频文件路径 (默认: 测试视频3.mp4): ").strip()
    if not video_path:
        video_path = "测试视频3.mp4"
    
    # 创建测试器
    tester = VideoUploadTester(base_url)
    
    print("\n选择测试模式:")
    print("1. 单次上传测试")
    print("2. 压力测试 (3次)")
    print("3. 仅测试服务器连接")
    
    choice = input("请选择 (1/2/3): ").strip()
    
    if choice == "1":
        tester.run_upload_test(video_path)
    elif choice == "2":
        tester.run_stress_test(video_path, 3)
    elif choice == "3":
        tester.test_server_connection()
    else:
        print("无效选择")
    
    print("\n测试完成！")


if __name__ == "__main__":
    main()