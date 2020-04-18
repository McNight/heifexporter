import Foundation

enum OperationError: Error {
    case unavailable
}

class GenericOperation: Operation {

    typealias ResultHandler = (Result<Data, Error>) -> Void

    private struct K {
        static let isExecutingKey: String = "isExecuting"
        static let isFinishedKey: String = "isFinished"
    }

    enum State {
        case ready
        case executing
        case finished
    }

    var resultHandler: ResultHandler?

    var state: State = .ready {
        willSet {
            willChangeValue(forKey: K.isExecutingKey)
            willChangeValue(forKey: K.isFinishedKey)
        }

        didSet {
            didChangeValue(forKey: K.isExecutingKey)
            didChangeValue(forKey: K.isFinishedKey)
        }
    }

    override var isReady: Bool {
        return state == .ready
    }

    override var isExecuting: Bool {
        return state == .executing
    }

    override var isFinished: Bool {
        return state == .finished
    }

    override func start() {
        fatalError("You should subclass me.")
    }

    func prologue() {
        guard !isCancelled else {
            state = .finished
            return
        }

        state = .executing
    }

    func epilogue() {
        state = .finished
    }

}

final class ConvertOperation: GenericOperation {

    private let resourceURL: URL

    init(resourceURL: URL) {
        self.resourceURL = resourceURL
        super.init()
    }

    override func start() {
        prologue()
        defer {
            epilogue()
        }

        if #available(macOS 10.13.4, *) {
            Sips.execute(action: .convert(resourceURL)) { result in
                self.resultHandler?(result)
            }
        } else {
            resultHandler?(.failure(OperationError.unavailable))
        }
    }

}

final class ReplaceOperation: GenericOperation {

    private enum K {
        static let substitutionExtension: String = "heic"
        static let sourceFileExtension: String = "json"
        static let sourceFileName: String = "Contents"
    }

    private let assetURL: URL
    private let imageURL: URL

    init(assetURL: URL, imageURL: URL) {
        self.assetURL = assetURL
        self.imageURL = imageURL
        super.init()
    }

    override func start() {
        prologue()
        defer {
            epilogue()
        }

        if #available(macOS 10.13.4, *) {
            let replacing = imageURL.lastPathComponent
            let substitution =
                imageURL.deletingPathExtension().appendingPathExtension(K.substitutionExtension).lastPathComponent
            let jsonURL =
                assetURL.appendingPathComponent(K.sourceFileName).appendingPathExtension(K.sourceFileExtension)

            Sed.execute(
                action: .replace(
                    replacing: replacing,
                    substitution: substitution,
                    url: jsonURL
                )
            ) { result in
                self.resultHandler?(result)
            }
        } else {
            resultHandler?(.failure(OperationError.unavailable))
        }
    }

}
