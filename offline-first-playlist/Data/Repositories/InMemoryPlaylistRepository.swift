import Foundation

actor InMemoryPlaylistRepository: PlaylistRepository {
    private enum RepositoryError: Error {
        case playlistNotFound
    }

    private var storage: [UUID: Playlist] = [:]

    func fetchActivePlaylists() async throws -> [Playlist] {
        storage.values
            .filter { !$0.isDeleted }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func fetchDeletedPlaylists() async throws -> [Playlist] {
        storage.values
            .filter(\.isDeleted)
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func createPlaylist(named name: String) async throws -> Playlist {
        let now = Date()
        let playlist = Playlist(
            id: UUID(),
            name: name,
            isDeleted: false,
            createdAt: now,
            updatedAt: now,
            syncState: .pending
        )

        storage[playlist.id] = playlist
        return playlist
    }

    func renamePlaylist(id: UUID, name: String) async throws -> Playlist {
        var playlist = try getPlaylist(id: id)
        playlist.name = name
        playlist.updatedAt = Date()
        playlist.syncState = .pending
        storage[id] = playlist
        return playlist
    }

    func softDeletePlaylist(id: UUID) async throws {
        var playlist = try getPlaylist(id: id)
        playlist.isDeleted = true
        playlist.updatedAt = Date()
        playlist.syncState = .pending
        storage[id] = playlist
    }

    func restorePlaylist(id: UUID) async throws {
        var playlist = try getPlaylist(id: id)
        playlist.isDeleted = false
        playlist.updatedAt = Date()
        playlist.syncState = .pending
        storage[id] = playlist
    }

    private func getPlaylist(id: UUID) throws -> Playlist {
        guard let playlist = storage[id] else {
            throw RepositoryError.playlistNotFound
        }

        return playlist
    }
}
