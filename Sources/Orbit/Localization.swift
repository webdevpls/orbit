import Foundation

/// The interface language. "system" follows macOS; otherwise a specific .lproj is used.
enum AppLanguage {
    static let key = "language"
    static let options: [(code: String, name: String)] = [("system", "Automatic"), ("en", "English"), ("pt-BR", "Português")]

    static var bundle: Bundle {
        let code = UserDefaults.standard.string(forKey: key) ?? "system"
        guard code != "system",
              let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let bundle = Bundle(path: path)
        else { return .main }
        return bundle
    }
}

/// Looks up a UI string in Localizable.strings. English strings are the keys; pt-BR.lproj translates them.
func L(_ key: String) -> String {
    AppLanguage.bundle.localizedString(forKey: key, value: key, table: nil)
}
