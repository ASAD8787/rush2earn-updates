const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  const initialOwner = process.env.TOKEN_OWNER || deployer.address;
  const wholeSupply = process.env.INITIAL_SUPPLY || "1000000000";
  const initialSupply = hre.ethers.parseUnits(wholeSupply, 18);

  console.log("Network:", hre.network.name);
  console.log("Deployer:", deployer.address);
  console.log("Owner:", initialOwner);
  console.log("Initial Supply:", wholeSupply, "RUSH");

  const RushToken = await hre.ethers.getContractFactory("RushToken");
  const token = await RushToken.deploy(initialOwner, initialSupply);
  await token.waitForDeployment();

  const address = await token.getAddress();
  console.log("RushToken deployed at:", address);
  console.log(
    "Verify with:",
    `npx hardhat verify --network base ${address} ${initialOwner} ${initialSupply.toString()}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
