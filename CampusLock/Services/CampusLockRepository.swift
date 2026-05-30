import CampusLockCore
import Foundation

#if canImport(FamilyControls)
import FamilyControls
#endif

struct CampusLockRepository {
    private let stateFileURL: URL
    private let activitySelectionFileURL: URL

    init(fileManager: FileManager = .default) {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let directory = baseURL.appending(path: "CampusLock", directoryHint: .isDirectory)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        stateFileURL = directory.appending(path: "state.json")
        activitySelectionFileURL = directory.appending(path: "activity-selection.json")
    }

    func load() -> CampusLockState? {
        guard let data = try? Data(contentsOf: stateFileURL) else { return nil }
        return try? JSONDecoder.campusLock.decode(CampusLockState.self, from: data)
    }

    func save(_ state: CampusLockState) {
        guard let data = try? JSONEncoder.campusLock.encode(state) else { return }
        try? data.write(to: stateFileURL, options: [.atomic])
    }

    #if canImport(FamilyControls)
    func loadActivitySelection() -> FamilyActivitySelection? {
        guard let data = try? Data(contentsOf: activitySelectionFileURL) else { return nil }
        return try? JSONDecoder.campusLock.decode(FamilyActivitySelection.self, from: data)
    }

    func saveActivitySelection(_ selection: FamilyActivitySelection) {
        guard let data = try? JSONEncoder.campusLock.encode(selection) else { return }
        try? data.write(to: activitySelectionFileURL, options: [.atomic])
    }
    #endif
}

private extension JSONEncoder {
    static var campusLock: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var campusLock: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
