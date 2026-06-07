import Combine
import Foundation

@MainActor
final class PlaylistListViewModel: ObservableObject {
    @Published var activePlaylists: [Playlist] = []
    @Published var deletedPlaylists: [Playlist] = []
    @Published var newPlaylistName = ""
    @Published var isPresentingCreateSheet = false
    @Published var renamePlaylistName = ""
    @Published var isPresentingRenameSheet = false
    @Published var errorMessage: String?

    private let repository: any PlaylistRepository
    private var editingPlaylistID: UUID?

    init(repository: any PlaylistRepository) {
        self.repository = repository
    }

    var pendingSyncCount: Int {
        (activePlaylists + deletedPlaylists).filter { $0.syncState == .pending }.count
    }

    var failedSyncCount: Int {
        (activePlaylists + deletedPlaylists).filter { $0.syncState == .failed }.count
    }

    var syncStatusLabel: String {
        if failedSyncCount > 0 {
            return "Sync failed"
        }
        if pendingSyncCount > 0 {
            return "Syncing..."
        }
        return "Up to date"
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

    func beginRename(playlist: Playlist) {
        editingPlaylistID = playlist.id
        renamePlaylistName = playlist.name
        isPresentingRenameSheet = true
    }

    func renamePlaylist() async {
        guard let editingPlaylistID else { return }

        let trimmedName = renamePlaylistName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        do {
            _ = try await repository.renamePlaylist(id: editingPlaylistID, name: trimmedName)
            renamePlaylistName = ""
            isPresentingRenameSheet = false
            self.editingPlaylistID = nil
            await load()
        } catch {
            errorMessage = "Failed to rename playlist."
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
