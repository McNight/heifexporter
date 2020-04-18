import Foundation

fileprivate let fileManager = FileManager.default

enum Asset: String {

    enum Error: Swift.Error {
        case invalidEnumerator
        case noAssetsFound
    }

    case xcassets
    case imageset
    case launchimage
    case images

    private func match(fileAt url: NSURL) -> Bool {
        let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .typeIdentifierKey]
        guard let resourceValues = try? url.resourceValues(forKeys: resourceKeys) else {
            return false
        }
        switch self {
        case .xcassets, .imageset, .launchimage:
            return (resourceValues[.isDirectoryKey] as? Bool) == true && url.pathExtension == pathExtension
        case .images:
            guard let uti = resourceValues[.typeIdentifierKey] as? NSString else {
                return false
            }
            return UTTypeConformsTo(uti, kUTTypeImage)
        }
    }

    var pathExtension: String {
        return rawValue
    }

    static func retrieve(asset: Asset, at url: URL) throws -> [URL] {
        let resourceKeys: [URLResourceKey] = [.isDirectoryKey]

        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: resourceKeys) else {
            throw Error.invalidEnumerator
        }

        var fileURLs: [URL] = []
        for case let fileURL as NSURL in enumerator where asset.match(fileAt: fileURL) {
            fileURLs.append(fileURL as URL)
        }

        guard !fileURLs.isEmpty else {
            throw Error.noAssetsFound
        }

        return fileURLs
    }

}
