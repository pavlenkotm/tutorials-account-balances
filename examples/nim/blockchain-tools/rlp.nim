##[
  High-Performance RLP (Recursive Length Prefix) Encoder/Decoder

  RLP is the serialization format used by Ethereum for:
  - Transaction encoding
  - Block headers
  - State trie nodes
  - Network protocol messages

  This implementation focuses on:
  - Zero-copy decoding where possible
  - Minimal allocations
  - Type-safe encoding/decoding
  - Performance optimization for hot paths
]##

import std/[strutils, sequtils]

type
  RlpNodeKind* = enum
    rlpBlob   ## Raw byte data
    rlpList   ## List of RLP items

  RlpNode* = ref object
    case kind*: RlpNodeKind
    of rlpBlob:
      bytes*: seq[byte]
    of rlpList:
      items*: seq[RlpNode]

  RlpError* = object of CatchableError

# ============================================================================
# RLP Encoding
# ============================================================================

proc encodeLength*(length: int, offset: int): seq[byte] =
  ## Encode length prefix for RLP
  if length < 56:
    result = @[(offset + length).byte]
  else:
    var lengthBytes = newSeq[byte]()
    var len = length

    while len > 0:
      lengthBytes.insert((len and 0xFF).byte, 0)
      len = len shr 8

    result = @[(offset + 55 + lengthBytes.len).byte]
    result.add(lengthBytes)

