pragma solidity ^0.8.0;

interface IUnitroller {
    function enterMarkets(address[] memory cTokens) external returns (uint[] memory);
}
