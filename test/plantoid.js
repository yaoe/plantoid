const Plantoid = artifacts.require("./Plantoid.sol");
var ERC827TokenMock = artifacts.require("./ERC827TokenMock.sol");
var GenesisProtocol = artifacts.require("./GenesisProtocol.sol");
var Proxy = artifacts.require("./Proxy.sol");


class TestSetup {
  constructor() {
  }
}

const setup = async function (accounts,artist=accounts[0], threshold=100) {
  var testSetup = new TestSetup();

  //deploy staking token
  testSetup.stakingToken = await ERC827TokenMock.new(accounts[1],1000);
  //deploy genesisProtocol
  testSetup.genesisProtocol = await GenesisProtocol.new(testSetup.stakingToken.address,{gas:6000000});
  //deploy proxy
  testSetup.proxy = await Proxy.new(accounts[0],accounts[0],50);
  //deploy plantoid
  var plantoid = await Plantoid.new();

  await testSetup.proxy.upgradeTo(plantoid.address);

  testSetup.plantoid = await Plantoid.at(testSetup.proxy.address);

  await testSetup.plantoid.init();
  await testSetup.plantoid.setVotingMachine(testSetup.genesisProtocol.address);

  return testSetup;
};
contract('Plantoid',  accounts =>  {

    // it("Proxy params", async () => {
    //     let testSetup = await setup();
    //     assert.equal(await testSetup.plantoid.artist(),accounts[0]);
    //     assert.equal(await testSetup.plantoid.threshold(),100);
    // });

    // it("Plantoid fund", async () => {
    //     let testSetup = await setup();
    //     var tx = await testSetup.plantoid.fund({value:100});
    //     assert.equal(tx.logs.length, 4);
    //     assert.equal(tx.logs[0].event, "GotDonation");
    //     assert.equal(tx.logs[0].args._donor, accounts[0]);
    //     assert.equal(tx.logs[0].args._amount, 100);
    //
    //     assert.equal(tx.logs[1].event, "AcceptedDonation");
    //     assert.equal(tx.logs[1].args._donor, accounts[0]);
    //     assert.equal(tx.logs[1].args._amount, 100);
    //
    //     assert.equal(tx.logs[2].event, "Reproducing");
    //     assert.equal(tx.logs[2].args._seedCnt, 0);
    //
    //     assert.equal(tx.logs[3].event, "NewSeed");
    //     assert.equal(tx.logs[3].args._cnt, 1);
    //
    //     assert.equal(await testSetup.plantoid.getBalance(),100);
    // });

    it("propose vote and execute ", async () => {
      var testSetup = await setup(accounts);
      //Proxy.(fallback): value: 3000 wei (with account 1)
      await web3.eth.sendTransaction({from:accounts[1],to:testSetup.plantoid.address, value:30,gas:1000000});
      //Proxy.(fallback): value: 3000 wei (with account 2)
      await web3.eth.sendTransaction({from:accounts[2],to:testSetup.plantoid.address, value:30,gas:1000000});
      //Proxy.addProposal(0, "AAA") with account 2
       var tx = await testSetup.plantoid.addProposal(0,"AAA",{from:accounts[2]});
      assert.equal(tx.logs.length, 1);
      assert.equal(tx.logs[0].event, "NewProposal");
      //get proposalId
      var proposalId = tx.logs[0].args.pid;
      // Proxy.voteProposal(0, "AAA"-id) with account 2
      tx = await testSetup.plantoid.voteProposal(0,proposalId,{from:accounts[2]});
      //Proxy.voteProposal(0, "AAA"-id) with account 1
      tx = await testSetup.plantoid.voteProposal(0,proposalId,{from:accounts[1]});

      assert.equal(tx.logs.length, 1);
      assert.equal(tx.logs[0].event, "Execution");

    });

});
