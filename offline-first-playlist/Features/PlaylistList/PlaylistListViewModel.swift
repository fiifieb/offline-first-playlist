import Combine
import Foundation

@MainActor
final class PlaylistListViewModel: ObservableObject {
    @Published var activePlaylists: [Playlist] = []
    @Published var deletedPlaylists: [Playlist] = []
    @Published var newPlaylistName = ""
    @Published var isPresentingCreateSheet = false
    @Published var errorMessage: String?

    private let repository: any PlaylistRepository

    init(repository: any PlaylistRepository) {
        self.repository = repository
    }

    func load() async {
        do {
            async let active = repository.fetchActivePlaylists()
            async let deleted = repository.fetchDeletedPlaylists()
            activePlaylists = try await active
            deletedPlaylists = try await deleted
            errorMessage = nil
        } catch {
            errorMessage = "Failed to load playlists."
        }
    }

    func createPlaylist() async {
        let trimmedName = newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        do {
            _ = try await repository.createPlaylist(named: trimmedName)
            newPlaylistName = ""
            isPresentingCreateSheet = false
            await load()
        } catch {
            errorMessage = "Failed to create playlist."
        }
    }

    func softDeletePlaylist(id: UUID) async {
        do {
            try await repository.softDeletePlaylist(id: id)
            await load()
        } catch {
            errorMessage = "Failed to delete playlist."
        }
    }

    func restorePlaylist(id: UUID) async {
        do {
            try await repository.restorePlaylist(id: id)
            await load()
        } catch {
            errorMessage = "Failed to restore playlist."
        }
    }
}
