import Demangler
import Foundation

private enum Action {
    case demangleClosest
    case demangleAll
}

extension SwiftDemangle {
    @objc
    func demangleClosestName() {
        self.performAction(.demangleClosest)
    }

    @objc
    func demangleAllProcedures() {
        self.performAction(.demangleAll)
    }

    private func performAction(_ action: Action) {
        let function: (HPDocument) -> Void
        switch action {
        case .demangleClosest:
            function = self.demangleClosestName
        case .demangleAll:
            function = self.demangleAllProcedures
        }

        if let document = self.services.currentDocument() {
            function(document)
        } else {
            self.services.logMessage("No document currently loaded")
        }
    }

    // MARK: - Actions

    private func demangleClosestName(withDocument document: HPDocument) {
        document.wait(withReason: "Demangling Closest Name") { document, file, _ in
            let address = file.nearestNamedAddress(beforeVirtualAddress: document.currentAddress())
            let mangledString = file.name(forVirtualAddress: address)
            let demangleResult = self.demangler.demangle(string: mangledString)
            self.handle(demangleResult: demangleResult, forAddress: address, mangledString: mangledString,
                        file: file, document: document)
        }
    }

    func handle(demangleResult result: DemangleResult, forAddress address: Address,
                               mangledString: String?, file: HPDisassembledFile, document: HPDocument)
    {
        switch result {
        case .success(let demangledString):
            file.setName(demangledString, forVirtualAddress: address, reason: .NCReason_Script)
            document.logStringMessage("Demangled '\(mangledString ?? "")' -> '\(demangledString)'")
        case .ignored(let ignoredString):
            document.logStringMessage("Ignoring '\(ignoredString)'")
        case .failed(let failedString):
            document.logStringMessage("Failed to demangle '\(failedString)'")
        }
    }
}
