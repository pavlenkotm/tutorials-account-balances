# Package metadata
version       = "0.1.0"
author        = "Web3 Multi-Language Playground"
description   = "High-performance blockchain tools in Nim"
license       = "MIT"
srcDir        = "."
bin           = @["merkle_tree", "rlp"]

# Dependencies
requires "nim >= 1.6.14"
requires "nimcrypto >= 0.6.0"

# Tasks
task bench, "Run performance benchmarks":
  exec "nim c -r -d:release --opt:speed --gc:orc merkle_tree.nim"
  exec "nim c -r -d:release --opt:speed --gc:orc rlp.nim"

task test, "Run tests":
  exec "nim c -r merkle_tree.nim"
  exec "nim c -r rlp.nim"

task clean, "Clean build artifacts":
  exec "rm -f merkle_tree rlp"
  exec "rm -rf nimcache/"
