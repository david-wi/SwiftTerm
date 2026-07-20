import Testing
@testable import SwiftTerm

final class TerminalOutboundEventTests {
    private final class ProvenanceDelegate: TerminalDelegate {
        var events: [TerminalOutboundEvent] = []
        var legacyBytes: [[UInt8]] = []

        func send(source: Terminal, data: ArraySlice<UInt8>) {
            legacyBytes.append(Array(data))
        }

        func send(source: Terminal, outbound: TerminalOutboundEvent) {
            events.append(outbound)
        }
    }

    @Test func focusAndBothResponseHelpersCarryGeneratedOriginAndGeneration() {
        let delegate = ProvenanceDelegate()
        let terminal = Terminal(delegate: delegate, options: TerminalOptions(cols: 80, rows: 24, scrollback: 0))
        terminal.outboundGeneration = 41
        terminal.feed(text: "\u{1B}[?1004h") // enable focus reporting

        terminal.setTerminalFocus(true)
        terminal.sendResponse(text: "text-response")
        // `sendResponse(_:)` accepts a `[UInt8]`, not an untyped integer
        // literal array. Keep the test on the public API contract used by the
        // emulator's existing `cc.CSI` call sites.
        let csi: [UInt8] = [0x1B, 0x5B]
        terminal.sendResponse(csi, "6n")

        #expect(delegate.events.count == 3)
        #expect(delegate.events.allSatisfy { $0.generation == 41 })
        #expect(delegate.events.allSatisfy {
            $0.segments.count == 1 && $0.segments[0].origin == .emulatorGeneratedReply
        })
        #expect(delegate.events[0].segments[0].bytes == [0x1B, 0x5B, 0x49])
        #expect(delegate.events[1].segments[0].bytes == Array("text-response".utf8))
        #expect(delegate.events[2].segments[0].bytes == [0x1B, 0x5B, 0x36, 0x6E])
        #expect(delegate.legacyBytes.isEmpty)
    }

    @Test func legacyDelegateStillReceivesGeneratedBytesInOrder() {
        let delegate = TerminalTestDelegate()
        let terminal = Terminal(delegate: delegate, options: TerminalOptions(cols: 80, rows: 24, scrollback: 0))

        terminal.sendResponse(text: "legacy")

        #expect(delegate.sentData == [Array("legacy".utf8)])
    }

    @Test func generationReplacementDiscardsIncompleteControlQuery() {
        let delegate = ProvenanceDelegate()
        let terminal = Terminal(delegate: delegate, options: TerminalOptions(cols: 80, rows: 24, scrollback: 0))
        terminal.outboundGeneration = 7

        terminal.feed(byteArray: [0x1B, 0x5B])
        terminal.outboundGeneration = 8
        terminal.feed(text: "c")

        #expect(delegate.events.isEmpty)
    }

    @Test func mixedEventPreservesSegmentOriginsAndGeneration() {
        let event = TerminalOutboundEvent(
            generation: 23,
            segments: [
                TerminalOutboundSegment(origin: .emulatorGeneratedReply, bytes: [0x1B, 0x5B, 0x3F, 0x31, 0x3B, 0x32, 0x63]),
                TerminalOutboundSegment(origin: .userInput, bytes: Array("typed".utf8)),
            ]
        )

        #expect(event.generation == 23)
        #expect(event.segments.map(\.origin) == [.emulatorGeneratedReply, .userInput])
        #expect(event.segments[1].bytes == Array("typed".utf8))
    }
}
