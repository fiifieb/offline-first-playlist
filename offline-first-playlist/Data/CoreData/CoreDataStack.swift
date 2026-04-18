import CoreData
import Foundation

struct CoreDataStack {
    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    init(storeURL: URL) throws {
        container = NSPersistentContainer(
            name: "OfflineFirstPlaylist",
            managedObjectModel: Self.managedObjectModel
        )

        let description = NSPersistentStoreDescription(url: storeURL)
        description.type = NSSQLiteStoreType
        description.shouldInferMappingModelAutomatically = true
        description.shouldMigrateStoreAutomatically = true
        container.persistentStoreDescriptions = [description]

        try Self.loadStores(for: container)
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    static func inMemory() throws -> CoreDataStack {
        let container = NSPersistentContainer(
            name: "OfflineFirstPlaylist",
            managedObjectModel: managedObjectModel
        )

        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        try loadStores(for: container)
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true

        return CoreDataStack(container: container)
    }

    private init(container: NSPersistentContainer) {
        self.container = container
    }

    private static func loadStores(for container: NSPersistentContainer) throws {
        var loadError: Error?
        let semaphore = DispatchSemaphore(value: 0)

        container.loadPersistentStores { _, error in
            loadError = error
            semaphore.signal()
        }

        semaphore.wait()

        if let loadError {
            throw loadError
        }
    }

    private static var managedObjectModel: NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let playlist = NSEntityDescription()
        playlist.name = "PlaylistEntity"
        playlist.managedObjectClassName = NSStringFromClass(PlaylistEntity.self)

        let id = NSAttributeDescription()
        id.name = "id"
        id.attributeType = .UUIDAttributeType
        id.isOptional = false

        let name = NSAttributeDescription()
        name.name = "name"
        name.attributeType = .stringAttributeType
        name.isOptional = false

        let deletedFlag = NSAttributeDescription()
        deletedFlag.name = "deletedFlag"
        deletedFlag.attributeType = .booleanAttributeType
        deletedFlag.isOptional = false

        let createdAt = NSAttributeDescription()
        createdAt.name = "createdAt"
        createdAt.attributeType = .dateAttributeType
        createdAt.isOptional = false

        let updatedAt = NSAttributeDescription()
        updatedAt.name = "updatedAt"
        updatedAt.attributeType = .dateAttributeType
        updatedAt.isOptional = false

        let syncStateRaw = NSAttributeDescription()
        syncStateRaw.name = "syncStateRaw"
        syncStateRaw.attributeType = .stringAttributeType
        syncStateRaw.isOptional = false

        playlist.properties = [id, name, deletedFlag, createdAt, updatedAt, syncStateRaw]
        model.entities = [playlist]

        return model
    }
}
