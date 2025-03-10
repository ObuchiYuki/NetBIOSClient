import Testing
import Foundation
@testable import NetBIOSClient

@Test func example() async throws {
    let response = try await NetBIOSClient.fetch("192.168.0.100")
    
    // NetBIOSResponse(
    //   records: [
    //     YUKI-WINDOWS (type: Workstation, flags: H-node),
    //     WORKGROUP (type: Workstation, flags: Group Name, P-node),
    //     YUKI-WINDOWS (type: Server, flags: H-node)
    //   ],
    //   macAddress: A8:A1:59:F5:A5:61
    // )
    print(response)
}
