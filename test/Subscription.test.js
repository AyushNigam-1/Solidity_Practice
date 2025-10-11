import { expect } from "chai";
import { network } from "hardhat";

const { ethers } = await network.connect();

describe("Subscription Contract", function () {
    let Subscription, subscription, provider, user;
    const amount = ethers.parseEther("1");
    const period = 3600;

    beforeEach(async function () {
        [provider, user] = await ethers.getSigners();

        Subscription = await ethers.getContractFactory("Subscription");
        subscription = await Subscription.connect(provider).deploy(amount, period);
        await subscription.waitForDeployment();
    });

    it("should set the correct provider and plan", async function () {
        expect(await subscription.provider()).to.equal(provider.address);
        const plan = await subscription.plan();
        expect(plan.amount).to.equal(amount);
        expect(plan.period).to.equal(period);
    });

    it("should allow a user to subscribe", async function () {
        const tx = await subscription.connect(user).subscribe({ value: amount });
        const receipt = await tx.wait();

        // extract event args directly from logs
        const event = receipt.logs
            .map(log => {
                try {
                    return subscription.interface.parseLog(log);
                } catch {
                    return null;
                }
            })
            .find(e => e && e.name === "Subscribed");

        expect(event.args.user).to.equal(user.address);
        expect(event.args.nextPayment).to.be.a("bigint");

        const sub = await subscription.subscribers(user.address);
        expect(sub.active).to.equal(true);
    });

    it("should allow a user to pay after period ends", async function () {
        await subscription.connect(user).subscribe({ value: amount });

        // fast-forward time
        await ethers.provider.send("evm_increaseTime", [period]);
        await ethers.provider.send("evm_mine");

        const balanceBefore = await ethers.provider.getBalance(provider.address);

        const tx = await subscription.connect(user).pay({ value: amount });
        const receipt = await tx.wait();

        const event = receipt.logs
            .map(log => {
                try {
                    return subscription.interface.parseLog(log);
                } catch {
                    return null;
                }
            })
            .find(e => e && e.name === "Payment");

        expect(event.args.user).to.equal(user.address);
        expect(event.args.amount).to.equal(amount);
        expect(event.args.date).to.be.a("bigint");

        const balanceAfter = await ethers.provider.getBalance(provider.address);
        expect(balanceAfter).to.be.greaterThan(balanceBefore);
    });

    it("should allow a user to cancel subscription", async function () {
        await subscription.connect(user).subscribe({ value: amount });
        const tx = await subscription.connect(user).cancel();
        const receipt = await tx.wait();

        const event = receipt.logs
            .map(log => {
                try {
                    return subscription.interface.parseLog(log);
                } catch {
                    return null;
                }
            })
            .find(e => e && e.name === "Canceled");

        expect(event.args.user).to.equal(user.address);

        const sub = await subscription.subscribers(user.address);
        expect(sub.active).to.equal(false);
    });
});
