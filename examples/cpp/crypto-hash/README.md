# Ethereum Cryptography Utilities (C++)

High-performance cryptographic utilities for Ethereum operations implemented in C++ using OpenSSL.

## Features

- ✅ Keccak256 hashing (Ethereum-compatible)
- ✅ EIP-55 address checksumming
- ✅ Hex encoding/decoding
- ✅ Address validation
- ✅ Wei/Ether conversion
- ✅ Public key to address derivation

## Tech Stack

- **C++17**: Modern C++ standard
- **OpenSSL**: Cryptographic library
- **CMake**: Build system

## Why C++ for Blockchain?

- **Performance**: Native code, optimal speed
- **Low-level Control**: Direct memory management
- **Crypto Libraries**: Mature OpenSSL integration
- **Cross-platform**: Works on all major platforms
- **Bitcoin/Ethereum Core**: Written in C++

## Setup

### Prerequisites

```bash
# Ubuntu/Debian
sudo apt-get install build-essential cmake libssl-dev

# macOS
brew install cmake openssl

# Windows (using vcpkg)
vcpkg install openssl
```

### Build

```bash
mkdir build && cd build
cmake ..
make
```

### Run

```bash
./keccak256
```

## Usage

### Hash a Message

```cpp
Keccak256 hasher;
std::string hash = hasher.hash("Hello, Ethereum!");
std::cout << hash << std::endl;
// Output: 0x...
```

### Checksum Address (EIP-55)

```cpp
std::string address = "0x5aaeb6053f3e94c9b9a09f33669435e7ef1beaed";
std::string checksummed = Keccak256::toChecksumAddress(address);
// Output: 0x5aAeb6053f3E94C9b9A09f33669435E7Ef1BeAed
```

### Validate Address

```cpp
bool valid = EthereumUtils::isValidAddress("0x742d35...");
```

## License

MIT
