// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title FlipFlopSwap
/// @author FeliPerdao
/// @notice Contract for simple ETH <-> USDC swaps using Uniswap V2
/// @dev All pricing, slippage and execution logic is handled off-chain.


interface IUniswapV2Router02 {
    /// @notice Returns the WETH address used by the router
    function WETH() external pure returns (address);

    /// @notice Swaps an exact amount of ETH for tokens
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    /// @notice Swaps an exact amount of tokens for ETH
    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

/// @dev Minimal owner-only swap contract.
/// Slippage and execution strategy are enforced off-chain via amountOutMin.
contract FlipFlopSwap {
    /// @notice Contract owner with exclusive execution rights
    address public immutable owner;

    /// @notice Uniswap V2 router
    IUniswapV2Router02 public immutable router;

    /// @notice USDC token used for swaps
    IERC20 public immutable usdc;

    /// @notice Maximum execution delay to reduce price manipulation risk
    uint256 public constant DEADLINE_OFFSET = 60;

    // =========================
    // EVENTS / ACCESS CONTROL
    // =========================

    /// @notice Emitted after a successful swap execution
    /// @param swapType 0 = ETH → USDC, 1 = USDC → ETH
    /// @param amountIn Exact input amount
    /// @param amountOut Exact output amount received
    event SwapExecuted(
        uint8 swapType, // 0 = ETH->USDC, 1 = USDC->ETH
        uint amountIn,
        uint amountOut
    );

    /// @dev Restricts function access to the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    // =========================
    // CONSTRUCTOR / RECEIVE
    // =========================

    /// @param _router Uniswap V2 router address
    /// @param _usdc USDC token address
    constructor(address _router, address _usdc) {
        owner = msg.sender;
        router = IUniswapV2Router02(_router);
        usdc = IERC20(_usdc);

        // Unlimited approval to avoid repeated approvals during swaps
        usdc.approve(_router, type(uint256).max);
    }

    /// @notice Allows the contract to receive ETH
    receive() external payable {}

    // =========================
    // SWAPS
    // =========================

    /// @notice Swaps ETH for USDC
    /// @dev Slippage is manually controlled via amountOutMin
    /// @param ethAmount Exact ETH amount to swap
    /// @param amountOutMin Minimum USDC amount accepted (slippage protection)
    function swapETHToUSDC(
        uint ethAmount,
        uint amountOutMin
    ) external onlyOwner {
        require(ethAmount > 0, "ZERO_AMOUNT");
        require(address(this).balance >= ethAmount, "INSUFFICIENT_ETH");

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(usdc);

        uint[] memory amounts =
            router.swapExactETHForTokens{value: ethAmount}(
                amountOutMin,
                path,
                address(this),
                block.timestamp + DEADLINE_OFFSET
            );

        emit SwapExecuted(0, ethAmount, amounts[1]);
    }

    /// @notice Swaps USDC for ETH
    /// @dev Requires prior token approval to the router
    /// @param usdcAmount Exact USDC amount to swap
    /// @param amountOutMin Minimum ETH amount accepted (slippage protection)
    function swapUSDCToETH(
        uint usdcAmount,
        uint amountOutMin
    ) external onlyOwner {
        require(usdcAmount > 0, "ZERO_USDC");
        require(usdc.balanceOf(address(this)) >= usdcAmount, "INSUFFICIENT_USDC");

        address[] memory path = new address[](2);
        path[0] = address(usdc);
        path[1] = router.WETH();

        uint[] memory amounts =
            router.swapExactTokensForETH(
                usdcAmount,
                amountOutMin,
                path,
                address(this),
                block.timestamp + DEADLINE_OFFSET
            );

        emit SwapExecuted(1, usdcAmount, amounts[1]);
    }

    // =========================
    // ETH WITHDRAW
    // =========================

    /// @notice Withdraws ETH from the contract
    /// @dev USDC has no withdrawal function; emergency rescue only
    /// @param amount ETH amount to withdraw
    function withdrawETH(uint amount) external onlyOwner {
        require(amount > 0, "amount = 0");
        require(address(this).balance >= amount, "no ETH enough");

        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, "ETH transfer failed");
    }

    // =========================
    // EMERGENCY / RESCUE
    // =========================

    /// @notice Rescue any ERC20 tokens sent to the contract by mistake
    /// @dev Intended for emergency recovery only
    function rescueERC20(address token, uint amount) external onlyOwner {
        IERC20(token).transfer(owner, amount);
    }
}
