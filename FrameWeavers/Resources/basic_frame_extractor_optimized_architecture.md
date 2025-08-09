# 优化版视频抽帧系统架构图

## 系统整体架构

```mermaid
graph TB
    subgraph "输入层 Input Layer"
        A[混合输入文件]
        A1[视频文件<br/>mp4, avi, mov, mkv等]
        A2[图片文件<br/>jpg, png, bmp等]
        A --> A1
        A --> A2
    end

    subgraph "配置层 Configuration Layer"
        B[FrameExtractorConfig]
        B1[文件格式配置]
        B2[时间间隔配置]
        B3[质量阈值配置]
        B4[场景检测配置]
        B --> B1
        B --> B2
        B --> B3
        B --> B4
    end

    subgraph "核心处理层 Core Processing Layer"
        C[OptimizedFrameExtractor]
        C1[文件验证模块]
        C2[抽帧计算模块]
        C3[质量评估模块]
        C4[场景检测模块]
        C5[图像处理模块]
        C --> C1
        C --> C2
        C --> C3
        C --> C4
        C --> C5
    end

    subgraph "算法层 Algorithm Layer"
        D1[智能抽帧算法]
        D2[质量评分算法]
        D3[场景变化检测]
        D4[相似度计算]
        D5[分辨率调整]
    end

    subgraph "输出层 Output Layer"
        E[格式化输出]
        E1[帧文件存储]
        E2[JSON结果文件]
        E3[任务目录管理]
        E --> E1
        E --> E2
        E --> E3
    end

    A1 --> C1
    A2 --> C1
    B --> C
    C1 --> C2
    C2 --> D1
    C3 --> D2
    C4 --> D3
    C4 --> D4
    C5 --> D5
    D1 --> E
    D2 --> E
    D3 --> E
    D4 --> E
    D5 --> E
```

## 核心类结构图

```mermaid
classDiagram
    class FrameExtractorConfig {
        +SUPPORTED_VIDEO_FORMATS: Set
        +SUPPORTED_IMAGE_FORMATS: Set
        +DEFAULT_OUTPUT_DIR: str
        +DEFAULT_QUALITY: int
        +SCENE_THRESHOLDS: Dict
        +INTENSITY_THRESHOLDS: Dict
        +时间间隔配置常量
        +质量评分权重
        +帧率分类阈值
    }

    class OptimizedFrameExtractor {
        -output_dir: str
        -max_file_size_mb: int
        -supported_formats: Set
        
        +__init__(output_dir, max_file_size_mb)
        +generate_task_id(device_id): str
        +create_task_output_dir(task_id): str
        +validate_file(file_path): Dict
        +calculate_optimal_frame_count(): Dict
        +calculate_frame_quality(): Dict
        +detect_scene_change(): Dict
        +resize_frame(): ndarray
        +extract_frames_optimized(): Dict
        +process_image_file(): Dict
        +process_mixed_inputs(): Dict
        +format_output(): Dict
        +process_and_format_base_frames(): Dict
        
        -_validate_video(): Dict
        -_validate_image(): Dict
        -_should_keep_frame(): bool
        -_save_json_result(): str
    }

    OptimizedFrameExtractor --> FrameExtractorConfig : uses
```

## 数据流程图

