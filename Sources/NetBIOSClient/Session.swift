//
//  File.swift
//  SMBClient
//
//  Created by yuki on 2025/03/09.
//

import Foundation
import Network
import os

final public class Session: Sendable {
    public let connection: NWConnection
    
    public init(_ host: String, port: NWEndpoint.Port) {
        self.connection = NWConnection(host: NWEndpoint.Host(host), port: port, using: .udp)
    }
    
    public func open() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let hasResumed = OSAllocatedUnfairLock(initialState: false)
            self.connection.stateUpdateHandler = { state in
                guard !hasResumed.withLock({ $0 }) else { return }
                
                switch state {
                case .ready:
                    hasResumed.withLock { $0 = true }
                    continuation.resume()
                case .failed(let error):
                    self.connection.cancel()
                    hasResumed.withLock { $0 = true }
                    continuation.resume(throwing: error)
                case .waiting(let error):
                    self.connection.cancel()
                    hasResumed.withLock { $0 = true }
                    continuation.resume(throwing: error)
                default:
                    break
                }
            }
            self.connection.start(queue: .global(qos: .userInitiated))
        }
    }
    
    public func fetch() async throws -> Response {
        let response = try await self.fetchData()
        return Response(response: response)
    }
    
    public func cancel() {
        if self.connection.state != .cancelled {
            self.connection.cancel()
        }
    }
    
    private func fetchData() async throws -> ResponseDTO {
        try await withCheckedThrowingContinuation { continuation in
            let hasResumed = OSAllocatedUnfairLock(initialState: false)
            
            self.connection.stateUpdateHandler = { state in
                guard !hasResumed.withLock({ $0 }) else { return }
                
                switch state {
                case .failed(let error):
                    hasResumed.withLock { $0 = true }
                    continuation.resume(throwing: error)
                case .waiting(let error):
                    hasResumed.withLock { $0 = true }
                    continuation.resume(throwing: error)
                case .cancelled:
                    hasResumed.withLock { $0 = true }
                    continuation.resume(throwing: NetBIOSError.cancelled)
                default: break
                }
            }
            
            let request = RequestDTO()
            let requestData = request.encoded()
            
            self.connection.send(content: requestData, completion: .contentProcessed({ error in
                guard !hasResumed.withLock({ $0 }) else { return }
                
                if let error = error {
                    self.connection.cancel()
                    continuation.resume(throwing: error)
                    return
                }
            }))
            
            self.connection.receiveMessage { data, _, _, error in
                guard !hasResumed.withLock({ $0 }) else { return }
                hasResumed.withLock { $0 = true }
                
                if self.connection.state != .cancelled {
                    self.connection.stateUpdateHandler = {_ in }
                    self.connection.cancel()
                }
                
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
        }
    }
}
