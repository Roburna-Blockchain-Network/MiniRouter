// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  
  const Greeter = await hre.ethers.getContractFactory("BigCoin");
  const greeter = await Greeter.deploy('0x8b08dC5b5058136312218D548cf78c67C5C99f26', '0x7505756F5A17D54E641f045fc792f61Fa495DB43');

  await greeter.deployed();

  console.log("Greeter deployed to:", greeter.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
