import CoreData
import XCTest
@testable import offline_first_playlist

final class CoreDataStackTests: XCTestCase {
    func testInMemoryStoreRoundTripSaveAndFetch() throws {
        let stack = try CoreDataStack.inMemory()
        let context = stack.viewContext

        let playlist = PlaylistEntity(context: context)
        playlist.id = UUID()
        playlist.name = "Deep Focus"
        playlist.deletedFlag = false
        playlist.createdAt = Date()
        playlist.updatedAt = Date()
        playlist.syncStateRaw = "pending"

        try context.save()

        let request = NSFetchRequest<PlaylistEntity>(entityName: "PlaylistEntity")
        let playlists = try context.fetch(request)

        XCTAssertEqual(playlists.count, 1)
        XCTAssertEqual(playlists.first?.name, "Deep Focus")
        XCTAssertEqual(playlists.first?.syncStateRaw, "pending")
    }

    func testSQLiteStoreLoadsAtCustomURL() throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("sqlite")

        defer {
            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("-shm"))
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("-wal"))
        }

        let stack = try CoreDataStack(storeURL: storeURL)
        let store = try XCTUnwrap(stack.container.persistentStoreCoordinator.persistentStores.first)

        XCTAssertEqual(store.type, NSSQLiteStoreType)
    }
}
