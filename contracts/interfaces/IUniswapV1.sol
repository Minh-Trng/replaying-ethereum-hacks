pragma solidity ^0.8.0;

interface IUniswapV1 {
    function tokenToEthSwapInput(uint256 tokensSold, uint256 minEth, uint256 deadline) external;
}
