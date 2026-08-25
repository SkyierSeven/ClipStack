import AppKit
import Carbon.HIToolbox
import Foundation

struct StoredHotkey: Codable, Equatable, Hashable {
    var keyCode: UInt32
    var carbonModifiers: UInt32

    static let defaultPanel = StoredHotkey(
        keyCode: UInt32(kVK_ANSI_X),
        carbonModifiers: UInt32(cmdKey | shiftKey)
    )

    var displayParts: [String] {
        HotkeyDisplay.parts(keyCode: keyCode, carbonModifiers: carbonModifiers)
    }

    var displayString: String {
        displayParts.joined(separator: " ")
    }

    var isValidPanelHotkey: Bool {
        carbonModifiers != 0 && keyCode != 0
    }
}

enum HotkeyDisplay {
    static func parts(keyCode: UInt32, carbonModifiers: UInt32) -> [String] {
        var parts: [String] = []
        if carbonModifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if carbonModifiers & UInt32(optionKey) != 0 { parts.append("⌥") }
        if carbonModifiers & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if carbonModifiers & UInt32(cmdKey) != 0 { parts.append("⌘") }
        parts.append(keyString(for: keyCode))
        return parts
    }

    static func format(keyCode: UInt32, carbonModifiers: UInt32) -> String {
        parts(keyCode: keyCode, carbonModifiers: carbonModifiers).joined(separator: " ")
    }

    private static func keyString(for keyCode: UInt32) -> String {
        switch Int(keyCode) {
        case kVK_ANSI_A: "A"
        case kVK_ANSI_B: "B"
        case kVK_ANSI_C: "C"
        case kVK_ANSI_D: "D"
        case kVK_ANSI_E: "E"
        case kVK_ANSI_F: "F"
        case kVK_ANSI_G: "G"
        case kVK_ANSI_H: "H"
        case kVK_ANSI_I: "I"
        case kVK_ANSI_J: "J"
        case kVK_ANSI_K: "K"
        case kVK_ANSI_L: "L"
        case kVK_ANSI_M: "M"
        case kVK_ANSI_N: "N"
        case kVK_ANSI_O: "O"
        case kVK_ANSI_P: "P"
        case kVK_ANSI_Q: "Q"
        case kVK_ANSI_R: "R"
        case kVK_ANSI_S: "S"
        case kVK_ANSI_T: "T"
        case kVK_ANSI_U: "U"
        case kVK_ANSI_V: "V"
        case kVK_ANSI_W: "W"
        case kVK_ANSI_X: "X"
        case kVK_ANSI_Y: "Y"
        case kVK_ANSI_Z: "Z"
        case kVK_ANSI_0: "0"
        case kVK_ANSI_1: "1"
        case kVK_ANSI_2: "2"
        case kVK_ANSI_3: "3"
        case kVK_ANSI_4: "4"
        case kVK_ANSI_5: "5"
        case kVK_ANSI_6: "6"
        case kVK_ANSI_7: "7"
        case kVK_ANSI_8: "8"
        case kVK_ANSI_9: "9"
        case kVK_Space: "Space"
        default: "Key\(keyCode)"
        }
    }

    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var modifiers: UInt32 = 0
        if flags.contains(.command) { modifiers |= UInt32(cmdKey) }
        if flags.contains(.option) { modifiers |= UInt32(optionKey) }
        if flags.contains(.control) { modifiers |= UInt32(controlKey) }
        if flags.contains(.shift) { modifiers |= UInt32(shiftKey) }
        return modifiers
    }
}

extension HotkeyDisplay {
    static func from(event: NSEvent) -> StoredHotkey {
        StoredHotkey(
            keyCode: UInt32(event.keyCode),
            carbonModifiers: carbonModifiers(from: event.modifierFlags)
        )
    }
}
