import Foundation

struct AppEnvironment {
    let playlistRepository: any PlaylistRepository

    static func live() -> AppEnvironment {
        do {
            let stack = try CoreDataStack(storeURL: persistentStoreURL())
            return AppEnvironment(playlistRepository: CoreDataPlaylistRepository(context: stack.viewContext))
        } catch {
            return AppEnvironment(playlistRepository: InMemoryPlaylistRepository())
        }
    }

    private static func persistentStoreURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return appSupport.appendingPathComponent("OfflineFirstPlaylist.sqlite")
    }
}
