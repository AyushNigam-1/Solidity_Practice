// ignition/modules/DeploySimpleNFT.ts
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("DeploySimpleNFT", (m) => {
  const deployer = m.getAccount(0); // Default to the first account

  // Deploy the SimpleNFT contract
  const nft = m.contract("SimpleNFT", ["MyNFT", "MNFT"], { from: deployer });

  return { nft };
});
