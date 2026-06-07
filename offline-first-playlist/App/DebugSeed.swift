import Foundation

enum DebugSeed {
    static func seedIfEmpty(repository: any PlaylistRepository) async {
        do {
            let active = try await repository.fetchActivePlaylists()
            if !active.isEmpty { return }

            let _ = try await repository.createPlaylist(named: "Morning Mix")
            let _ = try await repository.createPlaylist(named: "Workout")
            let _ = try await repository.createPlaylist(named: "Chill Vibes")
            let old = try await repository.createPlaylist(named: "Oldies")
            try await repository.softDeletePlaylist(id: old.id)
        } catch {
            // swallow errors in debug seeding
        }
    }
}
