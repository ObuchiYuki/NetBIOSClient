//
//  NetBIOSRequest.swift
//  NetBIOSClient
//
//  Created by yuki on 2025/03/10.
//

import Foundation

struct RequestNetBIOSDTO {
    let transactionID: UInt16 = .random(in: 0..<UInt16.max)
    let flags: UInt16 = 0x0000
    let questions: UInt16 = 1

    let answerRR: UInt16 = 0
    let authorityRR: UInt16 = 0
    let additionalRR: UInt16 = 0

    let questionType: UInt16 = 0x21
    let questionClass: UInt16 = 0x01

    func encoded() -> Data {
        var data = Data()

        data += self.transactionID.bigEndian
        data += self.flags.bigEndian
        data += self.questions.bigEndian
        data += self.answerRR.bigEndian
        data += self.authorityRR.bigEndian
        data += self.additionalRR.bigEndian

        let nameBytes = [UInt8(0x2A)] + Array<UInt8>(repeating: 0x00, count: 15)
        let encodedName = self.encodeNetBIOSName(nameBytes)

        data += UInt8(encodedName.count)
        data += encodedName
        data += UInt8(0x00)

        data += self.questionType.bigEndian
        data += self.questionClass.bigEndian

        return data
    }

    private func encodeNetBIOSName(_ nameBytes: [UInt8]) -> [UInt8] {
        var result = [UInt8]()
        for b in nameBytes {
            let hi = (b >> 4) & 0x0F
            let lo = b & 0x0F
            result.append(0x41 + hi)
            result.append(0x41 + lo)
        }
        return result
    }
}

