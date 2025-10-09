import { expect } from "chai";
import { network } from "hardhat";

const { ethers } = await network.connect();

describe("Escrow Contract", function () {
  let buyer, seller, arbiter;
  let escrow;

  beforeEach(async function () {
    [buyer, seller, arbiter] = await ethers.getSigners();
    escrow = await ethers.deployContract("Escrow");
    await escrow.waitForDeployment();
  });

  it("Should create a deal correctly", async function () {
    const tx = await escrow.connect(buyer).createDeal(seller.address, arbiter.address, {
      value: ethers.parseEther("1"),
    });

    await expect(tx).to.emit(escrow, "DealCreated");

    const deal = await escrow.deals(1);
    expect(deal.buyer).to.equal(buyer.address);
    expect(deal.seller).to.equal(seller.address);
    expect(deal.arbiter).to.equal(arbiter.address);
    expect(deal.amount).to.equal(ethers.parseEther("1"));
    expect(deal.state).to.equal(1); // AWAITING_DELIVERY
  });

  it("Only buyer can confirm delivery", async function () {
    await escrow.connect(buyer).createDeal(seller.address, arbiter.address, {
      value: ethers.parseEther("1"),
    });

    // Non-buyer tries
    await expect(
      escrow.connect(seller).confirmDelivery(1)
    ).to.be.revertedWith("Only buyer can confirm");

    // Buyer confirms
    const tx = await escrow.connect(buyer).confirmDelivery(1);
    await expect(tx).to.emit(escrow, "DeliveryConfirmed");

    const deal = await escrow.deals(1);
    expect(deal.state).to.equal(2); // COMPLETE
  });

  it("Buyer or arbiter can refund", async function () {
    await escrow.connect(buyer).createDeal(seller.address, arbiter.address, {
      value: ethers.parseEther("1"),
    });

    // Unauthorized account
    await expect(
      escrow.connect(seller).refund(1)
    ).to.be.revertedWith("Only buyer or arbiter can refund");

    // Arbiter triggers refund
    const tx = await escrow.connect(arbiter).refund(1);
    await expect(tx).to.emit(escrow, "Refunded");

    const deal = await escrow.deals(1);
    expect(deal.state).to.equal(3); // REFUNDED
  });
});
