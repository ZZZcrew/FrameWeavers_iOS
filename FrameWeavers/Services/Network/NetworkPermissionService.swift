import Foundation
import Network

// MARK: - 网络权限和状态检查服务
class NetworkPermissionService: ObservableObject {
    @Published var isNetworkAvailable = false
    @Published var networkType: NetworkType = .unknown
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    enum NetworkType {
        case wifi
        case cellular
        case wired
        case unknown
        case unavailable
        
        var description: String {
            switch self {
            case .wifi:
                return "WiFi"
            case .cellular:
                return "蜂窝网络"
            case .wired:
                return "有线网络"
            case .unknown:
                return "未知网络"
            case .unavailable:
                return "网络不可用"
            }
        }
    }
    
    init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - 开始网络监控
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateNetworkStatus(path: path)
            }
        }
        monitor.start(queue: queue)
        print("🌐 NetworkPermissionService: 开始网络监控")
    }
    
    // MARK: - 停止网络监控
    func stopMonitoring() {
        monitor.cancel()
        print("🌐 NetworkPermissionService: 停止网络监控")
    }
    
    // MARK: - 更新网络状态
    private func updateNetworkStatus(path: NWPath) {
        isNetworkAvailable = path.status == .satisfied
        
        if path.usesInterfaceType(.wifi) {
            networkType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            networkType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            networkType = .wired
        } else if path.status == .satisfied {
            networkType = .unknown
        } else {
            networkType = .unavailable
        }
        
        print("🌐 NetworkPermissionService: 网络状态更新 - 可用: \(isNetworkAvailable), 类型: \(networkType.description)")
    }
    
    // MARK: - 检查网络权限（主动发起网络请求）
    func checkNetworkPermission() async -> Bool {
        print("🌐 NetworkPermissionService: 开始检查网络权限")

        // 直接使用应用的API地址来触发权限弹窗，避免多余请求
        return await checkAPIConnectivity()
    }
    
    // MARK: - 检查API连接性
    func checkAPIConnectivity() async -> Bool {
        print("🌐 NetworkPermissionService: 开始检查API连接性")
        
        let testURL = NetworkConfig.baseURL
        guard let url = URL(string: testURL) else {
            print("❌ NetworkPermissionService: 无效的API URL")
            return false
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                let isConnected = httpResponse.statusCode < 500 // 允许4xx错误，但不允许5xx服务器错误
                print("✅ NetworkPermissionService: API连接性检查完成 - 可连接: \(isConnected), 状态码: \(httpResponse.statusCode)")
                return isConnected
            }
        } catch {
            print("❌ NetworkPermissionService: API连接性检查失败: \(error.localizedDescription)")
            return false
        }
        
        return false
    }
    
    // MARK: - 获取网络状态描述
    func getNetworkStatusDescription() -> String {
        if isNetworkAvailable {
            return "网络已连接 (\(networkType.description))"
        } else {
            return "网络不可用"
        }
    }
}
