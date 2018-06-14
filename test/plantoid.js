const Plantoid = artifacts.require("./Plantoid.sol");
var ERC827TokenMock = artifacts.require("./ERC827TokenMock.sol");


class TestSetup {
  constructor() {
  }
}
let accounts = web3.eth.accounts;
const setup = async function (artist=accounts[0], threshold=100) {
  var testSetup = new TestSetup();
  testSetup.stakingToken = await ERC827TokenMock.new(accounts[1],1000);
  testSetup.plantoid = await Plantoid.new(artist, threshold,testSetup.stakingToken.address);
  return testSetup;
};
contract('Plantoid', function (accounts)  {

    it("Proxy params", async () => {
        let testSetup = await setup();
        assert.equal(await testSetup.plantoid.artist(),accounts[0]);
        assert.equal(await testSetup.plantoid.threshold(),100);
    });

    it("Plantoid fund", async () => {
        let testSetup = await setup();
        var tx = await testSetup.plantoid.fund({value:100});
        assert.equal(tx.logs.length, 4);
        assert.equal(tx.logs[0].event, "GotDonation");
        assert.equal(tx.logs[0].args._donor, accounts[0]);
        assert.equal(tx.logs[0].args._amount, 100);

        assert.equal(tx.logs[1].event, "AcceptedDonation");
        assert.equal(tx.logs[1].args._donor, accounts[0]);
        assert.equal(tx.logs[1].args._amount, 100);

        assert.equal(tx.logs[2].event, "Reproducing");
        assert.equal(tx.logs[2].args._seedCnt, 0);

        assert.equal(tx.logs[3].event, "NewSeed");
        assert.equal(tx.logs[3].args._cnt, 1);

        assert.equal(await testSetup.plantoid.getBalance(),100);
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
