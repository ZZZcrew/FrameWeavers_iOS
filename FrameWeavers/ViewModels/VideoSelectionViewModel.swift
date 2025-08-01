import Foundation
import SwiftUI
import PhotosUI
import AVFoundation
import CoreMedia

class VideoSelectionViewModel: ObservableObject {
    @Published var selectedVideos: [URL] = []
    @Published var uploadStatus: UploadStatus = .pending
    @Published var errorMessage: String?
    @Published var isShowingPicker = false
    
    // 兼容性属性，返回第一个选中的视频
    var selectedVideo: URL? {
        return selectedVideos.first
    }
    
    func selectVideo(_ url: URL) {
        selectedVideos = [url]
        validateVideos()
    }
    
    func selectVideos(_ urls: [URL]) {
        selectedVideos = urls
        validateVideos()
    }
    
    func addVideo(_ url: URL) {
        selectedVideos.append(url)
        validateVideos()
    }
    
    func removeVideo(at index: Int) {
        guard index < selectedVideos.count else { return }
        selectedVideos.remove(at: index)
        validateVideos()
    }
    
    func resetSelection() {
        selectedVideos = []
        uploadStatus = .pending
        errorMessage = nil
    }
    
    /// 保存视频数据到临时文件
    /// - Parameter data: 视频数据
    /// - Returns: 保存的文件URL，失败时返回nil
    func saveVideoData(_ data: Data) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "temp_video_\(UUID().uuidString).mp4"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            print("✅ 视频保存成功: \(fileURL.lastPathComponent)")
            return fileURL
        } catch {
            print("❌ 保存视频失败: \(error)")
            errorMessage = "保存视频失败: \(error.localizedDescription)"
            return nil
        }
    }
    
    /// 处理PhotosPicker选择的视频项目
    /// - Parameter items: PhotosPicker选择的项目数组
    /// - Returns: 处理完成的视频URL数组
    func processSelectedItems(_ items: [PhotosPickerItem]) async -> [URL] {
        var videoURLs: [URL] = []
        
        await MainActor.run {
            uploadStatus = .processing
            errorMessage = "正在处理选中的视频..."
        }
        
        for (index, item) in items.enumerated() {
            do {
                await MainActor.run {
                    errorMessage = "正在处理第 \(index + 1)/\(items.count) 个视频..."
                }
                
                if let url = try await item.loadTransferable(type: URL.self) {
                    videoURLs.append(url)
                    print("✅ 视频处理成功: \(url.lastPathComponent)")
                } else if let data = try await item.loadTransferable(type: Data.self),
                          let savedUrl = saveVideoData(data) {
                    videoURLs.append(savedUrl)
                    print("✅ 视频保存成功（备用方案）: \(savedUrl.lastPathComponent)")
                }
            } catch {
                print("❌ 处理视频项目失败: \(error)")
                await MainActor.run {
                    errorMessage = "处理第 \(index + 1) 个视频失败: \(error.localizedDescription)"
                }
            }
        }
        
        await MainActor.run {
            errorMessage = nil
            uploadStatus = .pending
        }
        
        return videoURLs
    }
    
    private func validateVideos() {
        guard !selectedVideos.isEmpty else {
            errorMessage = nil
            uploadStatus = .pending
            return
        }
        
        Task {
            await MainActor.run {
                errorMessage = "正在验证视频..."
                uploadStatus = .processing
            }
            
            let validationResult = await performVideoValidation()
            
            await MainActor.run {
                if validationResult.hasError {
                    errorMessage = validationResult.errorMessage
                    uploadStatus = .failed
                } else {
                    errorMessage = nil
                    uploadStatus = .pending
                    print("✅ 所有视频验证通过")
                }
            }
        }
    }
    
    private func performVideoValidation() async -> VideoValidationResult {
        let results = await withTaskGroup(of: (Int, VideoValidationResult).self) { group in
            for (index, url) in selectedVideos.enumerated() {
                group.addTask {
                    let asset = AVAsset(url: url)
                    do {
                        let duration = try await asset.load(.duration)
                        let durationSeconds = CMTimeGetSeconds(duration)
                        let fileSize = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                        
                        if durationSeconds > 300 {
                            return (index, VideoValidationResult(hasError: true, errorMessage: "视频\(index + 1)时长超过5分钟（\(Int(durationSeconds))秒）"))
                        } else if Int64(fileSize) > 800 * 1024 * 1024 {
                            let fileSizeMB = Double(fileSize) / (1024 * 1024)
                            return (index, VideoValidationResult(hasError: true, errorMessage: "视频\(index + 1)文件过大（\(String(format: "%.1f", fileSizeMB))MB），请选择小于800MB的视频"))
                        }
                        
                        return (index, VideoValidationResult(hasError: false, errorMessage: nil))
                    } catch {
                        return (index, VideoValidationResult(hasError: true, errorMessage: "无法获取视频\(index + 1)的信息"))
                    }
                }
            }
            
            var overallResult = VideoValidationResult(hasError: false, errorMessage: nil)
            for await (_, result) in group {
                if result.hasError {
                    overallResult = result
                    break
                }
            }
            return overallResult
        }
        
        return results
    }
}

struct VideoValidationResult {
    let hasError: Bool
    let errorMessage: String?
}