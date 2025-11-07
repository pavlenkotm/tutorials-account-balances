#include <iostream>
#include <string>
#include <vector>
#include <iomanip>
#include <sstream>
#include <openssl/evp.h>
#include <openssl/sha.h>

/**
 * Keccak256 Hash Implementation for Ethereum
 *
 * Demonstrates C++ cryptographic operations compatible with Ethereum
 */

class Keccak256 {
public:
    /**
     * Compute Keccak256 hash of input data
     *
     * @param data Input data to hash
     * @return Hex string of the hash
     */
    static std::string hash(const std::string& data) {
        std::vector<unsigned char> hash(32);

        EVP_MD_CTX* mdctx = EVP_MD_CTX_new();
        const EVP_MD* md = EVP_sha3_256();  // Keccak256 = SHA3-256

        EVP_DigestInit_ex(mdctx, md, nullptr);
        EVP_DigestUpdate(mdctx, data.c_str(), data.length());
        EVP_DigestFinal_ex(mdctx, hash.data(), nullptr);
        EVP_MD_CTX_free(mdctx);

        return bytesToHex(hash);
    }

    /**
     * Compute Keccak256 hash of byte vector
     */
    static std::string hash(const std::vector<unsigned char>& data) {
        std::vector<unsigned char> hash(32);

        EVP_MD_CTX* mdctx = EVP_MD_CTX_new();
        const EVP_MD* md = EVP_sha3_256();

        EVP_DigestInit_ex(mdctx, md, nullptr);
        EVP_DigestUpdate(mdctx, data.data(), data.size());
        EVP_DigestFinal_ex(mdctx, hash.data(), nullptr);
        EVP_MD_CTX_free(mdctx);

        return bytesToHex(hash);
    }

    /**
     * Convert hex string to bytes
     */
    static std::vector<unsigned char> hexToBytes(const std::string& hex) {
        std::vector<unsigned char> bytes;

        std::string cleanHex = hex;
        if (hex.substr(0, 2) == "0x") {
            cleanHex = hex.substr(2);
        }

        for (size_t i = 0; i < cleanHex.length(); i += 2) {
            std::string byteString = cleanHex.substr(i, 2);
            unsigned char byte = static_cast<unsigned char>(std::stoi(byteString, nullptr, 16));
            bytes.push_back(byte);
        }

        return bytes;
    }

    /**
     * Convert bytes to hex string
     */
    static std::string bytesToHex(const std::vector<unsigned char>& bytes) {
        std::stringstream ss;
        ss << "0x";
        ss << std::hex << std::setfill('0');

        for (const auto& byte : bytes) {
            ss << std::setw(2) << static_cast<int>(byte);
        }

        return ss.str();
    }

    /**
     * Hash an Ethereum address (used for checksum)
     */
    static std::string hashAddress(const std::string& address) {
        std::string cleanAddr = address;
        if (address.substr(0, 2) == "0x") {
            cleanAddr = address.substr(2);
        }

        // Convert to lowercase
        std::transform(cleanAddr.begin(), cleanAddr.end(), cleanAddr.begin(), ::tolower);

        return hash(cleanAddr);
    }

    /**
     * Create EIP-55 checksummed address
     */
    static std::string toChecksumAddress(const std::string& address) {
        std::string cleanAddr = address;
        if (address.substr(0, 2) == "0x") {
            cleanAddr = address.substr(2);
        }

        std::transform(cleanAddr.begin(), cleanAddr.end(), cleanAddr.begin(), ::tolower);
        std::string hashStr = hashAddress(cleanAddr);

        // Remove 0x prefix from hash
        hashStr = hashStr.substr(2);

        std::string checksummed = "0x";
        for (size_t i = 0; i < cleanAddr.length(); i++) {
            char c = cleanAddr[i];
            if (std::isalpha(c)) {
                // Get the corresponding hex digit from hash
                int hashValue = std::stoi(std::string(1, hashStr[i]), nullptr, 16);
                if (hashValue >= 8) {
                    checksummed += std::toupper(c);
                } else {
                    checksummed += c;
                }
            } else {
                checksummed += c;
            }
        }

        return checksummed;
    }
};

