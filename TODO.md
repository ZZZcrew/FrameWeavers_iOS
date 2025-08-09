# 视频帧提取功能迁移计划（更新版）

## 项目背景
当前项目在后端处理视频并提取基础帧，现在需要将此功能迁移至iOS前端处理，仅上传提取的帧图片到后端。

## 技术可行性
iOS 17+设备具备强大的视频处理能力，AVFoundation框架提供了完整的视频处理功能，包括帧提取、格式转换等，完全满足项目需求。

## 后端算法文件分析

### async_frame_extractor.py（推荐使用）
这是后端提供的异步并行视频抽帧器，具有以下优势：
1. **异步并行处理**：支持多文件同时处理，性能比同步版本提升3-5倍
2. **设备性能检测**：自动检测设备CPU、内存等配置，动态调整处理参数
3. **实时进度监控**：支持进度回调函数，可以实时获取处理进度
4. **智能资源管理**：内存监控、垃圾回收、信号量控制等机制保证稳定运行
5. **丰富的功能**：支持视频和图片混合处理、质量评估、场景变化检测等

## 修改计划

### 1. 创建本地视频帧提取服务
我们将创建一个新的服务类 `LocalVideoFrameExtractor` 来处理视频帧提取。

需要创建文件：
- `FrameWeavers/Services/Video/LocalVideoFrameExtractor.swift`

主要功能：
- 使用 AVAssetImageGenerator 提取视频帧（参考后端算法实现）
- 实现质量评估算法（清晰度、亮度、对比度计算）
- 实现场景变化检测算法
- 支持按时间间隔提取帧
- 图像格式转换（转换为JPEG或PNG格式以便上传）
- 错误处理和异常情况处理

### 2. 实现后端算法的核心逻辑

#### 2.1 时间间隔计算算法
根据后端代码，我们需要实现类似的时间间隔计算逻辑：

```swift
// 根据视频时长确定抽帧间隔
func calculateFrameInterval(duration: Double, fps: Double, totalFrames: Int) -> Double {
    let interval: Double
    let strategy: String
    
    switch duration {
    case ...3:
        interval = 0.2  // 极短视频超密集采样
        strategy = "极短视频超密集采样"
    case ...10:
        interval = 0.5  // 短视频密集采样
        strategy = "短视频密集采样"
    case ...30:
        interval = 0.8  // 中短视频密集采样
        strategy = "中短视频密集采样"
    case ...120:
        interval = 1.0  // 中等视频标准采样
        strategy = "中等视频标准采样"
    case ...300:
        interval = 1.5  // 长视频密集采样
        strategy = "长视频密集采样"
    case ...600:
        interval = 2.0  // 超长视频采样
        strategy = "超长视频采样"
    case ...1800:
        interval = 2.5  // 30分钟视频采样
        strategy = "30分钟视频采样"
    case ...3600:
        interval = 3.0  // 1小时视频采样
        strategy = "1小时视频采样"
    default:
        interval = 4.0  // 超长视频采样
        strategy = "超长视频采样"
    }
    
    // 帧率修正
    let fpsFactor: Double
    if fps < 15 {
        fpsFactor = 0.8
    } else if fps > 60 {
        fpsFactor = 1.3
    } else if fps > 30 {
        fpsFactor = 1.15
    } else {
        fpsFactor = 1.0
    }
    
    return interval * fpsFactor
}
```

#### 2.2 质量评估算法
实现类似后端的质量评估算法：

```swift
// 计算帧质量指标
func calculateFrameQuality(_ image: UIImage) -> [String: Double] {
    // 转换为CIImage进行处理
    guard let ciImage = image.ciImage ?? CIImage(image: image) else {
        return [:]
    }
    
    // 清晰度计算（拉普拉斯方差）
    let sharpness = calculateSharpness(ciImage)
    
    // 亮度和对比度计算
    let (brightness, contrast) = calculateBrightnessAndContrast(ciImage)
    
    // 综合质量分
    let qualityScore = sharpness * 0.5 + contrast * 0.3 + min(brightness / 128.0, 1.0) * 0.2
    
    return [
        "sharpness": sharpness,
        "brightness": brightness,
        "contrast": contrast,
        "quality_score": qualityScore
    ]
}
```

