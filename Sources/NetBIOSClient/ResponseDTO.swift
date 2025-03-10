//
//  NetBIOSResponse.swift
//  NetBIOSClient
//
//  Created by yuki on 2025/03/10.
//

import Foundation

struct ResponseDTO {
    struct Record {
        let name: String
        let suffix: UInt8
        let flags: UInt16
    }

    let transactionID: UInt16
    let flags: UInt16
    let questionCount: UInt16
    let answerCount: UInt16
    let authorityCount: UInt16
    let additionalCount: UInt16

    let nameRecords: [Record]
    let macAddress: String

    init(data: Data) throws {
        let reader = ByteReader(data)

        self.transactionID = reader.readUInt16BE()
        self.flags = reader.readUInt16BE()
        self.questionCount = reader.readUInt16BE()
        self.answerCount = reader.readUInt16BE()
        self.authorityCount = reader.readUInt16BE()
        self.additionalCount = reader.readUInt16BE()

        for _ in 0..<self.questionCount {
            Self.skipNetBIOSName(reader)
            _ = reader.readUInt16BE()
            _ = reader.readUInt16BE()
        }

        var tmpRecords: [Record] = []
        var tmpMac = ""

        for _ in 0..<self.answerCount {
            Self.skipNetBIOSName(reader)

            let rtype = reader.readUInt16BE()
            _ = reader.readUInt16BE()
            _ = reader.readUInt32BE()
            let rdlength = reader.readUInt16BE()

            if rtype == 0x21 {
                let rdata = reader.read(count: Int(rdlength))
                let rdataReader = ByteReader(rdata)

                let numberOfNames = rdataReader.readUInt8()

                var entries: [Record] = []
                for _ in 0..<numberOfNames {
                    let rawName = rdataReader.read(count: 15)
                    let suffix = rdataReader.readUInt8()
                    let flags = rdataReader.readUInt16BE()

                    let nameString = Self.parseNetBIOSRawName(rawName)
                    entries.append(Record(name: nameString, suffix: suffix, flags: flags))
                }

                let macData = rdataReader.read(count: 6)
                tmpMac = macData.map { String(format: "%02X", $0) }.joined(separator: ":")

                tmpRecords.append(contentsOf: entries)
            } else {
                _ = reader.read(count: Int(rdlength))
            }
        }

        self.nameRecords = tmpRecords
        self.macAddress = tmpMac
    }

    private static func skipNetBIOSName(_ reader: ByteReader) {
        while true {
            let length = reader.readUInt8()
            if length == 0 { break }
            if (length & 0xC0) == 0xC0 {
                _ = reader.readUInt8()
                break
            } else {
                _ = reader.read(count: Int(length))
            }
        }
    }
    
    private static func parseNetBIOSRawName(_ data: Data) -> String {
        var bytes = [UInt8](data)
        if let idx = bytes.firstIndex(of: 0x00) {
            bytes.removeSubrange(idx..<bytes.count)
        }
        return String(bytes: bytes, encoding: .ascii)?
            .trimmingCharacters(in: .whitespaces) ?? ""
    }
}
