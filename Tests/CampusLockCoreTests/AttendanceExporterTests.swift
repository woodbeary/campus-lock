import Foundation
import Testing

@testable import CampusLockCore

@Suite("Attendance export")
struct AttendanceExporterTests {
    @Test("CSV includes stable header and escaped rows")
    func csvExport() {
        let session = ClassSession(
            period: 1,
            title: "Biology, Lab",
            room: "Room 204",
            startsAt: Date(timeIntervalSince1970: 1_800_000_000)
        )
        let record = AttendanceRecord(
            session: session,
            checkedInAt: Date(timeIntervalSince1970: 1_800_000_000),
            checkedOutAt: Date(timeIntervalSince1970: 1_800_000_060),
            state: .checkedOut
        )

        let csv = AttendanceExporter.csv(records: [record])

        #expect(csv.contains("period,class,room,checked_in,checked_out,state"))
        #expect(csv.contains("1,\"Biology, Lab\",Room 204"))
        #expect(csv.contains(",checkedOut"))
    }
}