proc encodeBytes*(data: openArray[byte]): seq[byte] =
  ## Encode byte array to RLP format

  if data.len == 0:
    # Empty string
    result = @[0x80'u8]

  elif data.len == 1 and data[0] < 0x80:
    # Single byte < 128
    result = @[data[0]]

  elif data.len < 56:
    # Short string (0-55 bytes)
    result = @[(0x80 + data.len).byte]
    result.add(data)

  else:
    # Long string (56+ bytes)
    result = encodeLength(data.len, 0x80)
    result.add(data)

proc encodeString*(s: string): seq[byte] {.inline.} =
  ## Encode string to RLP
  encodeBytes(s.toOpenArrayByte(0, s.high))

proc encodeInt*(n: int): seq[byte] =
  ## Encode integer to RLP
  if n == 0:
    return @[0x80'u8]

  var bytes = newSeq[byte]()
  var num = n

  while num > 0:
    bytes.insert((num and 0xFF).byte, 0)
    num = num shr 8

  result = encodeBytes(bytes)

proc encodeList*(items: openArray[seq[byte]]): seq[byte] =
  ## Encode list of RLP items

  # Concatenate all items
  var payload = newSeq[byte]()
  for item in items:
    payload.add(item)

  if payload.len < 56:
    # Short list
    result = @[(0xc0 + payload.len).byte]
    result.add(payload)
  else:
    # Long list
    result = encodeLength(payload.len, 0xc0)
    result.add(payload)

proc encode*(node: RlpNode): seq[byte] =
  ## Encode RlpNode to bytes
  case node.kind
  of rlpBlob:
    result = encodeBytes(node.bytes)
  of rlpList:
    var encodedItems = newSeq[seq[byte]]()
    for item in node.items:
      encodedItems.add(encode(item))
    result = encodeList(encodedItems)

# ============================================================================
# RLP Decoding
# ============================================================================

proc decodeLength*(data: openArray[byte], offset: var int): (int, int) =
  ## Decode length prefix
  ## Returns (length, headerSize)

  if offset >= data.len:
    raise newException(RlpError, "Insufficient data for length decoding")

  let prefix = data[offset]

  if prefix < 0x80:
    # Single byte
    return (1, 0)

  elif prefix <= 0xb7:
    # Short string
    let length = prefix.int - 0x80
    offset += 1
    return (length, 1)

  elif prefix <= 0xbf:
    # Long string
    let lengthSize = prefix.int - 0xb7
    if offset + lengthSize >= data.len:
      raise newException(RlpError, "Invalid long string length")

    var length = 0
    for i in 1..lengthSize:
      length = (length shl 8) or data[offset + i].int

    offset += lengthSize + 1
    return (length, lengthSize + 1)

  elif prefix <= 0xf7:
    # Short list
    let length = prefix.int - 0xc0
    offset += 1
    return (length, 1)

  else:
    # Long list
    let lengthSize = prefix.int - 0xf7
    if offset + lengthSize >= data.len:
      raise newException(RlpError, "Invalid long list length")

    var length = 0
    for i in 1..lengthSize:
      length = (length shl 8) or data[offset + i].int

    offset += lengthSize + 1
    return (length, lengthSize + 1)

proc decode*(data: openArray[byte]): RlpNode =
  ## Decode RLP bytes to RlpNode

  if data.len == 0:
    raise newException(RlpError, "Cannot decode empty data")

  var offset = 0
  let prefix = data[0]

  if prefix < 0x80:
    # Single byte
    return RlpNode(kind: rlpBlob, bytes: @[prefix])

  elif prefix <= 0xbf:
    # String (short or long)
    let (length, headerSize) = decodeLength(data, offset)

    if offset + length > data.len:
      raise newException(RlpError, "Invalid string length")

    var bytes = newSeq[byte](length)
    if length > 0:
      copyMem(addr bytes[0], unsafeAddr data[offset], length)

    return RlpNode(kind: rlpBlob, bytes: bytes)

  else:
    # List (short or long)
    let (length, headerSize) = decodeLength(data, offset)

    if offset + length > data.len:
      raise newException(RlpError, "Invalid list length")

    var items = newSeq[RlpNode]()
    let endPos = offset + length

    while offset < endPos:
      let itemStart = offset
      let itemNode = decode(data[itemStart..<endPos])

      # Calculate item size
      var tempOffset = itemStart
      let (itemLength, itemHeaderSize) = decodeLength(data, tempOffset)
      offset = tempOffset + itemLength

      items.add(itemNode)

    return RlpNode(kind: rlpList, items: items)

# ============================================================================
# Utility Functions
# ============================================================================

proc toHex*(data: openArray[byte]): string =
  ## Convert bytes to hex string
  result = "0x"
  for b in data:
    result.add(b.toHex(2).toLowerAscii())

proc fromHex*(s: string): seq[byte] =
  ## Convert hex string to bytes
  var str = s
  if str.startsWith("0x"):
    str = str[2..^1]

  if str.len mod 2 != 0:
    raise newException(ValueError, "Invalid hex string length")

  result = newSeq[byte](str.len div 2)
  for i in 0..<result.len:
    result[i] = parseHexInt(str[i*2..<i*2+2]).byte

proc `$`*(node: RlpNode): string =
  ## String representation of RlpNode
  case node.kind
  of rlpBlob:
    if node.bytes.len < 32:
      result = "Blob(" & node.bytes.toHex() & ")"
    else:
      result = "Blob(" & $node.bytes.len & " bytes)"
  of rlpList:
    result = "List["
    for i, item in node.items:
      if i > 0:
        result.add(", ")
      result.add($item)
    result.add("]")

# ============================================================================
# High-Level API for Common Types
# ============================================================================

proc encodeTransaction*(
  nonce: int,
  gasPrice: int,
  gasLimit: int,
  to: string,
  value: int,
  data: seq[byte]
): seq[byte] =
  ## Encode Ethereum transaction (legacy format)
  let fields = [
    encodeInt(nonce),
    encodeInt(gasPrice),
    encodeInt(gasLimit),
    encodeBytes(fromHex(to)),
    encodeInt(value),
    encodeBytes(data)
  ]
  result = encodeList(fields)

proc encodeBlockHeader*(
  parentHash: string,
  stateRoot: string,
  transactionsRoot: string,
  receiptsRoot: string,
  number: int,
  gasLimit: int,
  gasUsed: int,
  timestamp: int
): seq[byte] =
  ## Encode Ethereum block header (simplified)
  let fields = [
    encodeBytes(fromHex(parentHash)),
    encodeBytes(fromHex(stateRoot)),
    encodeBytes(fromHex(transactionsRoot)),
    encodeBytes(fromHex(receiptsRoot)),
    encodeInt(number),
    encodeInt(gasLimit),
    encodeInt(gasUsed),
    encodeInt(timestamp)
  ]
  result = encodeList(fields)

# ============================================================================
# Benchmarks and Examples
# ============================================================================

when isMainModule:
  import std/times

  echo "⚡ Nim RLP Encoder/Decoder - Performance Tests"
  echo "=" .repeat(50)

  # Test 1: String encoding/decoding
  echo "\n📝 Test 1: String Encoding"
  let testStr = "Hello, Ethereum!"
  let encoded = encodeString(testStr)
  echo "  Original: ", testStr
  echo "  Encoded: ", encoded.toHex()
  echo "  Size: ", encoded.len, " bytes"

  let decoded = decode(encoded)
  echo "  Decoded: ", decoded

  # Test 2: Integer encoding
  echo "\n🔢 Test 2: Integer Encoding"
  for num in [0, 127, 128, 255, 256, 1024, 65535]:
    let enc = encodeInt(num)
    echo "  ", num, " => ", enc.toHex()

  # Test 3: List encoding
  echo "\n📋 Test 3: List Encoding"
  let listItems = [
    encodeString("cat"),
    encodeString("dog"),
    encodeString("bird")
  ]
  let encodedList = encodeList(listItems)
  echo "  Encoded list: ", encodedList.toHex()

  let decodedList = decode(encodedList)
  echo "  Decoded: ", decodedList

  # Test 4: Transaction encoding
  echo "\n💸 Test 4: Transaction Encoding"
  let tx = encodeTransaction(
    nonce = 9,
    gasPrice = 20_000_000_000,  # 20 Gwei
    gasLimit = 21000,
    to = "0x3535353535353535353535353535353535353535",
    value = 1_000_000_000_000_000_000,  # 1 ETH
    data = @[]
  )
  echo "  Transaction RLP: ", tx.toHex()
  echo "  Size: ", tx.len, " bytes"

  # Performance benchmark
  echo "\n⚡ Performance Benchmark"
  echo "-" .repeat(50)

  let iterations = 100_000

  # Benchmark encoding
  let encodeStart = cpuTime()
  for i in 0..<iterations:
    discard encodeString("benchmark_test_string_" & $i)
  let encodeDuration = cpuTime() - encodeStart

  echo "  String encoding: ", iterations, " iterations"
  echo "  Time: ", encodeDuration.formatFloat(ffDecimal, 6), "s"
  echo "  Rate: ", (iterations.float / encodeDuration).formatFloat(ffDecimal, 0), " ops/s"

  # Benchmark decoding
  let testEncoded = encodeString("benchmark_test_string")
  let decodeStart = cpuTime()
  for i in 0..<iterations:
    discard decode(testEncoded)
  let decodeDuration = cpuTime() - decodeStart

  echo "\n  String decoding: ", iterations, " iterations"
  echo "  Time: ", decodeDuration.formatFloat(ffDecimal, 6), "s"
  echo "  Rate: ", (iterations.float / decodeDuration).formatFloat(ffDecimal, 0), " ops/s"

  echo "\n✅ All tests completed!"
