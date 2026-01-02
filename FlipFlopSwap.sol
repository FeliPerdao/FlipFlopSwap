// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title FlipFlopSwap
/// @author FeliPerdao
/// @notice Contract for simple ETH <-> USDT swaps using Uniswap V2
/// @dev Only Owner operations. ETH withdraws only.
interface IERC20 {
    /// @notice Returns balance of an address
    function balanceOf(address account) external view returns (uint256);

    /// @notice Approves token spending for a given spender
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IUniswapV2Router02 {
    /// @notice WETH Token direction
    function WETH() external pure returns (address);

    /// @notice Exact ETH swap for tokens
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    /// @notice Exact tokens swap for ETH
    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

/// @dev Main Swap Contracto with slippage is manually enforced by the caller via amountOutMin
contract FlipFlopSwap {

    /// @notice Only Owner restriction
    address public immutable owner;
    /// @notice Router Uniswap V2
    IUniswapV2Router02 public immutable router;

    /// @notice only USDT token swaps
    IERC20 public immutable usdt;

    /// @notice Maximum execution delay to reduce price manipulation risk
    uint256 public constant DEADLINE_OFFSET = 60;

    // =========================
    // EVENTS
    // =========================
    /// @notice Swap type executed
    enum SwapType { ETH_TO_USDT, USDT_TO_ETH }

    /// @notice Emmited after a successful swap
    /// @param swapType Type of swap
    /// @param amountIn Input Amount
    /// @param amountOut Output Amount received
    event SwapExecuted(
        SwapType swapType,
        uint amountIn,
        uint amountOut
    );

    /// @notice Emitted when ETH is received
    /// @param amount ETH amount received
    event ETHReceived(uint amount);

    /// @notice Emitted when ETH is withdrawn
    /// @param amount ETH amount withdrawn
    event ETHWithdrawn(uint amount);

    /// @dev Restricts function access to the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    /// @notice Contract constructor
    /// @param _router Uniswap V2 router address
    /// @param _usdt USDT token address
    constructor(address _router, address _usdt) {
        owner = msg.sender;
        router = IUniswapV2Router02(_router);
        usdt = IERC20(_usdt);
    }

    // =========================
    // RECEIVE ETH  
    // =========================
    /// @notice Receives ETH (from owner deposit or swap result)
    /// @dev Only the owner is expected to send ETH
    receive() external payable {
        emit ETHReceived(msg.value);
    }

    // =========================
    // SWAPS
    // =========================

    /// @notice Swaps ETH for USDT
    /// @dev Slippage is manually controlled via amountOutMin
    /// @param ethAmount Exact ETH amount to swap
    /// @param amountOutMin Minimum USDT amount accepted
    function swapETHToUSDT(
        uint ethAmount,
        uint amountOutMin
    ) external onlyOwner {
        require(ethAmount > 0, "eth = 0");
        require(address(this).balance >= ethAmount, "no hay ETH");

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(usdt);

        uint[] memory amounts =
            router.swapExactETHForTokens{value: ethAmount}(
                amountOutMin,
                path,
                address(this),
                block.timestamp + DEADLINE_OFFSET
            );

        emit SwapExecuted(
            SwapType.ETH_TO_USDT,
            ethAmount,
            amounts[1]
        );
    }

    /// @notice Swaps USDT for ETH
    /// @dev Requires prior token approval to the router
    /// @param usdtAmount Exact USDT amount to swap
    /// @param amountOutMin Minimum ETH amount accepted
    function swapUSDTToETH(
        uint usdtAmount,
        uint amountOutMin
    ) external onlyOwner {
        require(usdtAmount > 0, "usdt = 0");
        require(usdt.balanceOf(address(this)) >= usdtAmount, "no hay USDT");

        usdt.approve(address(router), 0);
        usdt.approve(address(router), usdtAmount);


        address[] memory path = new address[](2);
        path[0] = address(usdt);
        path[1] = router.WETH();

        uint[] memory amounts =
            router.swapExactTokensForETH(
                usdtAmount,
                amountOutMin,
                path,
                address(this),
                block.timestamp + DEADLINE_OFFSET
            );

        emit SwapExecuted(
            SwapType.USDT_TO_ETH,
            usdtAmount,
            amounts[1]
        );
    }

    // =========================
    // ETH WITHDRAW
    // =========================

    /// @notice Withdraws ETH from the contract
    /// @dev USDT withdrawals are intentionally not supported
    /// @param amount ETH amount to withdraw
    function withdrawETH(uint amount) external onlyOwner {
        require(amount > 0, "amount = 0");
        require(address(this).balance >= amount, "no ETH enough");

        emit ETHWithdrawn(amount);

        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, "ETH transfer failed");
    }
}
