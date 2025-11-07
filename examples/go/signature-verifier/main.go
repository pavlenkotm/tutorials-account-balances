package main

import (
	"crypto/ecdsa"
	"encoding/hex"
	"fmt"
	"log"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/common/hexutil"
	"github.com/ethereum/go-ethereum/crypto"
)

// SignatureVerifier handles Ethereum signature operations
type SignatureVerifier struct{}

// NewSignatureVerifier creates a new verifier instance
func NewSignatureVerifier() *SignatureVerifier {
	return &SignatureVerifier{}
}

// GenerateKeyPair generates a new ECDSA key pair
func (sv *SignatureVerifier) GenerateKeyPair() (*ecdsa.PrivateKey, *ecdsa.PublicKey, common.Address, error) {
	privateKey, err := crypto.GenerateKey()
	if err != nil {
		return nil, nil, common.Address{}, fmt.Errorf("failed to generate key: %w", err)
	}

	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		return nil, nil, common.Address{}, fmt.Errorf("failed to cast public key to ECDSA")
	}

	address := crypto.PubkeyToAddress(*publicKeyECDSA)

	return privateKey, publicKeyECDSA, address, nil
}

// SignMessage signs a message with a private key
func (sv *SignatureVerifier) SignMessage(message string, privateKey *ecdsa.PrivateKey) (string, error) {
	// Hash the message
	hash := crypto.Keccak256Hash([]byte(message))

	// Sign the hash
	signature, err := crypto.Sign(hash.Bytes(), privateKey)
	if err != nil {
		return "", fmt.Errorf("failed to sign message: %w", err)
	}

	return hexutil.Encode(signature), nil
}

// SignMessagePersonal signs a message with Ethereum personal_sign format
func (sv *SignatureVerifier) SignMessagePersonal(message string, privateKey *ecdsa.PrivateKey) (string, error) {
	// Create the Ethereum signed message hash
	prefixedMessage := fmt.Sprintf("\x19Ethereum Signed Message:\n%d%s", len(message), message)
	hash := crypto.Keccak256Hash([]byte(prefixedMessage))

	// Sign the hash
	signature, err := crypto.Sign(hash.Bytes(), privateKey)
	if err != nil {
		return "", fmt.Errorf("failed to sign personal message: %w", err)
	}

	// Adjust V value for personal_sign (add 27)
	signature[64] += 27

	return hexutil.Encode(signature), nil
}

// VerifySignature verifies a signature against a message and address
func (sv *SignatureVerifier) VerifySignature(message, signatureHex string, expectedAddress common.Address) (bool, error) {
	// Decode signature
	signature, err := hexutil.Decode(signatureHex)
	if err != nil {
		return false, fmt.Errorf("failed to decode signature: %w", err)
	}

	// Hash the message
	hash := crypto.Keccak256Hash([]byte(message))

	// Recover public key from signature
	sigPublicKey, err := crypto.Ecrecover(hash.Bytes(), signature)
	if err != nil {
		return false, fmt.Errorf("failed to recover public key: %w", err)
	}

	// Convert to ECDSA public key
	publicKey, err := crypto.UnmarshalPubkey(sigPublicKey)
	if err != nil {
		return false, fmt.Errorf("failed to unmarshal public key: %w", err)
	}

	// Get address from public key
	recoveredAddress := crypto.PubkeyToAddress(*publicKey)

	// Compare addresses
	return recoveredAddress == expectedAddress, nil
}

// VerifySignaturePersonal verifies a personal_sign format signature
func (sv *SignatureVerifier) VerifySignaturePersonal(message, signatureHex string, expectedAddress common.Address) (bool, error) {
	// Decode signature
	signature, err := hexutil.Decode(signatureHex)
	if err != nil {
		return false, fmt.Errorf("failed to decode signature: %w", err)
	}

	// Adjust V value back (subtract 27)
	if signature[64] >= 27 {
		signature[64] -= 27
	}

	// Create the prefixed hash
	prefixedMessage := fmt.Sprintf("\x19Ethereum Signed Message:\n%d%s", len(message), message)
	hash := crypto.Keccak256Hash([]byte(prefixedMessage))

	// Recover public key
	sigPublicKey, err := crypto.Ecrecover(hash.Bytes(), signature)
	if err != nil {
		return false, fmt.Errorf("failed to recover public key: %w", err)
	}

	// Convert to address
	publicKey, err := crypto.UnmarshalPubkey(sigPublicKey)
	if err != nil {
		return false, fmt.Errorf("failed to unmarshal public key: %w", err)
	}

	recoveredAddress := crypto.PubkeyToAddress(*publicKey)

	return recoveredAddress == expectedAddress, nil
}

// HashMessage returns the Keccak256 hash of a message
func (sv *SignatureVerifier) HashMessage(message string) string {
	hash := crypto.Keccak256Hash([]byte(message))
	return hash.Hex()
}

// RecoverAddress recovers the Ethereum address from a signature
func (sv *SignatureVerifier) RecoverAddress(message, signatureHex string) (common.Address, error) {
	signature, err := hexutil.Decode(signatureHex)
	if err != nil {
		return common.Address{}, fmt.Errorf("failed to decode signature: %w", err)
	}

	hash := crypto.Keccak256Hash([]byte(message))

	sigPublicKey, err := crypto.Ecrecover(hash.Bytes(), signature)
	if err != nil {
		return common.Address{}, fmt.Errorf("failed to recover public key: %w", err)
	}

	publicKey, err := crypto.UnmarshalPubkey(sigPublicKey)
	if err != nil {
		return common.Address{}, fmt.Errorf("failed to unmarshal public key: %w", err)
	}

	return crypto.PubkeyToAddress(*publicKey), nil
}

func main() {
	fmt.Println("🔐 Ethereum Signature Verifier Demo")
	fmt.Println("====================================\n")

	verifier := NewSignatureVerifier()

	// Example 1: Generate key pair
	fmt.Println("1️⃣  Generating new key pair...")
	privateKey, publicKey, address, err := verifier.GenerateKeyPair()
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("Address: %s\n", address.Hex())
	fmt.Printf("Private Key: %s\n", hex.EncodeToString(crypto.FromECDSA(privateKey)))
	fmt.Printf("Public Key: %s\n\n", hex.EncodeToString(crypto.FromECDSAPub(publicKey)))

	// Example 2: Sign message
	message := "Hello, Ethereum!"
	fmt.Println("2️⃣  Signing message...")
	fmt.Printf("Message: %s\n", message)

	signature, err := verifier.SignMessage(message, privateKey)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("Signature: %s\n\n", signature)

	// Example 3: Verify signature
	fmt.Println("3️⃣  Verifying signature...")
	valid, err := verifier.VerifySignature(message, signature, address)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("Signature valid: %v\n\n", valid)

	// Example 4: Personal sign
	fmt.Println("4️⃣  Personal sign (eth_sign format)...")
	personalSig, err := verifier.SignMessagePersonal(message, privateKey)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("Personal Signature: %s\n", personalSig)

	personalValid, err := verifier.VerifySignaturePersonal(message, personalSig, address)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("Personal signature valid: %v\n\n", personalValid)

	// Example 5: Hash message
	fmt.Println("5️⃣  Hashing message...")
	hash := verifier.HashMessage(message)
	fmt.Printf("Message hash: %s\n\n", hash)

	// Example 6: Recover address
	fmt.Println("6️⃣  Recovering address from signature...")
	recovered, err := verifier.RecoverAddress(message, signature)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("Recovered address: %s\n", recovered.Hex())
	fmt.Printf("Matches original: %v\n", recovered == address)
}
