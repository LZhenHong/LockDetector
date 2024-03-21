import Foundation

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

typealias Application = NSApplication
#elseif canImport(UIKit)
import UIKit

typealias Application = UIApplication
#endif

public class LockDetector {
    public enum ScreenState {
        case unknown, locked, unlocked
    }

    public static var isAppExtension: Bool {
        let cls: AnyClass? = NSClassFromString(String(describing: Application.self))

        guard let cls, cls.responds(to: #selector(getter: Application.shared)) else {
            return false
        }

        guard Bundle.main.bundlePath.hasSuffix(".appex") else {
            return false
        }

        return true
    }

    public static var protectedFilePath: String = {
        guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return ""
        }
        return path + "/protected"
    }()

    // https://developer.apple.com/documentation/foundation/fileprotectiontype/1616200-complete
    private static func createProtectedFile(with path: String) {
        FileManager.default.createFile(atPath: path,
                                       contents: "".data(using: .utf8),
                                       attributes: [FileAttributeKey.protectionKey: FileProtectionType.complete])
    }

    private static func isProtectedFileExsits() -> Bool {
        guard !protectedFilePath.isEmpty,
              FileManager.default.fileExists(atPath: protectedFilePath)
        else {
            return false
        }
        return true
    }

    /// Create protected file is not exsits.
    public static func initialize() {
        guard !isProtectedFileExsits() else {
            return
        }
        createProtectedFile(with: protectedFilePath)
    }

    public static var currentState: ScreenState {
        isAppExtension ? extensionAppScreenState : mainAppScreenState
    }

    private static var extensionAppScreenState: ScreenState {
        guard isProtectedFileExsits() else {
            createProtectedFile(with: protectedFilePath)
            return .unknown
        }

        do {
            _ = try String(contentsOfFile: protectedFilePath)
        } catch {
            return .locked
        }
        return .unlocked
    }

    private static var mainAppScreenState: ScreenState {
        return Application.shared.isProtectedDataAvailable ? ScreenState.unlocked : ScreenState.locked
    }
}
