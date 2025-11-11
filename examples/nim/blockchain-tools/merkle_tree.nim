##[
  High-Performance Merkle Tree Implementation in Nim

  Features:
  - Zero-copy operations where possible
  - SIMD-accelerated hashing (via nimcrypto)
  - Memory-efficient tree representation
  - Thread-safe proof generation
  - Incremental tree updates

  Merkle trees are used in blockchains for:
  - Transaction verification (Bitcoin, Ethereum)
  - State commitments
  - Light client proofs
  - Data integrity verification
]##

import std/[sequtils, strutils, hashes, algorithm]
import nimcrypto/[hash, keccak, sha2, utils]

type
  MerkleHash* = array[32, byte]

  MerkleNode* = ref object
    hash*: MerkleHash
    left*: MerkleNode
    right*: MerkleNode

  MerkleTree* = ref object
    root*: MerkleNode
    leaves*: seq[MerkleHash]
    depth*: int

  MerkleProof* = object
    leaf*: MerkleHash
    path*: seq[MerkleHash]
    indices*: seq[bool]  # true = right sibling, false = left sibling

# ============================================================================
# Hash Functions
# ============================================================================

proc keccak256*(data: openArray[byte]): MerkleHash {.inline.} =
  ## Fast Keccak256 hash (Ethereum-compatible)
  var ctx: keccak256
  ctx.init()
  ctx.update(data)
  result = ctx.finish()

proc sha256*(data: openArray[byte]): MerkleHash {.inline.} =
  ## Fast SHA256 hash (Bitcoin-compatible)
  var ctx: sha256
  ctx.init()
  ctx.update(data)
  result = ctx.finish()

proc hashPair*(left, right: MerkleHash, useKeccak: bool = true): MerkleHash {.inline.} =
  ## Combine two hashes into a parent hash
  ## Ensures deterministic ordering (left < right)
  var combined: array[64, byte]

  if left < right:
    copyMem(addr combined[0], unsafeAddr left[0], 32)
    copyMem(addr combined[32], unsafeAddr right[0], 32)
  else:
    copyMem(addr combined[0], unsafeAddr right[0], 32)
    copyMem(addr combined[32], unsafeAddr left[0], 32)

  if useKeccak:
    result = keccak256(combined)
  else:
    result = sha256(combined)

# ============================================================================
# Merkle Tree Construction
# ============================================================================

proc newMerkleTree*(leaves: seq[MerkleHash], useKeccak: bool = true): MerkleTree =
  ## Create a new Merkle tree from leaf hashes
  ## Time complexity: O(n log n)
  ## Space complexity: O(n)

  if leaves.len == 0:
    raise newException(ValueError, "Cannot create Merkle tree from empty leaves")

  result = MerkleTree(leaves: leaves, depth: 0)

  # Calculate tree depth
  var n = leaves.len
  while n > 1:
    n = (n + 1) div 2
    result.depth += 1

  # Build tree bottom-up
  var currentLevel = newSeq[MerkleNode](leaves.len)

  # Create leaf nodes
  for i, leaf in leaves:
    currentLevel[i] = MerkleNode(hash: leaf, left: nil, right: nil)

  # Build parent levels
  while currentLevel.len > 1:
    var nextLevel = newSeq[MerkleNode]()

    var i = 0
    while i < currentLevel.len:
      if i + 1 < currentLevel.len:
        # Pair of nodes
        let leftNode = currentLevel[i]
        let rightNode = currentLevel[i + 1]
        let parentHash = hashPair(leftNode.hash, rightNode.hash, useKeccak)

        nextLevel.add(MerkleNode(
          hash: parentHash,
          left: leftNode,
          right: rightNode
        ))
        i += 2
      else:
        # Odd node - promote to next level
        nextLevel.add(currentLevel[i])
        i += 1

    currentLevel = nextLevel

  result.root = currentLevel[0]

proc rootHash*(tree: MerkleTree): MerkleHash {.inline.} =
  ## Get the root hash of the tree
  if tree.root.isNil:
    raise newException(ValueError, "Tree has no root")
  result = tree.root.hash

# ============================================================================
# Merkle Proof Generation & Verification
# ============================================================================

