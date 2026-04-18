import XCTest
@testable import offline_first_playlist

final class PlaylistRepositoryContractTests: XCTestCase {
    func testCreatePlaylistAppearsInActiveList() async throws {
        let repository = InMemoryPlaylistRepository()

        let created = try await repository.createPlaylist(named: "Roadtrip")
        let active = try await repository.fetchActivePlaylists()

        XCTAssertEqual(created.name, "Roadtrip")
        XCTAssertEqual(active.count, 1)
        XCTAssertEqual(active.first?.id, created.id)
        XCTAssertFalse(active.first?.isDeleted ?? true)
        XCTAssertEqual(active.first?.syncState, .pending)
    }

    func testRenamePlaylistUpdatesName() async throws {
        let repository = InMemoryPlaylistRepository()

        let created = try await repository.createPlaylist(named: "Old")
        let renamed = try await repository.renamePlaylist(id: created.id, name: "New")

        XCTAssertEqual(renamed.name, "New")
        XCTAssertEqual(renamed.syncState, .pending)

        let active = try await repository.fetchActivePlaylists()
        XCTAssertEqual(active.first?.name, "New")
    }

    func testSoftDeleteMovesPlaylistToDeletedCollection() async throws {
        let repository = InMemoryPlaylistRepository()

        let created = try await repository.createPlaylist(named: "Workout")
        try await repository.softDeletePlaylist(id: created.id)

        let active = try await repository.fetchActivePlaylists()
        let deleted = try await repository.fetchDeletedPlaylists()

        XCTAssertTrue(active.isEmpty)
        XCTAssertEqual(deleted.count, 1)
        XCTAssertEqual(deleted.first?.id, created.id)
        XCTAssertTrue(deleted.first?.isDeleted ?? false)
    }

    func testRestoreMovesPlaylistBackToActiveCollection() async throws {
        let repository = InMemoryPlaylistRepository()

        let created = try await repository.createPlaylist(named: "Focus")
        try await repository.softDeletePlaylist(id: created.id)
        try await repository.restorePlaylist(id: created.id)

        let active = try await repository.fetchActivePlaylists()
        let deleted = try await repository.fetchDeletedPlaylists()

        XCTAssertEqual(active.count, 1)
        XCTAssertEqual(active.first?.id, created.id)
        XCTAssertFalse(active.first?.isDeleted ?? true)
        XCTAssertTrue(deleted.isEmpty)
    }
}