```mermaid
flowchart TD
    Start([开始处理]) --> Input[输入文件列表]
    Input --> TaskID[生成任务ID]
    TaskID --> CreateDir[创建任务目录]
    CreateDir --> FileLoop{遍历文件}
    
    FileLoop --> Validate[文件验证]
    Validate --> ValidCheck{验证通过?}
    ValidCheck -->|否| FailCount[失败计数+1]
    ValidCheck -->|是| TypeCheck{文件类型?}
    
    TypeCheck -->|视频| VideoProcess[视频抽帧处理]
    TypeCheck -->|图片| ImageProcess[图片处理]
    
    VideoProcess --> CalcFrames[计算最优帧数]
    CalcFrames --> ExtractLoop{抽帧循环}
    ExtractLoop --> ReadFrame[读取帧]
    ReadFrame --> FrameCheck{帧有效?}
    FrameCheck -->|否| ExtractEnd[抽帧结束]
    FrameCheck -->|是| IntervalCheck{间隔检查}
    IntervalCheck -->|否| NextFrame[下一帧]
    IntervalCheck -->|是| QualityCheck[质量评估]
    QualityCheck --> SceneCheck[场景检测]
    SceneCheck --> KeepFrame{保留帧?}
    KeepFrame -->|否| NextFrame
    KeepFrame -->|是| SaveFrame[保存帧]
    SaveFrame --> MaxCheck{达到最大数?}
    MaxCheck -->|是| ExtractEnd
    MaxCheck -->|否| NextFrame
    NextFrame --> ExtractLoop
    ExtractEnd --> SuccessCount[成功计数+1]
    
    ImageProcess --> ProcessImage[处理图片]
    ProcessImage --> SaveImage[保存图片]
    SaveImage --> SuccessCount
    
    SuccessCount --> MoreFiles{还有文件?}
    FailCount --> MoreFiles
    MoreFiles -->|是| FileLoop
    MoreFiles -->|否| QualitySort[按质量排序]
    
    QualitySort --> LimitCheck{超过限制?}
    LimitCheck -->|是| RemoveExtra[删除多余文件]
    LimitCheck -->|否| RenameFiles[重命名文件]
    RemoveExtra --> RenameFiles
    RenameFiles --> FormatOutput[格式化输出]
    FormatOutput --> SaveJSON[保存JSON结果]
    SaveJSON --> End([处理完成])
```

## 智能抽帧算法流程

```mermaid
flowchart TD
    VideoInput[视频输入] --> GetInfo[获取视频信息]
    GetInfo --> Duration[视频时长]
    GetInfo --> FPS[帧率]
    GetInfo --> TotalFrames[总帧数]
    
    Duration --> DurationCategory{时长分类}
    DurationCategory -->|≤3秒| UltraShort[超密集采样<br/>0.2秒间隔]
    DurationCategory -->|≤10秒| Short[密集采样<br/>0.5秒间隔]
    DurationCategory -->|≤30秒| MediumShort[中密集采样<br/>0.8秒间隔]
    DurationCategory -->|≤120秒| Medium[标准采样<br/>1.0秒间隔]
    DurationCategory -->|≤300秒| Long[长视频采样<br/>1.5秒间隔]
    DurationCategory -->|>300秒| VeryLong[超长采样<br/>2.0-4.0秒间隔]
    
    UltraShort --> CalcFrames[计算最优帧数]
    Short --> CalcFrames
    MediumShort --> CalcFrames
    Medium --> CalcFrames
    Long --> CalcFrames
    VeryLong --> CalcFrames
    
    FPS --> FPSCategory{帧率分类}
    FPSCategory -->|<15fps| LowFPS[低帧率修正×0.8]
    FPSCategory -->|15-30fps| StandardFPS[标准帧率×1.0]
    FPSCategory -->|30-60fps| HighFPS[高帧率修正×1.15]
    FPSCategory -->|>60fps| UltraFPS[超高帧率修正×1.3]
    
    LowFPS --> FPSCorrection[帧率修正]
    StandardFPS --> FPSCorrection
    HighFPS --> FPSCorrection
    UltraFPS --> FPSCorrection
    
    CalcFrames --> FPSCorrection
    FPSCorrection --> TotalLimit[总帧数限制]
    TotalFrames --> TotalLimit
    TotalLimit --> FinalFrames[最终抽帧数]
    FinalFrames --> FrameInterval[计算帧间隔]
```

## 质量评估系统

```mermaid
flowchart TD
    Frame[输入帧] --> GrayConvert[转换为灰度图]
    GrayConvert --> Sharpness[清晰度计算<br/>拉普拉斯方差]
    GrayConvert --> Brightness[亮度计算<br/>像素均值]
    GrayConvert --> Contrast[对比度计算<br/>像素标准差]
    
    Sharpness --> Weight1[权重×0.5]
    Brightness --> Normalize[亮度归一化]
    Normalize --> Weight2[权重×0.2]
    Contrast --> Weight3[权重×0.3]
    
    Weight1 --> QualityScore[综合质量分]
    Weight2 --> QualityScore
    Weight3 --> QualityScore
    
    QualityScore --> Threshold{质量阈值检查}
    Threshold -->|通过| KeepFrame[保留帧]
    Threshold -->|不通过| DiscardFrame[丢弃帧]
```

