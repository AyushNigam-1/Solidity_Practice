import { expect } from "chai";
import { network } from "hardhat";

const { ethers } = await network.connect();

describe("Crowdfunding", function () {
    let Crowdfunding, crowdfunding, creator, contributor1, contributor2;

    beforeEach(async function () {
        [creator, contributor1, contributor2] = await ethers.getSigners();
        Crowdfunding = await ethers.getContractFactory("Crowdfunding");
        crowdfunding = await Crowdfunding.deploy();
        await crowdfunding.waitForDeployment();
    });

    it("should create a new campaign", async function () {
        const tx = await crowdfunding.connect(creator).createCampaign("Build AI dApp", ethers.parseEther("5"), 10);
        const receipt = await tx.wait();
        const event = receipt.logs.find(
            log => log.fragment?.name === "CampaignCreated"
            );

            expect(event.args[0]).to.equal(0);
            expect(event.args[1]).to.equal(creator.address);
            expect(event.args[2]).to.equal(ethers.parseEther("5"));
    });

    it("should allow users to fund the campaign", async function () {
        await crowdfunding.connect(creator).createCampaign("Build AI dApp", ethers.parseEther("5"), 10);
        const tx = await crowdfunding.connect(contributor1).fund(0, { value: ethers.parseEther("2") });
        await expect(tx)
            .to.emit(crowdfunding, "Funded")
            .withArgs(0, contributor1.address, ethers.parseEther("2"));
    });

    it("should allow creator to withdraw if goal is met", async function () {
        await crowdfunding.connect(creator).createCampaign("Build AI dApp", ethers.parseEther("1"), 1);
        await crowdfunding.connect(contributor1).fund(0, { value: ethers.parseEther("1") });

        // Fast-forward time past deadline
        await ethers.provider.send("evm_increaseTime", [2 * 24 * 60 * 60]);
        await ethers.provider.send("evm_mine");

        const tx = await crowdfunding.connect(creator).withdraw(0);
        await expect(tx).to.emit(crowdfunding, "Withdrawn").withArgs(0, ethers.parseEther("1"));
    });

    it("should allow refund if goal not met", async function () {
        await crowdfunding.connect(creator).createCampaign("Small goal", ethers.parseEther("5"), 1);
        await crowdfunding.connect(contributor1).fund(0, { value: ethers.parseEther("1") });

        // Fast-forward time beyond deadline
        await ethers.provider.send("evm_increaseTime", [2 * 24 * 60 * 60]);
        await ethers.provider.send("evm_mine");

        const tx = await crowdfunding.connect(contributor1).refund(0);
        await expect(tx)
            .to.emit(crowdfunding, "Refunded")
            .withArgs(0, contributor1.address, ethers.parseEther("1"));
    });
});
