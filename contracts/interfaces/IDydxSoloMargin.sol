pragma solidity ^0.8.0;

struct AccountInfo {
    address owner;  // The address that owns the account
    uint256 number; // A nonce that allows a single address to control many accounts
}

enum AssetDenomination {
    Wei, // the amount is denominated in wei
    Par  // the amount is denominated in par
}

enum AssetReference {
        Delta, // the amount is given as a delta from the current value
        Target // the amount is given as an exact number to end up at
}

struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
}

struct ActionArgs {
        uint8 actionType;
        uint256 accountId;
        AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
}

interface IDydxSoloMargin {
    function operate(AccountInfo[] memory accounts, ActionArgs[] memory actions) external;
}

