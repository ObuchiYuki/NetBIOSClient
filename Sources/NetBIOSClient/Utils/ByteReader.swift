//
//  ByteReader.swift
//  NetBIOSClient
//
//  Created by yuki on 2025/03/10.
//

import Foundation

final class ByteReader {
    private let data: Data
    private(set) var offset: Data.Index

    var availableBytes: Int { self.data.count - self.offset }

    init(_ data: Data) {
        self.data = data
        self.offset = data.startIndex
    }

    func readUInt8() -> UInt8 {
        let value = self.data[self.offset]
        self.offset += 1
        return value
    }

    func readUInt16BE() -> UInt16 {
        let b0 = self.readUInt8()
        let b1 = self.readUInt8()
        return (UInt16(b0) << 8) | UInt16(b1)
    }

    func readUInt32BE() -> UInt32 {
        let b0 = self.readUInt8()
        let b1 = self.readUInt8()
        let b2 = self.readUInt8()
        let b3 = self.readUInt8()
        return (UInt32(b0) << 24)
             | (UInt32(b1) << 16)
             | (UInt32(b2) <<  8)
             |  UInt32(b3)
    }

    /// 任意の個数のバイト列を Data で返す
    func read(count: Int) -> Data {
        let end = self.offset + count
        let sub = self.data[self.offset..<end]
        self.offset += count
        return Data(sub)
    }

    func read(from: Int, count: Int) -> Data {
        self.seek(to: self.data.startIndex + from)
        return self.read(count: count)
    }

    func seek(to: Int) {
        self.offset = self.data.startIndex + to
    }

    func remaining() -> Data {
        return Data(self.data[self.offset...])
    }
}
