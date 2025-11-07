import org.web3j.crypto.Credentials;
import org.web3j.crypto.ECKeyPair;
import org.web3j.crypto.Keys;
import org.web3j.crypto.Sign;
import org.web3j.protocol.Web3j;
import org.web3j.protocol.core.DefaultBlockParameterName;
import org.web3j.protocol.core.methods.response.*;
import org.web3j.protocol.http.HttpService;
import org.web3j.utils.Convert;
import org.web3j.utils.Numeric;

import java.math.BigDecimal;
import java.math.BigInteger;

/**
 * Web3j Demo - Ethereum Java Integration
 * Demonstrates wallet operations, transactions, and smart contract interaction
 */
public class Web3Demo {

    private Web3j web3j;
    private static final String SEPOLIA_RPC = "https://eth-sepolia.public.blastapi.io";

    public Web3Demo(String rpcUrl) {
        this.web3j = Web3j.build(new HttpService(rpcUrl));
    }

    /**
     * Create new Ethereum account
     */
    public Credentials createAccount() throws Exception {
        ECKeyPair keyPair = Keys.createEcKeyPair();
        Credentials credentials = Credentials.create(keyPair);

        System.out.println("🔑 New Account Created");
        System.out.println("Address: " + credentials.getAddress());
        System.out.println("Private Key: " + credentials.getEcKeyPair().getPrivateKey().toString(16));

        return credentials;
    }

    /**
     * Get account balance in ETH
     */
    public BigDecimal getBalance(String address) throws Exception {
        EthGetBalance balanceResponse = web3j.ethGetBalance(
                address,
                DefaultBlockParameterName.LATEST
        ).send();

        BigInteger balanceWei = balanceResponse.getBalance();
        return Convert.fromWei(new BigDecimal(balanceWei), Convert.Unit.ETHER);
    }

    /**
     * Get current gas price
     */
    public BigInteger getGasPrice() throws Exception {
        EthGasPrice gasPrice = web3j.ethGasPrice().send();
        return gasPrice.getGasPrice();
    }

    /**
     * Get transaction by hash
     */
    public void getTransactionDetails(String txHash) throws Exception {
        EthTransaction txResponse = web3j.ethGetTransactionByHash(txHash).send();

        if (txResponse.getTransaction().isPresent()) {
            Transaction tx = txResponse.getTransaction().get();

            System.out.println("📝 Transaction Details");
            System.out.println("Hash: " + tx.getHash());
            System.out.println("From: " + tx.getFrom());
            System.out.println("To: " + tx.getTo());
            System.out.println("Value: " + Convert.fromWei(
                    new BigDecimal(tx.getValue()), Convert.Unit.ETHER
            ) + " ETH");
            System.out.println("Gas Price: " + tx.getGasPrice());
            System.out.println("Block: " + tx.getBlockNumber());
        } else {
            System.out.println("Transaction not found");
        }
    }

    /**
     * Get latest block information
     */
    public void getLatestBlock() throws Exception {
        EthBlock blockResponse = web3j.ethGetBlockByNumber(
                DefaultBlockParameterName.LATEST,
                false
        ).send();

        EthBlock.Block block = blockResponse.getBlock();

        System.out.println("📦 Latest Block");
        System.out.println("Number: " + block.getNumber());
        System.out.println("Hash: " + block.getHash());
        System.out.println("Timestamp: " + block.getTimestamp());
        System.out.println("Transactions: " + block.getTransactions().size());
        System.out.println("Gas Used: " + block.getGasUsed());
    }

    /**
     * Sign a message
     */
    public String signMessage(Credentials credentials, String message) {
        byte[] messageBytes = message.getBytes();
        byte[] messageHash = org.web3j.crypto.Hash.sha3(messageBytes);

        Sign.SignatureData signature = Sign.signPrefixedMessage(
                messageHash,
                credentials.getEcKeyPair()
        );

        byte[] signatureBytes = new byte[65];
        System.arraycopy(signature.getR(), 0, signatureBytes, 0, 32);
        System.arraycopy(signature.getS(), 0, signatureBytes, 32, 32);
        signatureBytes[64] = signature.getV()[0];

        return Numeric.toHexString(signatureBytes);
    }

    /**
     * Validate Ethereum address
     */
    public boolean isValidAddress(String address) {
        try {
            return address != null &&
                   address.startsWith("0x") &&
                   address.length() == 42 &&
                   Keys.toChecksumAddress(address) != null;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Convert Wei to Ether
     */
    public BigDecimal weiToEther(BigInteger wei) {
        return Convert.fromWei(new BigDecimal(wei), Convert.Unit.ETHER);
    }

    /**
     * Convert Ether to Wei
     */
    public BigInteger etherToWei(BigDecimal ether) {
        return Convert.toWei(ether, Convert.Unit.ETHER).toBigInteger();
    }

    /**
     * Get network version (chain ID)
     */
    public String getNetworkVersion() throws Exception {
        EthChainId chainId = web3j.ethChainId().send();
        return chainId.getChainId().toString();
    }

    /**
     * Check if connected to network
     */
    public boolean isConnected() {
        try {
            Web3ClientVersion version = web3j.web3ClientVersion().send();
            return version.getWeb3ClientVersion() != null;
        } catch (Exception e) {
            return false;
        }
    }

    public static void main(String[] args) {
        try {
            System.out.println("🌐 Web3j Ethereum Demo");
            System.out.println("======================\n");

            Web3Demo demo = new Web3Demo(SEPOLIA_RPC);

            // Check connection
            if (!demo.isConnected()) {
                System.out.println("❌ Failed to connect to Ethereum network");
                return;
            }
            System.out.println("✅ Connected to Ethereum\n");

            // Get chain ID
            String chainId = demo.getNetworkVersion();
            System.out.println("Chain ID: " + chainId + "\n");

            // Create new account
            Credentials credentials = demo.createAccount();
            System.out.println();

            // Get balance
            BigDecimal balance = demo.getBalance(credentials.getAddress());
            System.out.println("💰 Balance: " + balance + " ETH\n");

            // Get gas price
            BigInteger gasPrice = demo.getGasPrice();
            System.out.println("⛽ Gas Price: " + demo.weiToEther(gasPrice) + " ETH\n");

            // Get latest block
            demo.getLatestBlock();
            System.out.println();

            // Sign message
            String message = "Hello, Web3j!";
            String signature = demo.signMessage(credentials, message);
            System.out.println("✍️  Signed Message");
            System.out.println("Message: " + message);
            System.out.println("Signature: " + signature + "\n");

            // Validate address
            boolean valid = demo.isValidAddress(credentials.getAddress());
            System.out.println("✅ Address valid: " + valid);

        } catch (Exception e) {
            System.err.println("Error: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