#### 2.3 场景变化检测算法
实现场景变化检测算法：

```swift
// 检测场景变化
func detectSceneChange(_ frame1: UIImage, _ frame2: UIImage, sensitivity: String = "high") -> [String: Any] {
    // 转换为灰度图并比较差异
    guard let gray1 = convertToGrayscale(frame1),
          let gray2 = convertToGrayscale(frame2) else {
        return ["is_scene_change": false, "change_intensity": 0.0]
    }
    
    // 计算像素差异
    let pixelDiff = calculatePixelDifference(gray1, gray2)
    
    // 获取阈值配置
    let thresholds = getSceneThresholds(for: sensitivity)
    
    // 判断场景变化
    let pixelChange = pixelDiff > thresholds["pixel_threshold"]!
    
    // 计算变化强度
    let changeIntensity = pixelDiff / thresholds["pixel_threshold"]!
    
    return [
        "is_scene_change": pixelChange,
        "change_intensity": changeIntensity,
        "pixel_difference": pixelDiff
    ]
}
```

### 3. 修改连环画生成协调器
需要修改 `ComicGenerationCoordinator.swift` 文件，使其使用本地帧提取服务而不是调用后端API。

修改点：
- 注入 `LocalVideoFrameExtractor` 实例
- 修改 `extractBaseFrames(taskId: String)` 方法实现，使用本地服务
- 移除对 `BaseFrameService` 的依赖

### 4. 调整视图模型
需要修改 `VideoUploadViewModel.swift` 以支持新的帧提取流程。

修改点：
- 更新 `extractBaseFrames()` 方法的实现
- 可能需要调整进度报告逻辑
- 更新错误处理流程

### 5. 网络请求调整
由于不再需要调用基础帧提取的API，可以移除相关网络请求代码。

涉及文件：
- `VideoUploadModel.swift` 中的 `BaseFrameService` 类及相关响应模型
- `ComicGenerationCoordinator.swift` 中对 `BaseFrameService` 的调用

### 6. 依赖注入调整
更新 `ComicGenerationCoordinator` 的初始化方法，注入新的本地帧提取服务。

### 7. 错误处理和边界情况
需要考虑以下情况：
- 视频文件损坏或无法读取
- 设备存储空间不足
- 内存使用过高
- 不同视频格式的兼容性
- 大视频文件的处理性能

### 8. 性能优化
- 实现异步处理避免阻塞主线程
- 考虑使用OperationQueue或DispatchQueue管理并发
- 对大视频文件进行分段处理
- 实现内存监控和垃圾回收机制

### 9. 测试计划
- 单元测试本地帧提取服务
- 测试不同格式视频的兼容性
- 测试异常情况下的错误处理
- 性能基准测试

## 具体实现步骤

### 第一阶段：基础框架搭建
1. 创建 `LocalVideoFrameExtractor` 类
2. 实现基本的帧提取功能
3. 添加错误处理机制

### 第二阶段：算法实现
1. 实现时间间隔计算算法
2. 实现质量评估算法
3. 实现场景变化检测算法
4. 实现图像处理功能（缩放、格式转换等）

### 第三阶段：集成与替换
1. 修改 `ComicGenerationCoordinator` 使用新服务
2. 调整相关视图模型
3. 移除旧的网络请求相关代码

### 第四阶段：优化与测试
1. 实现性能优化
2. 添加完整错误处理
3. 编写测试用例
4. 进行全面测试

## 风险评估
1. 设备性能差异可能导致处理时间不一致
2. 内存使用可能增加，需要优化
3. 不同视频格式可能存在兼容性问题
4. 需要处理用户中断操作的情况

## 预期收益
1. 减少网络传输数据量
2. 提高用户隐私保护
3. 降低后端服务器压力
4. 提升用户体验（更快的处理反馈）

## 后续优化方向
1. 实现智能帧提取算法（不仅仅按时间间隔）
2. 添加帧质量评估机制
3. 支持用户手动选择关键帧