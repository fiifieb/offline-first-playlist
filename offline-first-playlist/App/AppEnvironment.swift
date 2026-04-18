import Foundation

struct AppEnvironment {
    let playlistRepository: any PlaylistRepository

    static func live() -> AppEnvironment {
        AppEnvironment(playlistRepository: InMemoryPlaylistRepository())
    }
}
