import Foundation

struct AppEnvironment {
    let playlistRepository: any PlaylistRepository
    let syncEngine: any PlaylistSyncEngine

    static func live() -> AppEnvironment {
        do {
            let stack = try CoreDataStack(storeURL: persistentStoreURL())
            let repository = CoreDataPlaylistRepository(context: stack.viewContext)
            return AppEnvironment(
                playlistRepository: repository,
                syncEngine: MockPlaylistSyncEngine(repository: repository)
            )
        } catch {
            let repository = InMemoryPlaylistRepository()
            return AppEnvironment(
                playlistRepository: repository,
                syncEngine: MockPlaylistSyncEngine(repository: repository)
            )
        }
    }

    private static func persistentStoreURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return appSupport.appendingPathComponent("OfflineFirstPlaylist.sqlite")
    }
}
