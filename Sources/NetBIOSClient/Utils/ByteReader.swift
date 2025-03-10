final class ByteReader {
    private let data: Data
    private(set) var offset: Data.Index

    var availableBytes: Int {
        return data.count - offset
    }

    init(_ data: Data) {
        self.data = data
        offset = data.startIndex
    }

    /// 1バイトを読み込む（アラインメントを気にしなくて済む）
    func readUInt8() -> UInt8 {
        let value = data[offset]
        offset += 1
        return value
    }

    /// 2バイト(ビッグエンディアン)を手動で読み込む
    func readUInt16BE() -> UInt16 {
        let b0 = readUInt8()
        let b1 = readUInt8()
        return (UInt16(b0) << 8) | UInt16(b1)
    }

    /// 4バイト(ビッグエンディアン)を手動で読み込む
    func readUInt32BE() -> UInt32 {
        let b0 = readUInt8()
        let b1 = readUInt8()
        let b2 = readUInt8()
        let b3 = readUInt8()
        return (UInt32(b0) << 24)
             | (UInt32(b1) << 16)
             | (UInt32(b2) <<  8)
             |  UInt32(b3)
    }

    /// 任意の個数のバイト列を Data で返す
    func read(count: Int) -> Data {
        let end = offset + count
        let sub = data[offset..<end]
        offset += count
        return Data(sub)
    }

    func read(from: Int, count: Int) -> Data {
        seek(to: data.startIndex + from)
        return read(count: count)
    }

    func seek(to: Int) {
        offset = data.startIndex + to
    }

    func remaining() -> Data {
        return Data(data[offset...])
    }
}