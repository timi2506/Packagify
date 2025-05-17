import SwiftUI

class PackageGenerator: ObservableObject {
    static let shared = PackageGenerator()
    @Published var swiftToolsVersion: String? {
        didSet {
            if let swiftToolsVersion {
                swiftToolsVersionTrimmed = CGFloat(Double(trimToMajorMinor(version: swiftToolsVersion)) ?? 6.0)
            }
        }
    }
    @Published var swiftToolsVersionTrimmed: CGFloat?
    init() {
        self.swiftToolsVersion = getSwiftLanguageVersion()
    }
    func getSwiftLanguageVersion() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
        process.arguments = ["--version"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                if let match = output.range(of: #"Apple Swift version (\d+\.\d+(\.\d+)?)"#, options: .regularExpression) {
                    let version = output[match].replacingOccurrences(of: "Apple Swift version ", with: "")
                    return version
                }
            }
        } catch {
            print("Error running swift: \(error)")
        }

        return nil
    }
    func trimToMajorMinor(version: String) -> String {
        let components = version.split(separator: ".")
        guard components.count >= 2 else { return version }
        return "\(components[0]).\(components[1])"
    }
    func createPackage(from packageInfo: PackageInfo) -> String {
        var platformStrings: [String] = []
        for plaform in packageInfo.supportedPlaforms {
            platformStrings.append(
                supportedPlatformString(for: plaform)
            )
        }
        let finishedPlatformStrings = platformStrings.joined(separator: ",\n")
        let package = """
    // swift-tools-version: \(packageInfo.swiftToolsVersion ?? 6.0)
    import PackageDescription

    let package = Package(
        name: "\(packageInfo.name.replacingOccurrences(of: " ", with: "_"))",
        platforms: [
            \(finishedPlatformStrings)
        ],
        products: [
            .library(
                name: "\(packageInfo.name.replacingOccurrences(of: " ", with: "_"))",
                targets: ["\(packageInfo.name.replacingOccurrences(of: " ", with: "_"))"]
            ),
        ],
        dependencies: [],
        targets: [
            .target(
                name: "\(packageInfo.name.replacingOccurrences(of: " ", with: "_"))",
                dependencies: [],
                path: "Sources/\(packageInfo.name.replacingOccurrences(of: " ", with: "_"))",
                resources: []
            )
        ]
    )
    """
        return package
    }
    func supportedPlatformString(for platform: Platforms) -> String {
        switch platform {
        case .iOS(let version):
            ".iOS(.v\(version))".replacingOccurrences(of: ".0", with: "")
        case .macOS(let version):
            ".macOS(.v\(version))".replacingOccurrences(of: ".0", with: "")
        case .macCatalyst(let version):
            ".macCatalyst(.v\(version))".replacingOccurrences(of: ".0", with: "")
        case .driverKit(let version):
            ".driverKit(.v\(version))".replacingOccurrences(of: ".0", with: "")
        case .tvOS(let version):
            ".tvOS(.v\(version))"
        case .visionOS(let version):
            ".visionOS(.v\(version))".replacingOccurrences(of: ".0", with: "")
        case .watchOS(let version):
            ".watchOS(.v\(version))".replacingOccurrences(of: ".0", with: "")
        }
    }
}

enum Platforms {
    case iOS(version: CGFloat)
    case macOS(version: CGFloat)
    case macCatalyst(version: CGFloat)
    case driverKit(version: CGFloat)
    case tvOS(version: CGFloat)
    case visionOS(version: CGFloat)
    case watchOS(version: CGFloat)
}
