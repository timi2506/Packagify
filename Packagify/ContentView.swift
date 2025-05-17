//
//  ContentView.swift
//  Packagify
//
//  Created by Tim on 17.05.25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State var droppedFiles: [File]?
    @State private var path = NavigationPath()
    @State var isHovering = false
    @State var importFiles = false
    var body: some View {
        NavigationStack {
            VStack {
                if let droppedFiles {
                    SelectFilesView(files: droppedFiles.extractSwiftFiles())
                } else {
                    VStack(spacing: 25) {
                        Image(systemName: "swift")
                            .font(.system(size: 75))
                            .bold()
                            .foregroundStyle(.gray.opacity(0.5))
                        Text("Drop Swift Files or a Folder containing Swift Files")
                            .bold()
                    }
                    .padding(15)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .foregroundStyle(isHovering ? Color.accentColor.opacity(0.10): Color.primary.opacity(0.10))
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(isHovering ? Color.accentColor.opacity(0.5): Color.primary.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [10, 5]))
                    }
                    .dropDestination(for: URL.self, action: { items, _ in
                        let (result, files) = handleDroppedFiles(items)
                        droppedFiles = files
                        return result
                    }, isTargeted: { bool in isHovering = bool })
                    .onTapGesture {
                        importFiles = true
                    }
                    .fileImporter(isPresented: $importFiles, allowedContentTypes: [.swiftSource, .folder], allowsMultipleSelection: true, onCompletion: { result in
                        switch result {
                        case .success(let urls):
                            let (_, files) = handleDroppedFiles(urls)
                            droppedFiles = files
                        case .failure:
                            print("Error Picking Files")
                        }
                    })
                    Text("OR")
                        .foregroundStyle(.gray)
                        .font(.caption)
                        .padding(.vertical, 25)

                    VStack {
                        Button("Start with an Empty File") {
                            do {
                                let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("Source.swift", conformingTo: .data)
                                let fileData = String("import Foundation\n")
                                try fileData.data(using: .utf8)!.write(to: fileURL)
                                let (_, files) = handleDroppedFiles([fileURL])
                                droppedFiles = files
                            } catch {
                                print(error.localizedDescription)
                            }
                        }
                        .bold()
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.accentColor)
                        Text("This is useful if you want to have the Package Project Structure for coding the Package directly in Xcode")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
            }
            .animation(.smooth)
            .toolbar {
                if droppedFiles != nil {
                    Button("Clear Selection") {
                        droppedFiles = nil
                    }
                } else {
                    Text("No Selection yet")
                        .foregroundStyle(.gray)
                }
            }
            .onOpenURL { url in
                let (_, files) = handleDroppedFiles([url])
                droppedFiles = files
            }
        }
    }
    func handleDroppedFiles(_ urls: [URL]) -> (Bool, [File]) {
        var droppedFiles: [File] = []
        do {
            print("Starting to Read File")
            for url in urls {
                let file = try readFile(url)
                if file.type == .swift {
                    droppedFiles.append(file)
                } else if file.type == .folder {
                    droppedFiles = [file]
                    return (true, droppedFiles)
                } else {
                    print("Other")
                }
            }
            return (true, droppedFiles)
        } catch {
            print(error.localizedDescription)
            return (false, [])
        }
    }
}



func readFile(_ fileURL: URL) throws -> File {
    guard fileURL.startAccessingSecurityScopedResource() else {
        throw FileError.unableToAccessFile(reason: "Failed to start accessing Security Scoped Resource")
    }
    defer { fileURL.stopAccessingSecurityScopedResource() }

    let name = fileURL.lastPathComponent
    if isFolder(at: fileURL) {
        return File(name: name, data: .folder(folderURL: fileURL), type: .folder)
    } else if isSwiftFile(at: fileURL) {
        let data = try Data(contentsOf: fileURL)
        return File(name: name, data: .swift(data: data), type: .swift)
    } else {
        let data = try Data(contentsOf: fileURL)
        return File(name: name, data: .other(data: data), type: .other)
    }
}


func isFolder(at url: URL) -> Bool {
    var isDirectory: ObjCBool = false
    let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
    return exists && isDirectory.boolValue
}
func isSwiftFile(at url: URL) -> Bool {
    var isDirectory: ObjCBool = false
    let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
    return exists && !isDirectory.boolValue && url.pathExtension.lowercased() == "swift"
}

struct File: Identifiable {
    let id = UUID()
    let name: String
    let data: FileContent
    let type: FileTypes
}

struct Folder: Identifiable {
    let id = UUID()
    let name: String
    let data: URL
    let type: FileTypes = .folder
}

struct SwiftFile: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let data: Data
    let type: FileTypes = .swift
}

enum FileError: Error {
    case unableToAccessFile(reason: String)
}

enum FileTypes {
    case folder
    case swift
    case other
}

enum FileContent {
    case swift(data: Data)
    case folder(folderURL: URL)
    case other(data: Data)
}

extension [File] {
    func fileType() -> FileTypes {
        self.first!.type
    }
    func extractSwiftFiles() -> [SwiftFile] {
        var swiftFiles: [SwiftFile] = []
        for file in self {
            switch file.data {
            case .swift(data: let data):
                swiftFiles.append(
                    SwiftFile(name: file.name, data: data)
                )
            case .folder(folderURL: let folderURL):
                do {
                    for swiftFile in try getSwiftFiles(from: folderURL) {
                        swiftFiles.append(swiftFile)
                    }
                } catch {
                    
                }
            case .other(data: let data):
                print("Irrelevant")
            }
        }
        return swiftFiles
    }
}

func getSwiftFiles(from folderURL: URL) throws -> [SwiftFile] {
    let fileManager = FileManager.default
    let fileURLs = try fileManager.contentsOfDirectory(
        at: folderURL,
        includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles]
    )
    
    var swiftFiles: [SwiftFile] = []
    
    for fileURL in fileURLs {
        if fileURL.pathExtension.lowercased() == "swift" {
            let data = try Data(contentsOf: fileURL)
            let swiftFile = SwiftFile(name: fileURL.lastPathComponent, data: data)
            swiftFiles.append(swiftFile)
        }
    }
    
    return swiftFiles
}

#Preview {
    ContentView()
}
