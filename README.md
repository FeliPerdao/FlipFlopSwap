# FlipFlopSwap

Minimal, owner-only smart contract to perform **ETH ⇄ USDC swaps** using **Uniswap V2**, with **manual slippage control** enforced entirely off-chain.

Designed to be driven by an external bot (Python, Node.js, scripts), keeping on-chain logic **simple, explicit, cheap and auditable**.

---

## 🚀 Features

- ETH → USDC swaps  
- USDC → ETH swaps  
- Manual slippage control (`amountOutMin`)  
- Short execution deadline (MEV mitigation)  
- Owner-only execution model  
- ETH deposits & withdrawals  
- ERC20 rescue function (emergency use only)  
- Swap execution events  

---

## 🧠 Design Philosophy

This contract **does not make decisions**.

All trading logic lives **off-chain**:

- Price discovery  
- Slippage calculation  
- Execution timing  
- Automation logic  

On-chain responsibilities are intentionally limited to:

- Asset custody  
- Swap execution  
- Event emission  

Less logic on-chain = less attack surface.

---

## 📦 Contract Overview

### Swap Functions

```solidity
swapETHToUSDC(uint256 ethAmount, uint256 amountOutMin)
swapUSDCToETH(uint256 usdcAmount, uint256 amountOutMin)
```

- `amountOutMin` is calculated **off-chain**
- Slippage is entirely controlled by the caller
- Uses Uniswap V2 Router directly

---

### ETH Handling

The contract can receive ETH via:

- Direct transfers (owner deposits)
- Swap outputs

```solidity
receive() external payable
withdrawETH(uint256 amount)
```

Only the owner can withdraw ETH.

---

### USDC Handling & Approval

The contract requires approval to allow the Uniswap router to spend USDC.

```solidity
approveUSDC()
```

#### Why is `approveUSDC()` required?

- Uniswap V2 pulls tokens via `transferFrom`
- ERC20 requires explicit approval before spending
- Approval is set to `uint256.max` for gas efficiency

#### Why is it **not** in the constructor?

- Approvals are **external calls**
- Moving it outside the constructor **reduces deployment gas**
- You deploy cheaper, approve once later

#### How many times should it be called?

- **Once** after deployment  
- Calling it again simply overwrites the allowance with the same value  
- No security risk, just wasted gas  

Best practice:
> Call `approveUSDC()` once and forget it exists.

---

### Emergency ERC20 Rescue

```solidity
rescueERC20(address token, uint256 amount)
```

Allows recovery of any ERC20 tokens mistakenly sent to the contract.

- Owner-only
- Emergency use only
- Not part of normal operation

---

## 🔐 Access Control

- Single immutable owner
- All sensitive functions are `onlyOwner`
- No multi-user logic
- No upgradeability
- No external permissions

Simple and boring — by design.

---

## 📜 Events

| Event | Description |
|------|------------|
| `SwapExecuted` | Emitted after each successful swap |

Useful for:

- Off-chain monitoring
- Bots
- Analytics
- Auditing

---

## ⚠️ Security Considerations

- Slippage is enforced manually via `amountOutMin`
- Deadline limited to 60 seconds
- No on-chain price oracles
- No reentrancy surface
- MEV risk reduced, not eliminated

Recommended:

- Small trade sizes
- Private transactions
- MEV-protected RPCs when possible

---

## 🤖 Automation (Off-chain)

Designed to be controlled via:

- Python + Web3.py  
- Node.js + ethers.js  
- Any EVM-compatible client  

Typical flow:

1. Fetch price off-chain  
2. Compute slippage  
3. Execute swap  
4. Listen to events  

---

## 🛠 Deployment (BASE Network)

This contract is deployed on **Base**:

- **FlipFlopSwap address:**  
  `0xc6eE31Bb47626a888E07AB5c58DC7f6162EEa292`

### Constructor Parameters (Base)

```solidity
_router = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24
_usdc   = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
```

### Constructor Parameters (Ethereun Mainnet)

```solidity
_router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
_usdc   = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
```

---

## 📄 License

MIT License

---

## 👤 Author

**FeliPerdao**  
Industrial Engineer  

Prefers:
- explicit control  
- minimal contracts  
- predictable execution  

---

## 🧯 Final Note

This contract is **not**:

- autonomous trading logic  
- complex DeFi strategy  
- magic money printer  

This contract **is**:

- simple  
- explicit  
- boring  
- safe  
