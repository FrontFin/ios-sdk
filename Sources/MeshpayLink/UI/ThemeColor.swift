#if canImport(UIKit)
import UIKit

extension UIColor {
    /// A colour from a `#RRGGBB` string. Falls back to opaque black on a value
    /// that doesn't parse — only the two built-in theme backgrounds are passed
    /// in, so this never happens at runtime.
    convenience init(linkHex hex: String) {
        let cleaned = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        var value: UInt64 = 0
        guard cleaned.count == 6, Scanner(string: cleaned).scanHexInt64(&value) else {
            self.init(white: 0, alpha: 1)
            return
        }
        self.init(
            red: CGFloat((value & 0xFF0000) >> 16) / 255,
            green: CGFloat((value & 0x00FF00) >> 8) / 255,
            blue: CGFloat(value & 0x0000FF) / 255,
            alpha: 1
        )
    }
}

/// The two resolved-theme backgrounds behind the WebView while Link loads.
enum ThemeColor {
    static func background(isDark: Bool) -> UIColor {
        UIColor(linkHex: isDark ? Constants.BackgroundColor.darkHex : Constants.BackgroundColor.lightHex)
    }

    static func foreground(isDark: Bool) -> UIColor {
        UIColor(linkHex: isDark ? Constants.BackgroundColor.lightHex : Constants.BackgroundColor.darkHex)
    }
}
#endif
