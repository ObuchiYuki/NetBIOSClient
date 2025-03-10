//
//  File.swift
//  NetBIOSClient
//
//  Created by yuki on 2025/03/10.
//

import Foundation
import Network

public enum NetBIOSError: Error {
    case invalidData
    case timeout
}

final public class NetBIOSClient {
    public static func fetch(_ host: String, port: NWEndpoint.Port = 137, timeout: TimeInterval = 0.05) async throws -> Response {
        try await withThrowingTaskGroup(of: Response.self) { group in
            let session = Session(host, port: port)
            
            group.addTask {
                try await session.open()
                return try await session.fetch()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                session.cancel()
                throw NetBIOSError.timeout
            }
            
            defer {
                group.cancelAll()
            }
            
            guard let result = try await group.next() else {
                throw CancellationError()
            }
            return result
        }
    }
}
