import { expect } from "chai";
import { Contract, ContractTransaction, Signer } from "ethers";
import hre, { ethers } from "hardhat";
import { forkFrom } from "./utils/fork";
import {getAttackerContractName} from "./utils/fs";

//full description: https://www.palkeo.com/en/projets/ethereum/bzx.html#b-the-compound-borrow

let accounts: Signer[];
let attackerEOA: Signer;
let attacker: Contract;

before(async () => {
  await forkFrom(9484687);

  accounts = await ethers.getSigners();
  [attackerEOA] = accounts;

  const attackerFactory = await ethers.getContractFactory(
    getAttackerContractName(__filename),
    attackerEOA
  );
  attacker = await attackerFactory.deploy(
  );
  console.log(attacker)
});

describe("bzx exploit", function () {
    it("attacker made profit", async function (){
        let initialEthBalance = await attackerEOA.getBalance();

        await attacker.attack();

        let ethBalanceAfter = await attackerEOA.getBalance();

        let profit = ethBalanceAfter.sub(initialEthBalance);
        console.log(`Profit: ${ethers.utils.formatEther(profit)} ETH`);
        expect(ethBalanceAfter > initialEthBalance, "attacker did not make profit")
    })
})
