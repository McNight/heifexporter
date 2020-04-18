import Foundation

typealias CompletionHandler = (Result<Data, Error>) -> Void

protocol Command {
    static var launchPath: String { get }
}

enum Runnable {

    @available (macOS 10.13.4, *)
    static func run(launchPath: String, arguments: [String], completionHandler: CompletionHandler? = nil) {
        let task = Process()
        task.launchPath = launchPath
        task.arguments = arguments

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            completionHandler?(.success(data))
        } catch let error {
            completionHandler?(.failure(error))
        }
    }

}

enum Sips: Command {

    static var launchPath: String {
        return "/usr/bin/sips"
    }

    enum Action {
        case convert(URL)

        var arguments: [String] {
            return [
                "-s", "format", "heic",
                "-s", "formatOptions", "100",
                url.path,
                "--out", "\(url.deletingPathExtension().appendingPathExtension("heic").path)"
            ]
        }

        private var url: URL {
            switch self {
            case .convert(let url): return url
            }
        }
    }

    @available (macOS 10.13.4, *)
    static func execute(action: Action, completionHandler: CompletionHandler? = nil) {
        Runnable.run(launchPath: Self.launchPath, arguments: action.arguments, completionHandler: completionHandler)
    }

}

enum Sed: Command {

    static var launchPath: String {
        return "/usr/bin/sed"
    }

    enum Action {
        case replace(replacing: String, substitution: String, url: URL)

        var arguments: [String] {
            return [
                "-i",
                "",
                "-e",
                "s/\(replacing)/\(substitution)/g",
                url.path
            ]
        }

        var replacing: String {
            switch self {
            case .replace(let replacing, _, _): return replacing
            }
        }

        var substitution: String {
            switch self {
            case .replace(_, let substitution, _): return substitution
            }
        }

        var url: URL {
            switch self {
            case .replace(_, _, let url): return url
            }
        }
    }

    @available (macOS 10.13.4, *)
    static func execute(action: Action, completionHandler: CompletionHandler? = nil) {
        Runnable.run(launchPath: Self.launchPath, arguments: action.arguments, completionHandler: completionHandler)
    }

}
