# FlipFlopSwap

Simple, owner-only smart contract to perform ETH ⇄ USDT swaps using **Uniswap V2**, with **manual slippage control** enforced off-chain.

Designed to be driven by an external bot (e.g. Python + Web3), keeping on-chain logic minimal, explicit, and auditable.

---

## 🚀 Features

- ETH → USDT swaps
- USDT → ETH swaps
- Manual slippage (`amountOutMin`) per transaction
- Short deadline to reduce MEV exposure
- Owner-only execution
- ETH withdrawals (USDT intentionally locked)
- Full event logging (deposits, swaps, withdrawals)

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
swapETHToUSDT(uint ethAmount, uint amountOutMin)
swapUSDTToETH(uint usdtAmount, uint amountOutMin)
```

- `amountOutMin` is calculated **off-chain**
- Slippage is fully controlled by the caller
- Uses Uniswap V2 Router

---

### ETH Handling

- ETH can be received via:
  - Owner deposits
  - Swap outputs
- All ETH movements emit events
- Only the owner can withdraw ETH

```solidity
receive() external payable
withdrawETH(uint amount)
```

---

### Token Handling

- Only USDT is supported
- USDT withdrawals are **not supported by design**
- Safe approve pattern used (`approve(0)` → `approve(amount)`)

---

## 🔐 Access Control

- Single owner (immutable)
- All swap and withdraw functions are `onlyOwner`
- No multi-user logic
- No external permissions

---

## 📜 Events

| Event          | Description                  |
| -------------- | ---------------------------- |
| `ETHReceived`  | ETH received by the contract |
| `ETHWithdrawn` | ETH withdrawn by owner       |
| `SwapExecuted` | Successful swap execution    |

---

## ⚠️ Security Considerations

- **Slippage** is enforced manually via `amountOutMin`
- **Deadline** limited to 60 seconds
- **No price oracles** on-chain
- **No reentrancy risk** (no external callbacks after transfers)
- **MEV risk minimized**, not eliminated (small trades recommended)

For higher protection:

- Private transactions (Flashbots)
- MEV-protected RPCs

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
    address _usdt    // USDT token address
)
```

Example (Ethereum mainnet):

- Router: `0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D`
- USDT: `0xdAC17F958D2ee523a2206206994597C13D831ec7`

---

## 📄 License

MIT License

---

## 👤 Author

**FeliPerdao**

Industrial engineer.  
Likes simple contracts, manual control, and not getting sandwiched.

---

## 🧯 Final Note

If you’re looking for:

- complex on-chain strategies
- autonomous trading logic
- “AI smart contracts”

This is **not** that.

If you want:

- control
- clarity
- safety

You’re in the right place.
