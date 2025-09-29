import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("ContractModule", (m) => {
  const contract = m.contract("TipJar");

  m.call(contract, "incBy", [5n]);

  return { contract };
});
