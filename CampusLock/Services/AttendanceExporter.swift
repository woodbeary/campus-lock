import CampusLockCore
import Foundation

enum AttendanceExporter {
    static func exportURL(records: [AttendanceRecord], fileManager: FileManager = .default) throws -> URL {
        let fileURL = fileManager.temporaryDirectory.appending(path: "campus-lock-attendance.csv")
        try csv(records: records).write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    static func csv(records: [AttendanceRecord]) -> String {
        var rows = ["period,class,room,checked_in,checked_out,state"]
        rows += records.map { record in
            [
                "\(record.session.period)",
                escape(record.session.title),
                escape(record.session.room),
                record.checkedInAt.ISO8601Format(),
                record.checkedOutAt?.ISO8601Format() ?? "",
                record.state.rawValue
            ].joined(separator: ",")
        }
        return rows.joined(separator: "\n") + "\n"
    }

    private static func escape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }
}
