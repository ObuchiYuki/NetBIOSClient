//
//  File.swift
//  SMBClient
//
//  Created by yuki on 2025/03/09.
//

import Foundation
import Network

final public class Session: Sendable {
    public let connection: NWConnection
    
    public init(_ host: String, port: NWEndpoint.Port) {
        self.connection = NWConnection(host: NWEndpoint.Host(host), port: port, using: .udp)
    }
    
    public func open() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    continuation.resume()
                case .failed(let error):
                    self.connection.cancel()
                    continuation.resume(throwing: error)
                case .waiting(let error):
                    self.connection.cancel()
                    continuation.resume(throwing: error)
                default:
                    break
                }
            }
            self.connection.start(queue: .global(qos: .userInitiated))
        }
    }
    
    public func fetch() async throws -> Response {
        let response = try await fetchData()
        return Response(response: response)
    }
    
    public func cancel() {
        self.connection.cancel()
    }
    
    private func fetchData() async throws -> ResponseDTO {
        try await withCheckedThrowingContinuation { continuation in

            self.connection.stateUpdateHandler = { state in
                switch state {
                case .cancelled:
                    continuation.resume(throwing: NetBIOSError.invalidData)
                case .failed(let error):
                    continuation.resume(throwing: error)
                case .waiting(let error):
                    continuation.resume(throwing: error)
                default: break
                }
            }
            
            let request = RequestDTO()
            let requestData = request.encoded()
            
            self.connection.send(content: requestData, completion: .contentProcessed({ error in
                if let error = error {
                    self.connection.cancel()
                    continuation.resume(throwing: error)
                    return
                }

                self.connection.receiveMessage { data, _, _, error in
                    self.connection.stateUpdateHandler = {_ in }
                    self.connection.cancel()
                    
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let data = data, !data.isEmpty else {
                        continuation.resume(throwing: NetBIOSError.invalidData)
                        return
                    }

                    do {
                        let response = try ResponseDTO(data: data)
                        continuation.resume(returning: response)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }))
        }
    }
}
