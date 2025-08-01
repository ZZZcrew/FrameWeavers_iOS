import Foundation
import Combine

// MARK: - ProgressMonitoringService
class ProgressMonitoringService {
    private let expectedDuration: TimeInterval
    private var timer: Timer?
    private let progressSubject = CurrentValueSubject<Double, Never>(0)
    
    init(expectedDuration: TimeInterval) {
        self.expectedDuration = expectedDuration
    }
    
    var progressPublisher: AnyPublisher<Double, Never> {
        progressSubject.eraseToAnyPublisher()
    }
    
    func startMonitoring() {
        timer?.invalidate()
        
        let startTime = Date()
        progressSubject.value = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let elapsed = Date().timeIntervalSince(startTime)
            let progress = min(elapsed / self.expectedDuration * 100, 95)
            
            self.progressSubject.value = progress / 100.0
            print("📤 上传进行中... 进度: \(Int(progress))%")
            
            // 超时警告
            if elapsed > self.expectedDuration * 1.2 {
                print("⚠️ 上传时间超过预期，可能遇到网络问题")
            }
        }
        timer?.fire()
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        
        if let totalTime = timer?.fireDate?.timeIntervalSince(Date()) {
            print("📊 处理总耗时: \(abs(totalTime))秒")
        }
        
        progressSubject.value = 0
    }
}

// MARK: - ProgressMonitoringService
class ProgressMonitor {
    private var startTime: Date?
    private var timer: Timer?
    private let expectedDuration: TimeInterval
    
    init(expectedDuration: TimeInterval) {
        self.expectedDuration = expectedDuration
    }
    
    func start() {
        startTime = Date()
        
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            guard let startTime = self.startTime else { return }
            
            let elapsed = Date().timeIntervalSince(startTime)
            let progress = min(elapsed / self.expectedDuration * 100, 95)
            
            print("📤 上传进行中... 已耗时: \(elapsed.formatted(.number.precision(.fractionLength(1))))秒 (预计进度: \(progress.formatted(.number.precision(.fractionLength(1))))%)")
            
            if elapsed > self.expectedDuration * 1.2 {
                print("⚠️ 上传时间超过预期，可能遇到网络问题")
            }
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        
        if let startTime = startTime {
            let totalTime = Date().timeIntervalSince(startTime)
            print("📊 上传总耗时: \(totalTime.formatted(.number.precision(.fractionLength(2))))秒")
        }
        
        startTime = nil
    }
}
