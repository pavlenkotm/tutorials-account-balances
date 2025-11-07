# Wallet Connect Demo (TypeScript + React)

A production-ready Web3 wallet connection component using Wagmi, ethers.js, and React.

## Features

- ✅ Multi-wallet support (MetaMask, WalletConnect, etc.)
- ✅ Network switching (Mainnet, Sepolia, etc.)
- ✅ Real-time balance display
- ✅ Transaction sending
- ✅ Message signing
- ✅ Auto-reconnection
- ✅ TypeScript support
- ✅ React hooks for Web3 operations
- ✅ Error handling and loading states

## Tech Stack

- **React**: UI library
- **TypeScript**: Type safety
- **Wagmi**: React hooks for Ethereum
- **ethers.js**: Ethereum JavaScript library (v6)
- **WalletConnect**: Multi-wallet protocol
- **Next.js**: React framework (optional)
- **Viem**: Low-level Ethereum utilities

## Why Wagmi?

Wagmi is the modern standard for Web3 React development:

| Feature | Wagmi | Legacy web3-react |
|---------|-------|-------------------|
| TypeScript | ✅ First-class | ⚠️ Partial |
| Hooks API | ✅ Clean & intuitive | ⚠️ Complex |
| Auto-reconnect | ✅ Built-in | ❌ Manual |
| ENS Support | ✅ Native | ⚠️ External |
| Testing | ✅ Easy mocking | ⚠️ Difficult |
| Bundle Size | ✅ Small | ⚠️ Large |

## Setup

```bash
npm install
```

## Usage

### Basic Integration

```tsx
import { App } from './WalletConnect';

function MyApp() {
  return <App />;
}
```

### Using the Hooks

```tsx
import { useAccount, useBalance } from 'wagmi';

function Balance() {
  const { address } = useAccount();
  const { data: balance } = useBalance({ address });

  return <div>{balance?.formatted} ETH</div>;
}
```

### Sending Transactions

```tsx
import { useSendTransaction } from './WalletConnect';

function SendETH() {
  const { sendTransaction, loading } = useSendTransaction();

  const handleSend = async () => {
    await sendTransaction('0x...', '0.1');
  };

  return (
    <button onClick={handleSend} disabled={loading}>
      {loading ? 'Sending...' : 'Send 0.1 ETH'}
    </button>
  );
}
```

### Signing Messages

```tsx
import { useSignMessage } from './WalletConnect';

function SignMessage() {
  const { signMessage, loading } = useSignMessage();

  const handleSign = async () => {
    const signature = await signMessage('Hello Web3!');
    console.log('Signature:', signature);
  };

  return (
    <button onClick={handleSign} disabled={loading}>
      Sign Message
    </button>
  );
}
```

## Configuration

### Environment Variables

Create a `.env.local` file:

```bash
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=your_project_id
```

Get a WalletConnect project ID from [WalletConnect Cloud](https://cloud.walletconnect.com/).

### Supported Networks

The example supports multiple networks:
- Ethereum Mainnet
- Sepolia (testnet)

Add more networks in the configuration:

```typescript
const { chains } = configureChains(
  [mainnet, sepolia, polygon, arbitrum],
  [publicProvider()]
);
```

## Component Structure

```
WalletConnect.tsx
├── App                    # Wagmi config wrapper
├── WalletConnectionUI     # Main UI component
├── useSendTransaction     # Transaction hook
└── useSignMessage         # Signing hook
```

## Features in Detail

### Auto-Reconnection
Wagmi automatically reconnects to previously connected wallets:

```typescript
const config = createConfig({
  autoConnect: true,  // Enable auto-reconnect
  // ...
});
```

### Network Switching
Users can switch networks directly from the UI:

```tsx
const { switchNetwork } = useSwitchNetwork();

<button onClick={() => switchNetwork(1)}>
  Switch to Mainnet
</button>
```

### Real-time Updates
Balance and network status update automatically:

```tsx
const { data: balance } = useBalance({
  address: address,
  watch: true,  // Real-time updates
});
```

## Styling

The component uses CSS classes for styling. Add your own styles:

```css
.wallet-container {
  display: flex;
  justify-content: center;
  padding: 2rem;
}

.wallet-card {
  background: white;
  border-radius: 12px;
  padding: 2rem;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

.connector-button {
  width: 100%;
  padding: 1rem;
  margin: 0.5rem 0;
  border: 2px solid #e5e5e5;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s;
}

.connector-button:hover {
  border-color: #3b82f6;
  background: #eff6ff;
}
```

## Error Handling

The component includes comprehensive error handling:

```tsx
if (error) {
  return <div className="error">{error.message}</div>;
}
```

Common errors:
- User rejected connection
- Unsupported network
- Insufficient funds
- Transaction failed

## Testing

```bash
# Type checking
npm run type-check

# Linting
npm run lint
```

### Unit Testing with Jest

```tsx
import { renderHook } from '@testing-library/react-hooks';
import { useAccount } from 'wagmi';

test('should connect wallet', async () => {
  const { result } = renderHook(() => useAccount());
  // Test wallet connection
});
```

## Security Best Practices

1. **Never expose private keys**: Always use wallet providers
2. **Validate addresses**: Use ethers.js `isAddress()` function
3. **Verify network**: Check chain ID before transactions
4. **Handle errors**: Properly catch and display errors
5. **Rate limiting**: Implement request throttling
6. **HTTPS only**: Always use secure connections

## Browser Compatibility

- ✅ Chrome/Brave (with MetaMask)
- ✅ Firefox (with MetaMask)
- ✅ Safari (with WalletConnect)
- ✅ Mobile browsers (with WalletConnect)

## Resources

- [Wagmi Documentation](https://wagmi.sh/)
- [ethers.js Documentation](https://docs.ethers.org/v6/)
- [WalletConnect](https://walletconnect.com/)
- [MetaMask Documentation](https://docs.metamask.io/)

## License

MIT
