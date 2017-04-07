import Vapor
import HTTP
import Core

public protocol ReporterType {
    
    var drop: Droplet { get }
    var config: ConfigurationType { get }
    func report(error: Error, request: Request?) throws
    func report(
        error: Error,
        request: Request?,
        severity: Severity,
        completion: (() -> ())?) throws
}

public enum Severity: String {
    case error, warning, info
    
    init(value: String){
        guard let severity = Severity(rawValue: value) else {
            self = .error
            return
        }
        self = severity
    }
}

public final class Reporter: ReporterType {
    public let drop: Droplet
    public let config: ConfigurationType
    let connectionManager: ConnectionManagerType
    let payloadTransformer: PayloadTransformerType
    
    init(
        drop: Droplet,
        config: ConfigurationType,
        connectionManager: ConnectionManagerType? = nil,
        transformer: PayloadTransformerType? = nil
    ) {
        self.drop = drop
        self.config = config
        self.connectionManager = connectionManager ?? ConnectionManager(
            drop: drop,
            config: config
        )
        self.payloadTransformer = transformer ?? PayloadTransformer(
            drop: drop,
            config: config
        )
    }

    public func report(error: Error, request: Request?) throws {
        try report(error: error, request: request, completion: nil)
    }

    public func report(
        error: Error,
        request: Request?,
        severity: Severity = .error,
        completion complete: (() -> ())?
    ) throws {
        if let error = error as? AbortError {
            guard error.metadata?["report"]?.bool ?? true else {
                return
            }
            try self.report(
                message: error.message,
                metadata: error.metadata,
                request: request,
                severity: severity,
                completion: complete
            )
        } else {
            try self.report(
                message: Status.internalServerError.reasonPhrase,
                metadata: nil,
                request: request,
                severity: severity,
                completion: complete
            )
        }
    }


    // MARK: - Private helpers

    private func report(
        message: String,
        metadata: Node?,
        request: Request?,
        severity: Severity,
        completion complete: (() -> ())? = nil
    ) throws {
        let payload = try payloadTransformer.payloadFor(
            message: message,
            metadata: metadata,
            request: request,
            severity: severity
        )

        // Fire and forget.
        // TODO: Consider queue and retry mechanism.
        try background {
            _ = try? self.connectionManager.submitPayload(payload)
            if let complete = complete { complete() }
        }
    }
}
