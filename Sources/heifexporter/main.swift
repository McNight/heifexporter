import Foundation
import ArgumentParser

struct RuntimeError: Error, CustomStringConvertible {
    var description: String

    init(_ description: String) {
        self.description = description
    }
}

private let queue: OperationQueue = {
    let queue = OperationQueue()
    queue.name = "heifexporter_queue"
    queue.qualityOfService = .userInitiated
    return queue
}()

private var successCount: Int = 0

struct Heifconverter: ParsableCommand {

    static var configuration = CommandConfiguration(
        commandName: "heifconverter",
        abstract: "Convert image sets within Xcode assets catalogs to HEIF ressources",
        version: "0.0.1")

    @Argument(help: "The path of the Xcode project containing images ressources to be converted")
    var projectPath: String

    func run() throws {
        if #available(macOS 10.13.4, *) {
            let xcAssets = try Asset.retrieve(asset: .xcassets, at: URL(fileURLWithPath: projectPath))
            let imageAssets = try xcAssets.flatMap { try Asset.retrieve(asset: .imageset, at: $0) }

            for assetURL in imageAssets {
                do {
                    let images = try Asset.retrieve(asset: .images, at: assetURL)
                    for imageURL in images {
                        let convert = convertOperation(for: imageURL)
                        let replace = replaceOperation(for: imageURL, within: assetURL)
                        replace.addDependency(convert)
                        queue.addOperation(convert)
                        queue.addOperation(replace)
                    }
                } catch Asset.Error.noAssetsFound {
                    continue
                }

                queue.waitUntilAllOperationsAreFinished()
            }

            if successCount > 0 {
                throw CleanExit.message("Successfully converted and replaced \(successCount) ressources")
            } else {
                throw RuntimeError("No assets have been found at this path.")
            }
        } else {
            throw RuntimeError("You need at least macOS 10.13.4 to run this tool.")
        }
    }

    private func convertOperation(for url: URL) -> ConvertOperation {
        return ConvertOperation(resourceURL: url)
    }

    private func replaceOperation(for url: URL, within asset: URL) -> ReplaceOperation {
        let replace = ReplaceOperation(assetURL: asset, imageURL: url)
        replace.resultHandler = { result in
            if case .success = result {
                successCount += 1
            }
        }
        return replace
    }

}

Heifconverter.main()
