import Foundation

/// Opt-in diagnostics for synchronized-output paint timing.
///
/// Production builds keep this silent unless an operator explicitly sets
/// `SWIFTTERM_SYNC_DEBUG=1`; call sites remain cheap and do not eagerly build
/// their messages while diagnostics are disabled.
enum SyncDebug {
    private static let isEnabled = ProcessInfo.processInfo.environment["SWIFTTERM_SYNC_DEBUG"] == "1"

    static func log(_ message: @autoclosure () -> String) {
        guard isEnabled else { return }
        print("[SwiftTerm sync] \(message())")
    }
}
