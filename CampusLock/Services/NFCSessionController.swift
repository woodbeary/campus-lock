import Foundation
import OSLog

#if canImport(CoreNFC)
import CoreNFC
#endif

enum NFCScanState: Equatable {
    case idle
    case scanning
    case detected
    case unavailable
    case failed(String)

    var fallbackText: String? {
        switch self {
        case .idle, .scanning:
            nil
        case .detected:
            "Detected"
        case .unavailable, .failed:
            "Try manually"
        }
    }

    var isScanning: Bool {
        self == .scanning
    }
}

@MainActor
final class NFCSessionController: NSObject {
    var onStateChange: ((NFCScanState) -> Void)?
    var onDetected: (() -> Void)?

    #if canImport(CoreNFC)
    private let logger = Logger(subsystem: "com.woodbeary.campuslock", category: "NFC")
    private var ndefSession: NFCNDEFReaderSession?
    private var tagSession: NFCTagReaderSession?
    private var activeSessionID: ObjectIdentifier?
    private var pollingRestartTask: Task<Void, Never>?
    private var didDetectTag = false
    #endif

    func beginScanning() {
        #if canImport(CoreNFC)
        cancelActiveSession(notify: false)
        guard NFCNDEFReaderSession.readingAvailable else {
            logger.error("NFC reader is unavailable on this device")
            onStateChange?(.unavailable)
            return
        }
        didDetectTag = false
        beginNDEFScan()
        #else
        onStateChange?(.unavailable)
        #endif
    }

    func cancel() {
        #if canImport(CoreNFC)
        cancelActiveSession(notify: true)
        #else
        onStateChange?(.idle)
        #endif
    }

    #if canImport(CoreNFC)
    private func beginNDEFScan() {
        let session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        session.alertMessage = "Hold iPhone near the class tag."
        ndefSession = session
        activeSessionID = ObjectIdentifier(session)
        onStateChange?(.scanning)
        logger.info("NFC NDEF scan started")
        session.begin()
    }

    private func beginTagScan() {
        let pollingOptions: NFCTagReaderSession.PollingOption = [.iso14443, .iso15693, .iso18092]
        guard let session = NFCTagReaderSession(pollingOption: pollingOptions, delegate: self) else {
            logger.error("NFCTagReaderSession failed to initialize")
            onStateChange?(.unavailable)
            return
        }
        session.alertMessage = "Hold iPhone near the class tag."
        tagSession = session
        activeSessionID = ObjectIdentifier(session)
        onStateChange?(.scanning)
        logger.info("NFC tag scan started")
        session.begin()
        schedulePollingRestart(for: session)
    }

    private func cancelActiveSession(notify: Bool) {
        pollingRestartTask?.cancel()
        pollingRestartTask = nil
        ndefSession?.invalidate()
        ndefSession = nil
        tagSession?.invalidate()
        tagSession = nil
        activeSessionID = nil
        didDetectTag = false
        if notify {
            onStateChange?(.idle)
        }
    }

    private func schedulePollingRestart(for activeSession: NFCTagReaderSession) {
        pollingRestartTask?.cancel()
        pollingRestartTask = Task { @MainActor [weak self, weak activeSession] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(1250))
                guard
                    !Task.isCancelled,
                    let self,
                    let activeSession,
                    let currentSession = self.tagSession,
                    currentSession === activeSession,
                    !self.didDetectTag
                else {
                    return
                }
                self.logger.debug("Restarting NFC tag polling")
                activeSession.restartPolling()
            }
        }
    }

    private func handleActivation(from sessionID: ObjectIdentifier) {
        guard activeSessionID == sessionID else {
            logger.debug("Ignoring stale NFC activation")
            return
        }
        onStateChange?(.scanning)
    }

    private func handleDetected(from sessionID: ObjectIdentifier) {
        guard activeSessionID == sessionID else {
            logger.debug("Ignoring stale NFC detection")
            return
        }
        guard !didDetectTag else { return }
        didDetectTag = true
        pollingRestartTask?.cancel()
        pollingRestartTask = nil
        ndefSession = nil
        tagSession = nil
        activeSessionID = nil
        logger.info("NFC tag detected")
        onStateChange?(.detected)
        onDetected?()
    }

    private func handleInvalidation(from invalidatedSessionID: ObjectIdentifier, error: Error) {
        if didDetectTag {
            didDetectTag = false
            return
        }
        guard activeSessionID == invalidatedSessionID else {
            logger.debug("Ignoring stale NFC invalidation")
            return
        }
        pollingRestartTask?.cancel()
        pollingRestartTask = nil
        ndefSession = nil
        tagSession = nil
        activeSessionID = nil
        guard let readerError = error as? NFCReaderError else {
            logger.error("NFC invalidated with non-reader error: \(error.localizedDescription, privacy: .public)")
            onStateChange?(.failed(error.localizedDescription))
            return
        }
        if readerError.code == .readerSessionInvalidationErrorUserCanceled {
            logger.info("NFC scan canceled by user")
            onStateChange?(.idle)
        } else {
            logger.error("NFC scan failed: \(readerError.localizedDescription, privacy: .public)")
            onStateChange?(.failed(readerError.localizedDescription))
        }
    }
    #endif
}

#if canImport(CoreNFC)
extension NFCSessionController: NFCNDEFReaderSessionDelegate {
    nonisolated func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        let sessionID = ObjectIdentifier(session)
        Task { @MainActor in
            logger.info("NFC NDEF session became active")
            handleActivation(from: sessionID)
        }
    }

    nonisolated func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        guard !messages.isEmpty else { return }
        let sessionID = ObjectIdentifier(session)
        session.alertMessage = "Attendance marked."
        Task { @MainActor in
            handleDetected(from: sessionID)
        }
    }

    nonisolated func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        let invalidatedSessionID = ObjectIdentifier(session)
        Task { @MainActor in
            handleInvalidation(from: invalidatedSessionID, error: error)
        }
    }
}

extension NFCSessionController: NFCTagReaderSessionDelegate {
    nonisolated func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        let sessionID = ObjectIdentifier(session)
        Task { @MainActor in
            logger.info("NFC tag session became active")
            handleActivation(from: sessionID)
        }
    }

    nonisolated func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        let invalidatedSessionID = ObjectIdentifier(session)
        Task { @MainActor in
            handleInvalidation(from: invalidatedSessionID, error: error)
        }
    }

    nonisolated func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard !tags.isEmpty else { return }
        let sessionID = ObjectIdentifier(session)
        session.alertMessage = "Attendance marked."
        Task { @MainActor in
            handleDetected(from: sessionID)
        }
        session.invalidate()
    }
}
#endif
