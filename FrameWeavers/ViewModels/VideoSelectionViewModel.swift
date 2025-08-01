import Foundation
import SwiftUI
import PhotosUI
import AVFoundation
import CoreMedia
import Combine

// MARK: - 视频选择和验证ViewModel
/// 负责视频选择、验证、PhotosPicker处理等功能
/// 遵循MVVM架构，只处理视频选择相关的业务逻辑
@Observable
class VideoSelectionViewModel {
    // MARK: - Published Properties
    var selectedVideos: [URL] = []
    var isShowingPicker = false
    var validationStatus: ValidationStatus = .pending
    var validationMessage: String?
    var isValidating = false

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Validation Status
    enum ValidationStatus {
        case pending      // 待验证
        case validating   // 验证中
        case valid        // 验证通过
        case invalid      // 验证失败
    }

    // MARK: - 视频选择方法

    /// 选择单个视频
    /// - Parameter url: 视频URL
    func selectVideo(_ url: URL) {
        selectedVideos = [url]
        validateVideos()
    }

    /// 选择多个视频
    /// - Parameter urls: 视频URL数组
    func selectVideos(_ urls: [URL]) {
        selectedVideos = urls
        validateVideos()
    }

    /// 添加视频到选择列表
    /// - Parameter url: 要添加的视频URL
    func addVideo(_ url: URL) {
        selectedVideos.append(url)
        validateVideos()
    }

    /// 移除指定索引的视频
    /// - Parameter index: 要移除的视频索引
    func removeVideo(at index: Int) {
        guard index < selectedVideos.count else { return }
        selectedVideos.remove(at: index)
        validateVideos()
    }

    /// 清空所有选择的视频
    func clearAllVideos() {
        selectedVideos.removeAll()
        validationStatus = .pending
        validationMessage = nil
    }

    // MARK: - PhotosPicker处理

    /// 处理PhotosPicker选择的视频项目
    /// - Parameter items: PhotosPicker选择的项目数组
    /// - Returns: 处理完成的视频URL数组
    func processSelectedItems(_ items: [PickerItem]) async -> [URL] {
        var videoURLs: [URL] = []

        // 更新处理状态
        await MainActor.run {
            self.isValidating = true
            self.validationStatus = .validating
            self.validationMessage = "正在处理选中的视频..."
        }

        for (index, item) in items.enumerated() {
            do {
                // 更新进度提示
                await MainActor.run {
                    self.validationMessage = "正在处理第 \(index + 1)/\(items.count) 个视频..."
                }

                // 优化：使用URL方式而不是Data方式，避免全量内存加载
                if let url = try await item.loadTransferable(type: URL.self) {
                    // 直接使用系统提供的临时URL，无需重新保存
                    videoURLs.append(url)
                    print("✅ 视频处理成功: \(url.lastPathComponent)")
                } else if let data = try await item.loadTransferable(type: Data.self),
                          let savedUrl = saveVideoData(data) {
                    // 备用方案：如果URL方式失败，使用Data方式
                    videoURLs.append(savedUrl)
                    print("✅ 视频保存成功（备用方案）: \(savedUrl.lastPathComponent)")
                }
            } catch {
                print("❌ 处理视频项目失败: \(error)")
                await MainActor.run {
                    self.validationMessage = "处理第 \(index + 1) 个视频失败: \(error.localizedDescription)"
                }
            }
        }

        // 清除处理状态提示
        await MainActor.run {
            self.isValidating = false
            self.validationMessage = nil
        }

        return videoURLs
    }

    /// 保存视频数据到临时文件
    /// - Parameter data: 视频数据
    /// - Returns: 保存的文件URL，失败时返回nil
    private func saveVideoData(_ data: Data) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "temp_video_\(UUID().uuidString).mp4"
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            print("✅ 视频保存成功: \(fileURL.lastPathComponent)")
            return fileURL
        } catch {
            print("❌ 保存视频失败: \(error)")
            return nil
        }
    }

    // MARK: - 视频验证

    /// 验证所有选择的视频
    private func validateVideos() {
        guard !selectedVideos.isEmpty else {
            validationStatus = .pending
            validationMessage = nil
            return
        }

        // 异步验证所有视频，提高性能
        Task {
            await MainActor.run {
                self.isValidating = true
                self.validationStatus = .validating
                self.validationMessage = "正在验证视频..."
            }

            let validationResult = await performVideoValidation()

            await MainActor.run {
                self.isValidating = false
                if validationResult.hasError {
                    self.validationStatus = .invalid
                    self.validationMessage = validationResult.errorMessage
                } else {
                    self.validationStatus = .valid
                    self.validationMessage = nil
                    print("✅ 所有视频验证通过")
                }
            }
        }
    }

    /// 执行视频验证
    /// - Returns: 验证结果
    private func performVideoValidation() async -> ValidationResult {
        // 并发验证所有视频以提高性能
        let validationResult = await withTaskGroup(of: (Int, Result<(Double, Int64), Error>).self) { group in
            for (index, url) in selectedVideos.enumerated() {
                group.addTask {
                    let asset = AVAsset(url: url)
                    do {
                        // 获取时长
                        let duration = try await asset.load(.duration)
                        let durationSeconds = CMTimeGetSeconds(duration)

                        // 获取文件大小
                        let fileSize = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0

                        return (index, .success((durationSeconds, Int64(fileSize))))
                    } catch {
                        return (index, .failure(error))
                    }
                }
            }

            // 收集所有结果
            var hasError = false
            var errorMsg = ""
            let maxFileSize: Int64 = 800 * 1024 * 1024 // 800MB限制，与服务器保持一致

            for await (index, result) in group {
                switch result {
                case .success(let (durationSeconds, fileSize)):
                    if durationSeconds > 300 { // 5分钟
                        hasError = true
                        errorMsg = "视频\(index + 1)时长超过5分钟（\(Int(durationSeconds))秒）"
                        break
                    } else if fileSize > maxFileSize {
                        let fileSizeMB = Double(fileSize) / (1024 * 1024)
                        hasError = true
                        errorMsg = "视频\(index + 1)文件过大（\(String(format: "%.1f", fileSizeMB))MB），请选择小于800MB的视频"
                        break
                    }
                case .failure(_):
                    hasError = true
                    errorMsg = "无法获取视频\(index + 1)的信息"
                    break
                }
            }

            return ValidationResult(hasError: hasError, errorMessage: hasError ? errorMsg : nil)
        }

        return validationResult
    }

    // MARK: - 辅助结构

    /// 验证结果结构体
    private struct ValidationResult {
        let hasError: Bool
        let errorMessage: String?
    }

    // MARK: - 计算属性

    /// 是否有选择的视频
    var hasSelectedVideos: Bool {
        !selectedVideos.isEmpty
    }

    /// 第一个选择的视频（兼容性）
    var selectedVideo: URL? {
        selectedVideos.first
    }

    /// 是否验证通过
    var isValid: Bool {
        validationStatus == .valid
    }

    /// 选择的视频数量
    var videoCount: Int {
        selectedVideos.count
    }
}