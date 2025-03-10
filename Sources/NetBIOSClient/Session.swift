//
//  File.swift
//  SMBClient
//
//  Created by yuki on 2025/03/09.
//

import Foundation
import Network

public enum NetBIOSError: Error {
    case invalidData
}

final public class NetBIOSSession: Sendable {
    public let connection: NWConnection
    
    public init(_ host: String, port: NWEndpoint.Port = 137) {
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
    
    public func fetch() async throws -> NetBIOSResponse {
        let response = try await fetchData()
        return NetBIOSResponse(response: response)
    }
    
    public func cancel() {
        self.connection.cancel()
    }
    
    private func fetchData() async throws -> ResponseNetBIOSDTO {
        try await withCheckedThrowingContinuation { continuation in
            let request = RequestNetBIOSDTO()
            let requestData = request.encoded()
            
            self.connection.send(content: requestData, completion: .contentProcessed({ error in
                if let error = error {
                    self.connection.cancel()
                    continuation.resume(throwing: error)
                    return
                }

                self.connection.receiveMessage { data, _, _, error in
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
                        let response = try ResponseNetBIOSDTO(data: data)
                        continuation.resume(returning: response)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }))
        }
    }
}
