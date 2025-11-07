import Foundation
import Web3
import CryptoKit

/**
 * Ethereum Wallet SDK for iOS
 * Demonstrates mobile Web3 integration
 */

class EthereumWallet {
    private let web3: Web3
    private var account: EthereumAccount?

    init(rpcURL: String) {
        self.web3 = Web3(rpcURL: rpcURL)
    }

    /// Create new wallet
    func createWallet() throws -> EthereumAccount {
        let account = try EthereumAccount.create()
        self.account = account
        return account
    }

    /// Get balance
    func getBalance(address: EthereumAddress) async throws -> BigUInt {
        return try await web3.eth.getBalance(address: address)
    }

    /// Send transaction
    func sendTransaction(to: EthereumAddress, value: BigUInt) async throws -> String {
        guard let account = account else {
            throw WalletError.noAccount
        }

        let tx = EthereumTransaction(
            from: account.address,
            to: to,
            value: value
        )

        let hash = try await web3.eth.sendTransaction(transaction: tx)
        return hash.hex()
    }

    /// Sign message
    func signMessage(_ message: String) throws -> String {
        guard let account = account else {
            throw WalletError.noAccount
        }

        let signature = try account.sign(message: message)
        return signature.hex()
    }
}

enum WalletError: Error {
    case noAccount
    case invalidAddress
    case transactionFailed
}

// Example usage
@main
struct WalletApp {
    static func main() async {
        print("📱 iOS Ethereum Wallet SDK")
        print("==========================\n")

        let wallet = EthereumWallet(rpcURL: "https://eth-sepolia.public.blastapi.io")

        do {
            // Create wallet
            let account = try wallet.createWallet()
            print("✅ Wallet Created")
            print("Address: \\(account.address.hex())\n")

            // Get balance
            let balance = try await wallet.getBalance(address: account.address)
            print("💰 Balance: \\(balance) wei\n")

        } catch {
            print("❌ Error: \\(error)")
        }
    }
}
