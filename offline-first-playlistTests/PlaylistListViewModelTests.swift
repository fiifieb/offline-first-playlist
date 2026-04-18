import Foundation
import XCTest
@testable import offline_first_playlist

@MainActor
final class PlaylistListViewModelTests: XCTestCase {
    func testLoadFetchesActiveAndDeletedPlaylists() async throws {
        let active = Playlist(
            id: UUID(),
            name: "Active",
            isDeleted: false,
            createdAt: Date(),
            updatedAt: Date(),
            syncState: .pending
        )
        let deleted = Playlist(
            id: UUID(),
            name: "Deleted",
            isDeleted: true,
            createdAt: Date(),
            updatedAt: Date(),
            syncState: .pending
        )

        let repository = FakePlaylistRepository(active: [active], deleted: [deleted])
        let viewModel = PlaylistListViewModel(repository: repository)

        await viewModel.load()

        XCTAssertEqual(viewModel.activePlaylists.count, 1)
        XCTAssertEqual(viewModel.deletedPlaylists.count, 1)
        XCTAssertEqual(viewModel.activePlaylists.first?.name, "Active")
        XCTAssertEqual(viewModel.deletedPlaylists.first?.name, "Deleted")
    }

    func testCreatePlaylistCreatesAndReloads() async throws {
        let repository = FakePlaylistRepository(active: [], deleted: [])
        let viewModel = PlaylistListViewModel(repository: repository)
        viewModel.isPresentingCreateSheet = true
        viewModel.newPlaylistName = "  Chill Mix  "

        await viewModel.createPlaylist()

        XCTAssertEqual(viewModel.activePlaylists.count, 1)
        XCTAssertEqual(viewModel.activePlaylists.first?.name, "Chill Mix")
        XCTAssertEqual(viewModel.newPlaylistName, "")
        XCTAssertFalse(viewModel.isPresentingCreateSheet)
    }

    func testSoftDeleteMovesPlaylistToDeletedSection() async throws {
        let playlist = Playlist(
            id: UUID(),
            name: "Workout",
            isDeleted: false,
            createdAt: Date(),
            updatedAt: Date(),
            syncState: .pending
        )

        let repository = FakePlaylistRepository(active: [playlist], deleted: [])
        let viewModel = PlaylistListViewModel(repository: repository)

        await viewModel.load()
        await viewModel.softDeletePlaylist(id: playlist.id)

        XCTAssertEqual(viewModel.activePlaylists.count, 0)
        XCTAssertEqual(viewModel.deletedPlaylists.count, 1)
        XCTAssertEqual(viewModel.deletedPlaylists.first?.id, playlist.id)
    }

    func testRestoreMovesPlaylistToActiveSection() async throws {
        let playlist = Playlist(
            id: UUID(),
            name: "Archive",
            isDeleted: true,
            createdAt: Date(),
            updatedAt: Date(),
            syncState: .pending
        )

        let repository = FakePlaylistRepository(active: [], deleted: [playlist])
        let viewModel = PlaylistListViewModel(repository: repository)

        await viewModel.load()
        await viewModel.restorePlaylist(id: playlist.id)

        XCTAssertEqual(viewModel.deletedPlaylists.count, 0)
        XCTAssertEqual(viewModel.activePlaylists.count, 1)
        XCTAssertEqual(viewModel.activePlaylists.first?.id, playlist.id)
    }

    func testBeginRenamePrefillsAndShowsRenameSheet() async throws {
        let playlist = Playlist(
            id: UUID(),
            name: "Evening Mix",
            isDeleted: false,
            createdAt: Date(),
            updatedAt: Date(),
            syncState: .pending
        )

        let repository = FakePlaylistRepository(active: [playlist], deleted: [])
        let viewModel = PlaylistListViewModel(repository: repository)

        viewModel.beginRename(playlist: playlist)

        XCTAssertTrue(viewModel.isPresentingRenameSheet)
        XCTAssertEqual(viewModel.renamePlaylistName, "Evening Mix")
    }

    func testRenamePlaylistUpdatesNameAndDismissesSheet() async throws {
        let playlist = Playlist(
            id: UUID(),
            name: "Old Name",
            isDeleted: false,
            createdAt: Date(),
            updatedAt: Date(),
            syncState: .pending
        )

        let repository = FakePlaylistRepository(active: [playlist], deleted: [])
        let viewModel = PlaylistListViewModel(repository: repository)

        await viewModel.load()
        viewModel.beginRename(playlist: playlist)
        viewModel.renamePlaylistName = "  New Name  "

        await viewModel.renamePlaylist()

        XCTAssertEqual(viewModel.activePlaylists.first?.name, "New Name")
        XCTAssertFalse(viewModel.isPresentingRenameSheet)
        XCTAssertEqual(viewModel.renamePlaylistName, "")
    }
}

private final class FakePlaylistRepository: PlaylistRepository {
    private enum RepositoryError: Error {
        case notFound
    }

    private var active: [Playlist]
    private var deleted: [Playlist]

    init(active: [Playlist], deleted: [Playlist]) {
        self.active = active
        self.deleted = deleted
    }

    func fetchActivePlaylists() async throws -> [Playlist] {
        active
    }

    func fetchDeletedPlaylists() async throws -> [Playlist] {
        deleted
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
        active.insert(playlist, at: 0)
        return playlist
    }

    func renamePlaylist(id: UUID, name: String) async throws -> Playlist {
        if let index = active.firstIndex(where: { $0.id == id }) {
            active[index].name = name
            active[index].updatedAt = Date()
            return active[index]
        }

        if let index = deleted.firstIndex(where: { $0.id == id }) {
            deleted[index].name = name
            deleted[index].updatedAt = Date()
            return deleted[index]
        }

        throw RepositoryError.notFound
    }

    func softDeletePlaylist(id: UUID) async throws {
        guard let index = active.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }

        var playlist = active.remove(at: index)
        playlist.isDeleted = true
        playlist.updatedAt = Date()
        deleted.insert(playlist, at: 0)
    }

    func restorePlaylist(id: UUID) async throws {
        guard let index = deleted.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }

        var playlist = deleted.remove(at: index)
        playlist.isDeleted = false
        playlist.updatedAt = Date()
        active.insert(playlist, at: 0)
    }
}
