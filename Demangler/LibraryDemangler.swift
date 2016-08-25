import Foundation

private typealias SwiftDemangleFunction = @convention(c) (UnsafePointer<CChar>,
    UnsafeMutablePointer<CChar>, size_t) -> size_t

private let xcodePath = "/Applications/Xcode.app"
private let xcodeBetaPath = "/Applications/Xcode-beta.app"
private let kDemangleLibraryPath = ("Contents/Developer/Toolchains" +
    "/XcodeDefault.xctoolchain/usr/lib/libswiftDemangle.dylib")
private let kBufferSize = 1024

final class LibraryDemangler: InternalDemangler {
    private var handle: UnsafeMutableRawPointer = {
        var path = NSString(string: xcodePath).appendingPathComponent(kDemangleLibraryPath)
        if !FileManager.default.fileExists(atPath: path) {
            path = NSString(string: xcodeBetaPath).appendingPathComponent(kDemangleLibraryPath)
        }
        NSLog("using library from %@", path)
        return dlopen(path, RTLD_NOW)
    }()

    private lazy var internalDemangleFunction: SwiftDemangleFunction = {
        let address = dlsym(self.handle, "swift_demangle_getDemangledName")
        return unsafeBitCast(address, to: SwiftDemangleFunction.self)
    }()

    func demangle(string: String) -> String? {
        let formattedString = self.removingExcessLeadingUnderscores(fromString: string)
        let outputString = UnsafeMutablePointer<CChar>.allocate(capacity: kBufferSize)
        let resultSize = self.internalDemangleFunction(formattedString, outputString, kBufferSize)
        if resultSize > kBufferSize {
            NSLog("Attempted to demangle string with length \(resultSize) but buffer size \(kBufferSize)")
        }

        return String(utf8String: outputString)
    }

    private func removingExcessLeadingUnderscores(fromString string: String) -> String {
        if string.hasPrefix("__T") {
            return String(string.characters.dropFirst())
        }

        return string
    }

    deinit {
        dlclose(self.handle)
    }
}
