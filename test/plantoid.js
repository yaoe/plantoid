const Plantoid = artifacts.require("./Plantoid.sol");
//const Reputation = artifacts.require("./Reputation.sol");

contract('Plantoid', function (accounts)  {

    it("Test parameters", async () => {
        let plantoid = await Plantoid.new(accounts[0], web3.toWei(1));

        assert.equal(await plantoid.artist(), accounts[0], 'Artist param is not correct');
        assert.equal(await plantoid.threshold(), web3.toWei(1), 'threshold param is not correct');
        let baby = await plantoid.babies(0);
        if (baby[0] == '0x0') {
            assert(false, 'No rep system');
        }
    });

    // it("Try donating", async () => {
    //     let plantoid = await Plantoid.new(accounts[0], web3.toWei(1));
    //     await plantoid.fund( { from: accounts[1], value: web3.toWei(0.5) } );
    //     let baby = await plantoid.babies(0);
    //     let repSystem = await Reputation.at(baby[0]);
    //     assert.equal(await repSystem.reputationOf(accounts[1]), web3.toWei(0.5), 'Donor did not get his reputation');
    //     // TODO: add more checks
    // });

});
