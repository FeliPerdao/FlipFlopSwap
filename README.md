# FlipFlopSwap

Simple, owner-only smart contract to perform ETH ⇄ USDC swaps using **Uniswap V2**, with **manual slippage control** enforced off-chain.

Designed to be driven by an external bot (e.g. Python + Web3), keeping on-chain logic minimal, explicit, and auditable.

---

## 🚀 Features

- ETH → USDC swaps
- USDC → ETH swaps
- Manual slippage (`amountOutMin`) per transaction
- Short deadline to reduce MEV exposure
- Owner-only execution
- ETH withdrawals
- ERC20 rescue function (emergency only)
- Full event logging for swaps

---

## 🧠 Design Philosophy

This contract **does not make decisions**.

All strategy logic (pricing, timing, slippage calculation, automation) lives **off-chain**:

- Python bot
- Trading script
- Manual execution

On-chain code is intentionally:

- Small
- Predictable
- Easy to audit
- Hard to exploit

Less magic. Less risk.

---

## 📦 Contract Overview

### Swap Functions

```solidity
swapETHToUSDC(uint256 ethAmount, uint256 amountOutMin)
swapUSDCToETH(uint256 usdcAmount, uint256 amountOutMin)
```

- `amountOutMin` is calculated **off-chain**
- Slippage is fully controlled by the caller
- Uses Uniswap V2 Router

---

### ETH Handling

- ETH can be received via:
  - Owner deposits
  - Swap outputs
- Only the owner can withdraw ETH

```solidity
receive() external payable
withdrawETH(uint256 amount)
```

---

### Token Handling

- Only **USDC** is supported for swaps
- USDC is approved once at deployment using the standard ERC20 `approve` pattern
- Direct USDC withdrawals are intentionally not exposed
- Emergency ERC20 rescue function available for recovery scenarios

```solidity
rescueERC20(address token, uint256 amount)
```

---

## 🔐 Access Control

- Single owner (immutable)
- All swap and withdraw functions are `onlyOwner`
- No multi-user logic
- No external permissions

---

## 📜 Events

| Event          | Description               |
| -------------- | ------------------------- |
| `SwapExecuted` | Successful swap execution |

---

## ⚠️ Security Considerations

- **Slippage** is enforced manually via `amountOutMin`
- **Deadline** limited to 60 seconds
- **No price oracles** on-chain
- **No reentrancy risk** (no external callbacks after swaps)
- **MEV risk minimized**, not eliminated (small trades recommended)

For additional protection:

- Private transactions (Flashbots)
- MEV-protected RPC endpoints

---

## 🤖 Automation (Off-chain)

This contract is designed to be automated via:

- Python + Web3.py
- Node.js + ethers.js
- Any Ethereum-compatible client

No additional on-chain changes required.

Typical flow:

1. Fetch price off-chain
2. Compute slippage
3. Call swap function
4. Monitor events

---

## 🛠 Deployment

Constructor parameters:

```solidity
constructor(
    address _router, // Uniswap V2 Router
    address _usdc    // USDC token address
)
```

Example (Ethereum mainnet):

- Uniswap V2 Router: `0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D`
- USDC: `0xA0b86991c6218b36c1d19d4a2e9eb0ce3606eb48`

---

## 📄 License

MIT License

---

## 👤 Author

**FeliPerdao**

Industrial engineer.  
Prefers explicit control, minimal contracts, and predictable execution.

---

## 🧯 Final Note

This code **is not**:

- complex on-chain strategies
- autonomous trading logic
- “AI smart contracts”

This code **is**:

- control
- clarity
- safety
