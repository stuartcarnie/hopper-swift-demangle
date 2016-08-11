import Foundation

extension String {
    func split() -> [String] {
        return self.characters.split(separator: " ").map(String.init)
    }

    func strip() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}

