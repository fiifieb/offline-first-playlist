import Foundation

protocol PlaylistRepository {
    func fetchActivePlaylists() async throws -> [Playlist]
    func fetchDeletedPlaylists() async throws -> [Playlist]
    func createPlaylist(named name: String) async throws -> Playlist
    func renamePlaylist(id: UUID, name: String) async throws -> Playlist
    func softDeletePlaylist(id: UUID) async throws
    func restorePlaylist(id: UUID) async throws
}