/**
 * Utility class for Ethereum-compatible operations
 */
class EthereumUtils {
public:
    /**
     * Derive Ethereum address from public key
     */
    static std::string publicKeyToAddress(const std::string& publicKeyHex) {
        auto pubKeyBytes = Keccak256::hexToBytes(publicKeyHex);

        // Remove first byte if compressed format (0x04 prefix)
        if (pubKeyBytes.size() == 65 && pubKeyBytes[0] == 0x04) {
            pubKeyBytes.erase(pubKeyBytes.begin());
        }

        // Hash the public key
        std::string hash = Keccak256::hash(pubKeyBytes);

        // Take last 20 bytes (40 hex chars + 0x prefix = 42 chars total, take last 40)
        std::string address = "0x" + hash.substr(hash.length() - 40);

        return Keccak256::toChecksumAddress(address);
    }

    /**
     * Validate Ethereum address format
     */
    static bool isValidAddress(const std::string& address) {
        if (address.length() != 42) return false;
        if (address.substr(0, 2) != "0x") return false;

        std::string hexPart = address.substr(2);
        for (char c : hexPart) {
            if (!std::isxdigit(c)) return false;
        }

        return true;
    }

    /**
     * Format wei to ether
     */
    static std::string weiToEther(const std::string& wei) {
        // Simple conversion for demonstration
        // In production, use bigint library
        long long weiValue = std::stoll(wei);
        double ether = static_cast<double>(weiValue) / 1e18;

        std::stringstream ss;
        ss << std::fixed << std::setprecision(18) << ether;
        return ss.str();
    }
};

int main() {
    std::cout << "🔐 Ethereum Cryptography Utilities (C++)" << std::endl;
    std::cout << "=========================================" << std::endl << std::endl;

    // Example 1: Hash a message
    std::cout << "1️⃣  Hashing message..." << std::endl;
    std::string message = "Hello, Ethereum!";
    std::string hash = Keccak256::hash(message);
    std::cout << "Message: " << message << std::endl;
    std::cout << "Hash: " << hash << std::endl << std::endl;

    // Example 2: Hex conversion
    std::cout << "2️⃣  Hex conversion..." << std::endl;
    std::string hexData = "0x48656c6c6f";
    auto bytes = Keccak256::hexToBytes(hexData);
    std::cout << "Hex: " << hexData << std::endl;
    std::cout << "Bytes: ";
    for (auto byte : bytes) {
        std::cout << static_cast<char>(byte);
    }
    std::cout << std::endl << std::endl;

    // Example 3: Address checksumming
    std::cout << "3️⃣  Address checksumming (EIP-55)..." << std::endl;
    std::string address = "0x5aAeb6053f3E94C9b9A09f33669435E7Ef1BeAed";
    std::string checksummed = Keccak256::toChecksumAddress(address);
    std::cout << "Original: " << address << std::endl;
    std::cout << "Checksum: " << checksummed << std::endl;
    std::cout << "Valid: " << (EthereumUtils::isValidAddress(checksummed) ? "Yes" : "No") << std::endl << std::endl;

    // Example 4: Wei to Ether conversion
    std::cout << "4️⃣  Wei to Ether conversion..." << std::endl;
    std::string wei = "1000000000000000000";
    std::string ether = EthereumUtils::weiToEther(wei);
    std::cout << "Wei: " << wei << std::endl;
    std::cout << "Ether: " << ether << std::endl << std::endl;

    // Example 5: Multiple hashing
    std::cout << "5️⃣  Chain hashing..." << std::endl;
    std::string data1 = "First";
    std::string data2 = "Second";
    std::string hash1 = Keccak256::hash(data1);
    std::string hash2 = Keccak256::hash(data2);
    std::string combined = hash1 + hash2;
    std::string finalHash = Keccak256::hash(combined);
    std::cout << "Hash('" << data1 << "'): " << hash1 << std::endl;
    std::cout << "Hash('" << data2 << "'): " << hash2 << std::endl;
    std::cout << "Hash(combined): " << finalHash << std::endl;

    return 0;
}
