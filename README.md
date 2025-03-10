# NetBIOSClient

##### Usage

```swift
let response = try await NetBIOSClient.fetch("192.168.0.10")

// NetBIOSResponse(
//   records: [
//     MY-WINDOWS (type: Workstation, flags: H-node),
//     WORKGROUP (type: Workstation, flags: Group Name, P-node),
//     MY-WINDOWS (type: Server, flags: H-node)
//   ],
//   macAddress: XX:XX:XX:XX:XX:XX
// )
print(response)
```

