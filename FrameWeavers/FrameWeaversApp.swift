import SwiftUI
import SwiftData

@main
struct FrameWeaversApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var networkService = NetworkPermissionService()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            HistoryAlbum.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            VideoUploadView()
                .tint(Color(hex: "#855C23"))
                .environmentObject(networkService)
                .task {
                    // 应用启动时主动检查网络权限
                    let hasPermission = await networkService.checkNetworkPermission()
                    print("🌐 App启动: 网络权限检查结果 - \(hasPermission ? "有权限" : "无权限")")
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