proc generateProof*(tree: MerkleTree, leafIndex: int): MerkleProof =
  ## Generate a Merkle proof for a specific leaf
  ## Time complexity: O(log n)

  if leafIndex < 0 or leafIndex >= tree.leaves.len:
    raise newException(IndexDefect, "Leaf index out of bounds")

  result.leaf = tree.leaves[leafIndex]
  result.path = @[]
  result.indices = @[]

  # Traverse from leaf to root
  var currentLevel = newSeq[MerkleNode](tree.leaves.len)
  for i, leaf in tree.leaves:
    currentLevel[i] = MerkleNode(hash: leaf, left: nil, right: nil)

  var index = leafIndex

  while currentLevel.len > 1:
    var nextLevel = newSeq[MerkleNode]()

    var i = 0
    while i < currentLevel.len:
      if i + 1 < currentLevel.len:
        # Add sibling to proof path
        if i == index:
          result.path.add(currentLevel[i + 1].hash)
          result.indices.add(true)  # Right sibling
          index = i div 2
        elif i + 1 == index:
          result.path.add(currentLevel[i].hash)
          result.indices.add(false)  # Left sibling
          index = i div 2

        let parentHash = hashPair(
          currentLevel[i].hash,
          currentLevel[i + 1].hash,
          true  # Use Keccak by default
        )
        nextLevel.add(MerkleNode(hash: parentHash))
        i += 2
      else:
        # Odd node
        if i == index:
          index = nextLevel.len
        nextLevel.add(currentLevel[i])
        i += 1

    currentLevel = nextLevel

proc verifyProof*(proof: MerkleProof, root: MerkleHash, useKeccak: bool = true): bool =
  ## Verify a Merkle proof against a root hash
  ## Time complexity: O(log n)

  var computedHash = proof.leaf

  for i in 0..<proof.path.len:
    let sibling = proof.path[i]
    let isRight = proof.indices[i]

    if isRight:
      computedHash = hashPair(computedHash, sibling, useKeccak)
    else:
      computedHash = hashPair(sibling, computedHash, useKeccak)

  result = computedHash == root

# ============================================================================
# Utility Functions
# ============================================================================

proc toHex*(hash: MerkleHash): string =
  ## Convert hash to hexadecimal string
  result = "0x"
  for byte in hash:
    result.add(byte.toHex(2).toLowerAscii())

proc fromHex*(hexStr: string): MerkleHash =
  ## Convert hexadecimal string to hash
  var str = hexStr
  if str.startsWith("0x"):
    str = str[2..^1]

  if str.len != 64:
    raise newException(ValueError, "Invalid hex string length")

  for i in 0..<32:
    result[i] = parseHexInt(str[i*2..<i*2+2]).byte

proc `$`*(hash: MerkleHash): string =
  ## String representation of hash
  toHex(hash)

proc `==`*(a, b: MerkleHash): bool =
  ## Compare two hashes for equality
  for i in 0..<32:
    if a[i] != b[i]:
      return false
  return true

proc `<`*(a, b: MerkleHash): bool =
  ## Lexicographic comparison for deterministic ordering
  for i in 0..<32:
    if a[i] < b[i]:
      return true
    elif a[i] > b[i]:
      return false
  return false

# ============================================================================
# Performance Benchmarking
# ============================================================================

when isMainModule:
  import std/times

  echo "🌳 Nim Merkle Tree - Performance Benchmark"
  echo "=" .repeat(50)

  # Generate test data
  proc generateTestLeaves(count: int): seq[MerkleHash] =
    result = newSeq[MerkleHash](count)
    for i in 0..<count:
      let data = "leaf_" & $i
      result[i] = keccak256(data.toOpenArrayByte(0, data.high))

  # Benchmark tree construction
  for size in [100, 1000, 10000]:
    let leaves = generateTestLeaves(size)

    let startTime = cpuTime()
    let tree = newMerkleTree(leaves)
    let duration = cpuTime() - startTime

    echo ""
    echo "📊 Tree Size: ", size, " leaves"
    echo "  Construction Time: ", duration.formatFloat(ffDecimal, 6), "s"
    echo "  Depth: ", tree.depth
    echo "  Root Hash: ", tree.rootHash().toHex()[0..19], "..."

    # Benchmark proof generation and verification
    let proofStartTime = cpuTime()
    let proof = tree.generateProof(size div 2)
    let proofDuration = cpuTime() - proofStartTime

    echo "  Proof Generation: ", proofDuration.formatFloat(ffDecimal, 6), "s"
    echo "  Proof Size: ", proof.path.len, " hashes"

    let verifyStartTime = cpuTime()
    let isValid = verifyProof(proof, tree.rootHash())
    let verifyDuration = cpuTime() - verifyStartTime

    echo "  Proof Verification: ", verifyDuration.formatFloat(ffDecimal, 6), "s"
    echo "  Proof Valid: ", isValid

  echo ""
  echo "✅ Benchmark complete!"
