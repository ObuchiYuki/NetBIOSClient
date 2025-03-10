//
//  Response.swift
//  NetBIOSClient
//
//  Created by yuki on 2025/03/10.
//


public struct NetBIOSResponse: Sendable {
    public let records: [Record]
    public let macAddress: String

    public struct Record: Sendable {
        public let name: String
        public let suffix: Suffix
        public let flags: Flags

        public enum Suffix: Equatable, Sendable {
            case workstation
            case server
            case messenger
            case domainMasterBrowser
            case domainController
            case unknown(UInt8)

            init(rawValue: UInt8) {
                switch rawValue {
                case 0x00: self = .workstation
                case 0x20: self = .server
                case 0x03: self = .messenger
                case 0x1B: self = .domainMasterBrowser
                case 0x1C: self = .domainController
                default: self = .unknown(rawValue)
                }
            }
        }

        public struct Flags: OptionSet, Sendable {
            public let rawValue: UInt16
            
            public init(rawValue: UInt16) {
                self.rawValue = rawValue
            }

            static let groupName  = Flags(rawValue: 1 << 15)
            static let conflict   = Flags(rawValue: 1 << 13)
            static let deregister = Flags(rawValue: 1 << 12)

            public var nodeType: NodeType {
                switch (rawValue & 0x0C00) >> 10 {
                case 0b00: return .b
                case 0b01: return .p
                case 0b10: return .m
                case 0b11: return .h
                default:   return .b
                }
            }

            public enum NodeType: String {
                case b = "B-node"
                case p = "P-node"
                case m = "M-node"
                case h = "H-node"
            }
        }

        init(name: String, rawSuffix: UInt8, rawFlags: UInt16) {
            self.name = name
            self.suffix = Suffix(rawValue: rawSuffix)
            self.flags = Flags(rawValue: rawFlags)
        }
    }
    
    init(response: ResponseNetBIOSDTO) {
        self.macAddress = response.macAddress
        self.records = response.nameRecords.map { record in
            Record(name: record.name, rawSuffix: record.suffix, rawFlags: record.flags)
        }
    }
}

extension NetBIOSResponse.Record.Suffix: CustomStringConvertible {
    public var description: String {
        switch self {
        case .workstation: return "Workstation"
        case .server: return "Server"
        case .messenger: return "Messenger"
        case .domainMasterBrowser: return "Domain Master Browser"
        case .domainController: return "Domain Controller"
        case .unknown(let value): return "Unknown(\(value))"
        }
    }
}

extension NetBIOSResponse.Record.Flags: CustomStringConvertible {
    public var description: String {
        var flags: [String] = []
        if self.contains(.groupName) { flags.append("Group Name") }
        if self.contains(.conflict) { flags.append("Conflict") }
        if self.contains(.deregister) { flags.append("Deregister") }
        flags.append(self.nodeType.rawValue)
        return flags.joined(separator: ", ")
    }
}

extension NetBIOSResponse.Record.Flags.NodeType: CustomStringConvertible {
    public var description: String {
        self.rawValue
    }
}

extension NetBIOSResponse.Record: CustomStringConvertible {
    public var description: String {
        "\(self.name) (type: \(self.suffix), flags: \(self.flags))"
    }
}

extension NetBIOSResponse: CustomStringConvertible {
    public var description: String {
        "NetBIOSResponse(records: \(self.records), macAddress: \(self.macAddress))"
    }
}
