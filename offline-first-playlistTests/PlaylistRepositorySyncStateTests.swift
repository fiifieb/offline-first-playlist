import XCTest
@testable import offline_first_playlist

final class PlaylistRepositorySyncStateTests: XCTestCase {
    func testSetSyncStateUpdatesStoredPlaylist() async throws {
        let repository = InMemoryPlaylistRepository()
        let created = try await repository.createPlaylist(named: "Sync Me")

        try await repository.setSyncState(id: created.id, syncState: .synced)

        let active = try await repository.fetchActivePlaylists()
        XCTAssertEqual(active.first?.syncState, .synced)
    }
}
