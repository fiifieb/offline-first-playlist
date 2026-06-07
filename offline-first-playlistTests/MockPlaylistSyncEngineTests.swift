import XCTest
@testable import offline_first_playlist

@MainActor
final class MockPlaylistSyncEngineTests: XCTestCase {
    func testEnqueueMarksPlaylistPendingAndIncrementsQueue() async throws {
        let repository = InMemoryPlaylistRepository()
        let playlist = try await repository.createPlaylist(named: "Queued")
        let engine = MockPlaylistSyncEngine(repository: repository)

        await engine.enqueue(playlistID: playlist.id, operation: .create)

        let pendingCount = await engine.pendingCount
        XCTAssertEqual(pendingCount, 1)

        let active = try await repository.fetchActivePlaylists()
        XCTAssertEqual(active.first?.syncState, .pending)
    }

    func testFlushMarksQueuedItemsSyncedOnSuccess() async throws {
        let repository = InMemoryPlaylistRepository()
        let playlist = try await repository.createPlaylist(named: "Queued")
        let engine = MockPlaylistSyncEngine(repository: repository)

        await engine.enqueue(playlistID: playlist.id, operation: .rename)
        await engine.flush()

        let pendingCount = await engine.pendingCount
        let failedCount = await engine.failedCount
        XCTAssertEqual(pendingCount, 0)
        XCTAssertEqual(failedCount, 0)

        let active = try await repository.fetchActivePlaylists()
        XCTAssertEqual(active.first?.syncState, .synced)
    }

    func testFlushMarksQueuedItemsFailedWhenOutcomeIsFailure() async throws {
        let repository = InMemoryPlaylistRepository()
        let playlist = try await repository.createPlaylist(named: "Queued")
        let engine = MockPlaylistSyncEngine(repository: repository) { _ in .failure }

        await engine.enqueue(playlistID: playlist.id, operation: .delete)
        await engine.flush()

        let pendingCount = await engine.pendingCount
        let failedCount = await engine.failedCount
        XCTAssertEqual(pendingCount, 0)
        XCTAssertEqual(failedCount, 1)

        let active = try await repository.fetchActivePlaylists()
        XCTAssertEqual(active.first?.syncState, .failed)
    }
}
