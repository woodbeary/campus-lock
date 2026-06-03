import Foundation

public struct SessionTiming: Equatable, Sendable {
    public var elapsedSeconds: TimeInterval

    public init(session: FocusSession, now: Date) {
        elapsedSeconds = max(0, now.timeIntervalSince(session.startedAt))
    }

    public var elapsedClock: String {
        Self.clock(elapsedSeconds)
    }

    public static func clock(_ seconds: TimeInterval) -> String {
        let totalSeconds = max(0, Int(seconds.rounded(.down)))
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return "\(hours):\(String(format: "%02d", minutes)):\(String(format: "%02d", seconds))"
        }
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}
