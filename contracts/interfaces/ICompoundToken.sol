pragma solidity ^0.8.0;

interface ICompoundToken {
    function mint() external payable;
    function balanceOfUnderlying(address owner) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
}
