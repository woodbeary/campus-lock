import CampusLockCore
import Foundation

struct CampusLockRepository {
    private let fileURL: URL

    init(fileManager: FileManager = .default) {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let directory = baseURL.appending(path: "CampusLock", directoryHint: .isDirectory)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appending(path: "state.json")
    }

    func load() -> CampusLockState? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder.campusLock.decode(CampusLockState.self, from: data)
    }

    func save(_ state: CampusLockState) {
        guard let data = try? JSONEncoder.campusLock.encode(state) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
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