## 场景变化检测算法

```mermaid
flowchart TD
    Frame1[前一帧] --> Gray1[转换灰度图]
    Frame2[当前帧] --> Gray2[转换灰度图]
    
    Gray1 --> SizeCheck{尺寸一致?}
    Gray2 --> SizeCheck
    SizeCheck -->|否| Resize[调整尺寸]
    SizeCheck -->|是| PixelDiff[像素差异计算]
    Resize --> PixelDiff
    
    Gray1 --> Hist1[计算直方图]
    Gray2 --> Hist2[计算直方图]
    Hist1 --> HistDiff[直方图差异]
    Hist2 --> HistDiff
    
    PixelDiff --> Sensitivity[敏感度配置]
    HistDiff --> Sensitivity
    
    Sensitivity --> ThresholdCheck{阈值检查}
    ThresholdCheck --> PixelChange[像素变化判断]
    ThresholdCheck --> HistChange[直方图变化判断]
    
    PixelChange --> SceneChange{场景变化?}
    HistChange --> SceneChange
    SceneChange -->|是| IntensityCalc[变化强度计算]
    SceneChange -->|否| NoChange[无场景变化]
    
    IntensityCalc --> IntensityThreshold{强度阈值}
    IntensityThreshold -->|通过| AcceptFrame[接受帧]
    IntensityThreshold -->|不通过| RejectFrame[拒绝帧]
```

## 内存优化策略

```mermaid
flowchart TD
    Processing[处理开始] --> FrameCount[帧计数器]
    FrameCount --> Interval{每1000帧?}
    Interval -->|是| GC[垃圾回收]
    Interval -->|否| Continue[继续处理]
    
    GC --> MemoryClean[内存清理]
    MemoryClean --> Continue
    
    Continue --> FrameResize[帧缩放优化]
    FrameResize --> CompareSize[比较用缩略图<br/>160×90]
    CompareSize --> TempStorage[临时存储优化]
    TempStorage --> NextFrame[下一帧]
    NextFrame --> FrameCount
```

## 输出格式结构

```mermaid
graph TD
    Output[输出结果] --> Success[success: bool]
    Output --> DeviceID[device_id: str]
    Output --> TaskID[task_id: str]
    Output --> FramePaths[base_frame_paths: Array]
    Output --> Summary[processing_summary: Object]
    Output --> Storage[storage_info: Object]
    Output --> Metadata[metadata: Object]
    
    FramePaths --> FrameInfo[单帧信息]
    FrameInfo --> FilePath[file_path]
    FrameInfo --> Filename[filename]
    FrameInfo --> SourceType[source_type]
    FrameInfo --> Quality[quality_metrics]
    
    Summary --> TotalFiles[total_input_files]
    Summary --> SuccessFiles[success_files]
    Summary --> ProcessTime[processing_time_seconds]
    
    Storage --> OutputDir[task_output_directory]
    Storage --> TotalSize[total_size_mb]
    Storage --> JSONPath[json_result_path]
```

## 性能优化特性

### 1. 配置驱动设计
- 所有硬编码值提取为配置常量
- 支持不同场景的参数调优
- 灵活的阈值配置系统

### 2. 智能抽帧策略
- 基于视频时长的自适应间隔
- 帧率感知的修正因子
- 质量驱动的帧选择

### 3. 内存管理优化
- 定期垃圾回收机制
- 缩略图比较减少内存占用
- 流式处理避免大量数据缓存

### 4. 并发处理能力
- 支持混合输入批量处理
- 任务级别的目录隔离
- 独立的错误处理机制

### 5. 质量保证系统
- 多维度质量评估
- 场景变化智能检测
- 相似度过滤机制

这个架构图展现了优化版抽帧系统的完整设计思路，从输入处理到输出格式化的全流程，以及各个模块之间的协作关系。系统采用了模块化设计，具有良好的可扩展性和维护性。