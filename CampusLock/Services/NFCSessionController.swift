import Foundation

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
    private var session: NFCTagReaderSession?
    private var didDetectTag = false
    #endif

    func beginScanning() {
        #if canImport(CoreNFC)
        guard NFCTagReaderSession.readingAvailable else {
            onStateChange?(.unavailable)
            return
        }
        didDetectTag = false
        let pollingOptions: NFCTagReaderSession.PollingOption = [.iso14443, .iso15693, .iso18092]
        guard let session = NFCTagReaderSession(pollingOption: pollingOptions, delegate: self) else {
            onStateChange?(.unavailable)
            return
        }
        session.alertMessage = "Hold iPhone near the class tag."
        self.session = session
        onStateChange?(.scanning)
        session.begin()
        #else
        onStateChange?(.unavailable)
        #endif
    }

    func cancel() {
        #if canImport(CoreNFC)
        session?.invalidate()
        session = nil
        didDetectTag = false
        #endif
        onStateChange?(.idle)
    }

    #if canImport(CoreNFC)
    private func handleDetected() {
        didDetectTag = true
        self.session = nil
        onStateChange?(.detected)
        onDetected?()
    }

    private func handleInvalidation(error: Error) {
        session = nil
        if didDetectTag {
            didDetectTag = false
            return
        }
        guard let readerError = error as? NFCReaderError else {
            onStateChange?(.failed(error.localizedDescription))
            return
        }
        if readerError.code == .readerSessionInvalidationErrorUserCanceled {
            onStateChange?(.idle)
        } else {
            onStateChange?(.failed(readerError.localizedDescription))
        }
    }
    #endif
}

#if canImport(CoreNFC)
extension NFCSessionController: NFCTagReaderSessionDelegate {
    nonisolated func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        Task { @MainActor in
            onStateChange?(.scanning)
        }
    }

    nonisolated func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        Task { @MainActor in
            handleInvalidation(error: error)
        }
    }

    nonisolated func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard !tags.isEmpty else { return }
        session.alertMessage = "Attendance marked."
        session.invalidate()
        Task { @MainActor in
            handleDetected()
        }
    }
}
#endif
