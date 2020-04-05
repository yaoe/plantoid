const Plantoid = artifacts.require("./Plantoid.sol");
//var ERC827TokenMock = artifacts.require("./ERC827TokenMock.sol");
var GenesisProtocol = artifacts.require("./GenesisProtocol.sol");
var AbsoluteVote = artifacts.require("./AbsoluteVote.sol");
var Proxy = artifacts.require("./Proxy.sol");


const NULL_ADDRESS = '0x0000000000000000000000000000000000000000';

class TestSetup {
  constructor() {
  }
}

const setup = async function (accounts,artist=accounts[0],parent=accounts[0], threshold=100) {
  var testSetup = new TestSetup();

  //deploy staking token
//  testSetup.stakingToken = await ERC827TokenMock.new(accounts[1],1000);
  //deploy genesisProtocol
  testSetup.genesisProtocol = await GenesisProtocol.new(NULL_ADDRESS,{gas:6000000});
  testSetup.amMachine = await AbsoluteVote.new({gas:6000000});

  //deploy proxy
  testSetup.proxy = await Proxy.new(artist,parent,threshold);
  //deploy plantoid
  var plantoid = await Plantoid.new();

  await testSetup.proxy.upgradeTo(plantoid.address);

  testSetup.plantoid = await Plantoid.at(testSetup.proxy.address);

  await testSetup.plantoid.init();
  await testSetup.plantoid.setHCVotingMachine(testSetup.genesisProtocol.address);
  await testSetup.plantoid.setAMVotingMachine(testSetup.amMachine.address, [artist, accounts[3], accounts[4]]);
  var amParams = await testSetup.plantoid.amParams();
  console.log( await testSetup.amMachine.parameters(amParams));
  testSetup.artist = artist;

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
      console.log("checking account 1 = " + accounts[1]);
      await web3.eth.sendTransaction({from:accounts[1],to:testSetup.plantoid.address, value:75,gas:7000000});
      console.log(">>sending 75 from acc1");
      //Proxy.(fallback): value: 3000 wei (with account 2)
      await web3.eth.sendTransaction({from:accounts[2],to:testSetup.plantoid.address, value:50,gas:1000000});
      console.log(">>sending 50 from acc2");
      //Proxy.addProposal(0, "AAA") with account 2
      var tx = await testSetup.plantoid.addProposal(0,"AAA",{from:accounts[2]});
      assert.equal(tx.logs.length, 1);
      assert.equal(tx.logs[0].event, "NewProposal");
      //get proposalId
      var proposalId = tx.logs[0].args.pid;
      // Proxy.voteProposal(0, "AAA"-id) with account 2
      console.log(">>account1 rep",(await testSetup.plantoid.reputationOfHC(accounts[1],proposalId)).toNumber(), "propID =", proposalId);
      console.log(">>account2 rep",(await testSetup.plantoid.reputationOfHC(accounts[2],proposalId)).toNumber(), "propID =", proposalId);
      assert.equal((await testSetup.plantoid.seeds(0)).status, 1);
      tx = await testSetup.plantoid.voteProposal(0,proposalId,1,{from:accounts[2]});
      assert.equal((await testSetup.plantoid.seeds(0)).status, 1);
      await testSetup.plantoid.voteProposal(0,proposalId,1,{from:accounts[1],gas:1000000});
      assert.equal((await testSetup.plantoid.seeds(0)).status, 2);
      assert.equal((await testSetup.plantoid.getAdminBalance(testSetup.artist))[1], 333);
      var amProposalId = (await testSetup.plantoid.seeds(0)).winpid;
      await testSetup.plantoid.voteAMProposal(0,amProposalId,1,{from:testSetup.artist,gas:1000000});
      assert.equal((await testSetup.plantoid.seeds(0)).status, 2);
      await testSetup.plantoid.voteAMProposal(0,amProposalId,1,{from:accounts[3],gas:1000000});
      assert.equal((await testSetup.plantoid.seeds(0)).status, 3);
    });

});
