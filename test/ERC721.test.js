import { expect } from "chai";
import { network } from "hardhat";

const { ethers } = await network.connect();

describe("MyNFT Contract", function () {
    let deployer, user1, user2;
    let nft;

    beforeEach(async function () {
        [deployer, user1, user2] = await ethers.getSigners();
        nft = await ethers.deployContract("MyOpenNFT", ["MyToken", "MTK"]);
        await nft.waitForDeployment();
    });

    it("Should set the correct name and symbol", async function () {
        expect(await nft.name()).to.equal("MyToken");
        expect(await nft.symbol()).to.equal("MTK");
    });

    it("Deployer should be the owner", async function () {
        expect(await nft.owner()).to.equal(deployer.address);
    });

    it("Only owner can mint", async function () {
        // Owner mints successfully
        const tx = await nft.connect(deployer).mintNFT(user1.address, "ipfs://token1");
        await expect(tx).to.emit(nft, "Transfer").withArgs(ethers.ZeroAddress, user1.address, 1n);

        // Non-owner tries to mint → should revert
        await expect(
            nft.connect(user1).mintNFT(user2.address, "ipfs://token2")
        ).to.be.revert(ethers);

    });


    it("Token owner can transfer NFT", async function () {
        await nft.connect(deployer).mintNFT(user1.address, "ipfs://token1");

        const tx = await nft.connect(user1).transferFrom(user1.address, user2.address, 1);
        await expect(tx).to.emit(nft, "Transfer").withArgs(user1.address, user2.address, 1);

        expect(await nft.ownerOf(1)).to.equal(user2.address);
    });

    it("tokenURI should match minted URI", async function () {
        await nft.connect(deployer).mintNFT(user1.address, "ipfs://token1");
        expect(await nft.tokenURI(1)).to.equal("ipfs://token1");
    });
});
