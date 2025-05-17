import SwiftUI
import UniformTypeIdentifiers

struct SelectFilesView: View {
    let files: [SwiftFile]
    @State private var selectedFiles: Set<SwiftFile> = []
    @State private var packageInfo: PackageInfo?

    var body: some View {
        VStack {
            VStack {
                Text("Choose Files to Include in Package")
                    .bold()
                    .font(.title)
                Text("Select all Swift files you want included in your Package")
                    .font(.caption)
                    .foregroundStyle(.gray)

                List {
                    if files.isEmpty {
                        Text("No Swift Files were found, please select a Different Folder or Swift Files")
                    } else {
                        if selectedFiles.count == files.count {
                            Button("Deselect All") {
                                selectedFiles = []
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(Color.accentColor)
                        } else {
                            Button("Select All") {
                                for file in files {
                                    if !selectedFiles.contains(file) {
                                        selectedFiles.insert(file)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(Color.accentColor)
                        }
                    }
                    ForEach(files) { file in
                        HStack {
                            Text(file.name)
                            Spacer()
                            if selectedFiles.contains(file) {
                                Image(systemName: "checkmark")
                            }
                        }
                        .contentShape(Rectangle())  // Make entire row tappable
                        .onTapGesture {
                            if selectedFiles.contains(file) {
                                selectedFiles.remove(file)
                            } else {
                                selectedFiles.insert(file)
                            }
                        }
                        .bold(selectedFiles.contains(file))
                    }
                }
                .cornerRadius(15)
                .onChange(of: selectedFiles) { newSelection in
                    print("Selected files changed:", newSelection.map(\.name))
                    self.packageInfo = PackageInfo(
                        name: "My Swift Package",
                        files: Array(selectedFiles),
                        supportedPlaforms: []
                    )
                }

                if !selectedFiles.isEmpty {
                    NavigationLink("Next") {
                        PackageInfoView(packageInfo: packageInfo ?? PackageInfo(name: "ERROR", files: [], supportedPlaforms: []))
                    }
                    .disabled(packageInfo == nil)
                }
            }
            .padding()
        }
        .animation(.smooth)
    }
}


struct PackageInfo {
    var name: String
    var files: [SwiftFile]
    var supportedPlaforms: [Platforms]
    var swiftToolsVersion: CGFloat? = 6.0
}

struct PackageInfoView: View {
    @State var packageInfo: PackageInfo

    @State private var iOS = false
    @State private var macOS = false
    @State private var macCatalyst = false
    @State private var driverKit = false
    @State private var tvOS = false
    @State private var visionOS = false
    @State private var watchOS = false

    @State private var iOSVersion: CGFloat = 13
    @State private var macOSVersion: CGFloat = 11
    @State private var macCatalystVersion: CGFloat = 13
    @State private var driverKitVersion: CGFloat = 19
    @State private var tvOSVersion: CGFloat = 13
    @State private var visionOSVersion: CGFloat = 1
    @State private var watchOSVersion: CGFloat = 6
    @State var generated = ""
    var body: some View {
        VStack {
            Text("Package Info")
                .bold()
                .font(.title)

            Text("Please provide all Info Required for your Package")
                .font(.caption)
                .foregroundStyle(.gray)

            List {
                VStack(alignment: .leading) {
                    TextField("Package Name", text: Binding(get: { packageInfo.name }, set: { newValue in packageInfo.name = newValue.replacingOccurrences(of: " ", with: "_")}))
                    Text("Spaces will be replaced with _ in the Package so it's not recommended to use them")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                ScrollView(.horizontal) {
                    HStack {
                        Text("Supported Platforms")
                        Toggle("iOS", isOn: $iOS).toggleStyle(.checkbox)
                        Toggle("macOS", isOn: $macOS).toggleStyle(.checkbox)
                        Toggle("macCatalyst", isOn: $macCatalyst).toggleStyle(.checkbox)
                        Toggle("driverKit", isOn: $driverKit).toggleStyle(.checkbox)
                        Toggle("tvOS", isOn: $tvOS).toggleStyle(.checkbox)
                        Toggle("visionOS", isOn: $visionOS).toggleStyle(.checkbox)
                        Toggle("watchOS", isOn: $watchOS).toggleStyle(.checkbox)
                    }
                }
                .scrollIndicators(.never)

                if iOS {
                    versionField("iOS Version", cgFloatBinding: $iOSVersion)
                }
                if macOS {
                    versionField("macOS Version", cgFloatBinding: $macOSVersion)
                }
                if macCatalyst {
                    versionField("macCatalyst Version", cgFloatBinding: $macCatalystVersion)
                }
                if driverKit {
                    versionField("driverKit Version", cgFloatBinding: $driverKitVersion)
                }
                if tvOS {
                    versionField("tvOS Version", cgFloatBinding: $tvOSVersion)
                }
                if visionOS {
                    versionField("visionOS Version", cgFloatBinding: $visionOSVersion)
                }
                if watchOS {
                    versionField("watchOS Version", cgFloatBinding: $watchOSVersion)
                }
                VStack(alignment: .leading) {
                    HStack {
                        Text("Swift Tools Version")
                        TextField("Swift Tools Version", text: Binding(get: {
                            "\(packageInfo.swiftToolsVersion ?? 6.0)"
                        }, set: { newValue in
                            if newValue.isEmpty {
                                packageInfo.swiftToolsVersion = nil
                            } else {
                                packageInfo.swiftToolsVersion = extractNumber(from: newValue, swiftVersion: true)
                            }
                        }))
                        .textFieldStyle(.plain)
                    }
                    Text("For Example use Version 6.0 to use macOS 15")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
            .cornerRadius(15)
            HStack {
                Button(generated.isEmpty ? "Generate" : "Regenerate") {
                    packageInfo.supportedPlaforms = []
                    
                    if iOS {
                        packageInfo.supportedPlaforms.append(.iOS(version: iOSVersion))
                    }
                    if macOS {
                        packageInfo.supportedPlaforms.append(.macOS(version: macOSVersion))
                    }
                    if macCatalyst {
                        packageInfo.supportedPlaforms.append(.macCatalyst(version: macCatalystVersion))
                    }
                    if driverKit {
                        packageInfo.supportedPlaforms.append(.driverKit(version: driverKitVersion))
                    }
                    if tvOS {
                        packageInfo.supportedPlaforms.append(.tvOS(version: tvOSVersion))
                    }
                    if visionOS {
                        packageInfo.supportedPlaforms.append(.visionOS(version: visionOSVersion))
                    }
                    if watchOS {
                        packageInfo.supportedPlaforms.append(.watchOS(version: watchOSVersion))
                    }
                    generated = PackageGenerator.shared.createPackage(from: packageInfo)
                }
                if !generated.isEmpty {
                    NavigationLink("Continue") {
                        ReviewPackageView(generatedPackageString: generated, packageInfo: packageInfo)
                    }
                }
            }
        }
        .padding()
        .animation(.smooth)
    }

    @ViewBuilder
    func versionField(_ label: String, cgFloatBinding: Binding<CGFloat>) -> some View {
        let binding = Binding<String>(
            get: { String(cgFloatBinding.wrappedValue.description) },
            set: { newValue in
                if let cgfloat = extractNumber(from: newValue) {
                    cgFloatBinding.wrappedValue = cgfloat
                }
            }
        )
        HStack {
            Text(label)
            TextField("Version", text: binding)
                .textFieldStyle(.plain)
        }
    }
    func extractNumber(from string: String, swiftVersion: Bool? = nil) -> CGFloat? {
        let defaultNumber: CGFloat? = (swiftVersion ?? false) ? PackageGenerator.shared.swiftToolsVersionTrimmed : 15.0
        let filtered = string.filter { "0123456789.".contains($0) }
        if let double = Double(filtered) {
            return CGFloat(double)
        } else {
            return defaultNumber
        }
    }

    var supportedPlatformStates: [Bool] {
        [iOS, macOS, macCatalyst, driverKit, tvOS, visionOS, watchOS]
    }
}

import CodeEditorView
import LanguageSupport

struct ReviewPackageView: View {
    @State var generatedPackageString: String
    @State private var exportFolderURL: URL?
    @State var isExporting = false
    @State var packageInfo: PackageInfo
    @State var position: CodeEditor.Position = CodeEditor.Position()
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    @State var exportResult: Result<URL, any Error>?
    var body: some View {
            
        VStack {
            if let exportResult {
                VStack(spacing: 25) {
                    switch exportResult {
                    case .success(let url):
                        Text("Export Succeeded")
                            .bold()
                            .font(.title)
                        HStack {
                            Text("The Package has been exported to:")
                            Text(url.path(percentEncoded: false))
                                .foregroundStyle(Color.accentColor)
                                .onTapGesture {
                                    NSWorkspace.shared.activateFileViewerSelecting([url])
                                }
                        }
                    case .failure(let error):
                        Text("Export Failed")
                            .bold()
                            .font(.title)
                        
                        Text(error.localizedDescription)
                    }
                    Spacer()
                }
            } else {
                Text("Review Package File")
                    .bold()
                    .font(.title)
                
                Text("Review the Package File and make Changes if needed")
                    .font(.caption)
                    .foregroundStyle(.gray)
                CodeEditor(text: $generatedPackageString, position: $position, messages: .constant(Set()), language: .swift())
                    .environment(\.codeEditorTheme, colorScheme == .dark ? Theme.defaultDark : Theme.defaultLight)
                    .environment(\.codeEditorLayoutConfiguration, .init(showMinimap: false, wrapText: true))
                    .padding(15)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(15)
                Button("Finish") {
                    do {
                        try preparePackageFolder()
                        isExporting = true
                    } catch {
                        print("Error preparing package folder: \(error)")
                    }
                }
            }
        }
        .padding()
        .animation(.smooth)
        .fileExporter(
            isPresented: $isExporting,
            document: FolderDocument(folderURL: exportFolderURL),
            contentType: .folder,
            defaultFilename: packageInfo.name
        ) { result in
            self.exportResult = result
        }
    }
    func preparePackageFolder() throws {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        
        if let exportFolderURL = exportFolderURL,
           fileManager.fileExists(atPath: exportFolderURL.path) {
            try fileManager.removeItem(at: exportFolderURL)
        }
        
        let packageFolderURL = tempDir.appendingPathComponent(packageInfo.name.replacingOccurrences(of: " ", with: "_"), isDirectory: true)
        
        try fileManager.createDirectory(at: packageFolderURL, withIntermediateDirectories: true)
        
        let packageSwiftURL = packageFolderURL.appendingPathComponent("Package.swift")
        try generatedPackageString.write(to: packageSwiftURL, atomically: true, encoding: .utf8)
        
        let sourcesFolderURL = packageFolderURL.appendingPathComponent("Sources", isDirectory: true)
        let packageSourcesFolderURL = sourcesFolderURL.appendingPathComponent(packageInfo.name.replacingOccurrences(of: " ", with: "_"), isDirectory: true)
        try fileManager.createDirectory(at: packageSourcesFolderURL, withIntermediateDirectories: true)
        
        for file in packageInfo.files {
            let fileURL = packageSourcesFolderURL.appendingPathComponent(file.name)
            try file.data.write(to: fileURL)
        }
        
        exportFolderURL = packageFolderURL
    }
}

struct FolderDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.folder]

    var folderURL: URL?

    init(folderURL: URL?) {
        self.folderURL = folderURL
    }

    init(configuration: ReadConfiguration) throws {
        fatalError("Reading folder is not supported")
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let folderURL = folderURL else {
            throw NSError(domain: "FolderDocument", code: 1, userInfo: nil)
        }
        return try FileWrapper(url: folderURL, options: .immediate)
    }
}
