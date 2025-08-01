import SwiftUI
import SwiftData

@main
struct FrameWeaversApp: App {
    @StateObject private var networkService = NetworkPermissionService()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
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
                .tint(Color(hex: "#2F2617"))
                .environmentObject(networkService)
                .task {
                    // 应用启动时主动检查网络权限
                    await networkService.checkNetworkPermission()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
