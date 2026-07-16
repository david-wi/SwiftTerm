import Foundation

/// Provenance for bytes leaving a terminal view.
///
/// Byte shape is not provenance: a user can paste a perfectly valid terminal
/// response sequence. Hosts that need to gate emulator replies must therefore
/// receive the origin captured at the emulator boundary.
public enum TerminalOutboundOrigin: Sendable, Equatable {
    case userInput
    case emulatorGeneratedReply
}

/// One contiguous range of outbound bytes with its origin preserved.
public struct TerminalOutboundSegment: Sendable, Equatable {
    public let origin: TerminalOutboundOrigin
    public let bytes: [UInt8]

    public init(origin: TerminalOutboundOrigin, bytes: [UInt8]) {
        self.origin = origin
        self.bytes = bytes
    }
}

/// A terminal outbound callback bound to the channel generation that caused
/// it. `generation` is captured when bytes enter the emulator (or when focus
/// changes), never looked up only when a later delegate callback fires.
public struct TerminalOutboundEvent: Sendable, Equatable {
    public let generation: UInt64
    public let segments: [TerminalOutboundSegment]

    public init(generation: UInt64, segments: [TerminalOutboundSegment]) {
        self.generation = generation
        self.segments = segments
    }
}
