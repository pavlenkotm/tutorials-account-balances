# WASM Crypto (Zig)

High-performance cryptographic functions compiled to WebAssembly.

## Features

- ✅ Keccak256 hashing
- ✅ WASM compilation
- ✅ Zero-cost abstractions
- ✅ Memory safe

## Build

```bash
zig build-lib crypto.zig -target wasm32-freestanding -dynamic
```

## Why Zig?

- **Performance**: C-like speed
- **Safety**: No undefined behavior
- **WASM**: First-class support
- **Simple**: Easy to learn

## License

MIT
