import { useEffect, useState } from 'react';
import { ethers } from 'ethers';
import { WagmiConfig, createConfig, configureChains, mainnet, sepolia } from 'wagmi';
import { publicProvider } from 'wagmi/providers/public';
import { InjectedConnector } from 'wagmi/connectors/injected';
import { WalletConnectConnector } from 'wagmi/connectors/walletConnect';
import { useAccount, useConnect, useDisconnect, useBalance, useNetwork, useSwitchNetwork } from 'wagmi';

/**
 * WalletConnect Component
 *
 * Demonstrates Web3 wallet integration using Wagmi and ethers.js
 * Supports MetaMask, WalletConnect, and other Web3 wallets
 */

// Configure chains and providers
const { chains, publicClient, webSocketPublicClient } = configureChains(
  [mainnet, sepolia],
  [publicProvider()]
);

// Setup Wagmi config
const config = createConfig({
  autoConnect: true,
  connectors: [
    new InjectedConnector({ chains }),
    new WalletConnectConnector({
      chains,
      options: {
        projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || '',
      },
    }),
  ],
  publicClient,
  webSocketPublicClient,
});

/**
 * Main App Component
 */
export function App() {
  return (
    <WagmiConfig config={config}>
      <WalletConnectionUI />
    </WagmiConfig>
  );
}

/**
 * Wallet Connection UI Component
 */
function WalletConnectionUI() {
  const [mounted, setMounted] = useState(false);
  const { address, isConnected, connector } = useAccount();
  const { connect, connectors, error, isLoading, pendingConnector } = useConnect();
  const { disconnect } = useDisconnect();
  const { chain } = useNetwork();
  const { chains, switchNetwork } = useSwitchNetwork();

  // Get balance
  const { data: balance } = useBalance({
    address: address,
    watch: true,
  });

  // Prevent hydration mismatch
  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) return null;

  /**
   * Format address for display
   */
  const formatAddress = (addr: string) => {
    return `${addr.slice(0, 6)}...${addr.slice(-4)}`;
  };

  /**
   * Format balance for display
   */
  const formatBalance = (balance: any) => {
    if (!balance) return '0';
    return parseFloat(ethers.formatEther(balance.value)).toFixed(4);
  };

  /**
   * Connected State
   */
  if (isConnected && address) {
    return (
      <div className="wallet-container">
        <div className="wallet-card">
          <h2>🔗 Wallet Connected</h2>

          <div className="wallet-info">
            <div className="info-row">
              <span className="label">Address:</span>
              <span className="value">{formatAddress(address)}</span>
            </div>

            <div className="info-row">
              <span className="label">Balance:</span>
              <span className="value">
                {balance ? `${formatBalance(balance)} ${balance.symbol}` : 'Loading...'}
              </span>
            </div>

            <div className="info-row">
              <span className="label">Network:</span>
              <span className="value">{chain?.name || 'Unknown'}</span>
            </div>

            <div className="info-row">
              <span className="label">Connector:</span>
              <span className="value">{connector?.name || 'Unknown'}</span>
            </div>
          </div>

          {/* Network Switcher */}
          <div className="network-switcher">
            <h3>Switch Network</h3>
            <div className="network-buttons">
              {chains.map((x) => (
                <button
                  key={x.id}
                  onClick={() => switchNetwork?.(x.id)}
                  disabled={!switchNetwork || x.id === chain?.id}
                  className={x.id === chain?.id ? 'active' : ''}
                >
                  {x.name}
                  {isLoading && pendingConnector?.id === x.id && ' (switching)'}
                </button>
              ))}
            </div>
          </div>

          <button onClick={() => disconnect()} className="disconnect-button">
            Disconnect Wallet
          </button>
        </div>
      </div>
    );
  }

  /**
   * Disconnected State - Show connection options
   */
  return (
    <div className="wallet-container">
      <div className="wallet-card">
        <h2>🔌 Connect Your Wallet</h2>
        <p>Choose your preferred wallet to connect to this DApp</p>

        <div className="connector-buttons">
          {connectors.map((connector) => (
            <button
              key={connector.id}
              onClick={() => connect({ connector })}
              disabled={!connector.ready || isLoading}
              className="connector-button"
            >
              {connector.name}
              {!connector.ready && ' (unsupported)'}
              {isLoading && connector.id === pendingConnector?.id && ' (connecting)'}
            </button>
          ))}
        </div>

        {error && (
          <div className="error-message">
            {error.message}
          </div>
        )}

        <div className="info-text">
          <p>
            <strong>Don't have a wallet?</strong><br />
            Install <a href="https://metamask.io" target="_blank" rel="noopener noreferrer">MetaMask</a>
            {' '}or use <a href="https://walletconnect.com" target="_blank" rel="noopener noreferrer">WalletConnect</a>
          </p>
        </div>
      </div>
    </div>
  );
}

/**
 * Hook for sending transactions
 */
export function useSendTransaction() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const sendTransaction = async (to: string, value: string) => {
    setLoading(true);
    setError(null);

    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();

      const tx = await signer.sendTransaction({
        to,
        value: ethers.parseEther(value),
      });

      await tx.wait();
      return tx;
    } catch (err) {
      setError(err as Error);
      throw err;
    } finally {
      setLoading(false);
    }
  };

  return { sendTransaction, loading, error };
}

/**
 * Hook for signing messages
 */
export function useSignMessage() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const signMessage = async (message: string) => {
    setLoading(true);
    setError(null);

    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const signature = await signer.signMessage(message);
      return signature;
    } catch (err) {
      setError(err as Error);
      throw err;
    } finally {
      setLoading(false);
    }
  };

  return { signMessage, loading, error };
}

export default App;
