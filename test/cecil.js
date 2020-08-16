const Cecil = artifacts.require("./Cecil.sol");
var GenesisProtocol = artifacts.require("./GenesisProtocol.sol");
var AbsoluteVote = artifacts.require("./AbsoluteVote.sol");
const App = artifacts.require("./App.sol");
const Package = artifacts.require("./Package.sol");
var ImplementationDirectory = artifacts.require("./ImplementationDirectory.sol");
var PlantoidFactory = artifacts.require("./PlantoidFactory.sol");


const NULL_ADDRESS = '0x0000000000000000000000000000000000000000';
const NULL_HASH = '0x0000000000000000000000000000000000000000000000000000000000000000';

var packageName = "Plantoid";
var version = [0,1,0];

class TestSetup {
  constructor() {
  }
}

const setup = async function (accounts,beneficiary=accounts[0]) {
  var testSetup = new TestSetup();
  //deploy staking token
//  testSetup.stakingToken = await ERC827TokenMock.new(accounts[1],1000);
  //deploy genesisProtocol
  testSetup.genesisProtocol = await GenesisProtocol.new(NULL_ADDRESS,{gas:6000000});
  testSetup.amMachine = await AbsoluteVote.new({gas:6000000});
  var packageInstance = await Package.new();
  var appInstance = await App.new();
  var implementationDirectory = await ImplementationDirectory.new();
  await packageInstance.addVersion(version,implementationDirectory.address,NULL_HASH);
  await appInstance.setPackage(packageName,packageInstance.address,version);
  var cecilImplementation = await Cecil.new();
  await implementationDirectory.setImplementation("Cecil",cecilImplementation.address);
  var plantoidFactory = await PlantoidFactory.new();
  await plantoidFactory.initialize(appInstance.address);
  var tx = await plantoidFactory.createCecil(
                                                 [testSetup.amMachine.address,testSetup.genesisProtocol.address],
                                                 [accounts[2], accounts[3], accounts[4]],
                                                 accounts[0],
                                                 version,
                                                 {gas:6000000});


  testSetup.cecil = await Cecil.at(tx.logs[0].args._proxy);
  return testSetup;
};

contract('Cecil',  accounts =>  {

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
      await web3.eth.sendTransaction({from:accounts[1],to:testSetup.cecil.address, value:75,gas:7000000});
      console.log(">>sending 75 from acc1");
      //Proxy.(fallback): value: 3000 wei (with account 2)
      await web3.eth.sendTransaction({from:accounts[2],to:testSetup.cecil.address, value:50,gas:1000000});
      console.log(">>sending 50 from acc2");
      //Proxy.addProposal(0, "AAA") with account 2
      var tx = await testSetup.cecil.addProposal("AAA", 100, {from:accounts[2]});
      assert.equal(tx.logs.length, 1);
      assert.equal(tx.logs[0].event, "NewProposal");
      //get proposalId
      var proposalId = tx.logs[0].args.pid;
      // Proxy.voteProposal(0, "AAA"-id) with account 2
      console.log(">>account1 rep",(await testSetup.cecil.reputationOfHC(accounts[1],proposalId)).toNumber(), "propID =", proposalId);
      console.log(">>account2 rep",(await testSetup.cecil.reputationOfHC(accounts[2],proposalId)).toNumber(), "propID =", proposalId);
      assert.equal((await testSetup.cecil.proposals(proposalId)).status, 1);
      tx = await testSetup.cecil.voteProposal(proposalId,1,{from:accounts[2]});
      console.log(">>voted on " + proposalId);
      assert.equal((await testSetup.cecil.proposals(proposalId)).status, 1);
      await testSetup.cecil.voteProposal(proposalId,1,{from:accounts[1],gas:1000000});
      console.log(">>voted on " + proposalId);
      assert.equal((await testSetup.cecil.proposals(proposalId)).status, 2);
      assert.equal((await testSetup.cecil.getAdminBalance(accounts[2]))[1], 333);
      var amProposalId = (await testSetup.cecil.winpid());
      console.log("trying to vote on windpid = " + amProposalId);
      await testSetup.cecil.voteAMProposal(proposalId,1,{from:accounts[2],gas:1000000});
      console.log(">>voted on AM " + amProposalId);
      assert.equal((await testSetup.cecil.proposals(proposalId)).status, 2);
      console.log(">>status is ::: 2");
      var ppp = await testSetup.cecil.beneficiary();
      console.log("transferring funds to... beneficiary = " + ppp );
      await testSetup.cecil.voteAMProposal(proposalId,2,{from:accounts[3],gas:1000000});
      console.log(">>AM voted again 1");
      assert.equal((await testSetup.cecil.proposals(proposalId)).status, 2);
      await testSetup.cecil.voteAMProposal(proposalId,1,{from:accounts[4],gas:1000000});
      console.log(">>AM voted again 2");
      assert.equal((await testSetup.cecil.proposals(proposalId)).status, 3);

      try {
        await testSetup.cecil.addRepProposal(accounts[4], 1000, 1);
        assert(false, "only admin can propose");
      } catch(error) {

      }
      tx = await testSetup.cecil.addRepProposal(accounts[4], 1000, 1, {from:accounts[2]});
      assert.equal(tx.logs.length, 1);
      assert.equal(tx.logs[0].event, "NewRepProposal");

      var pid = tx.logs[0].args.pid;
      console.log("new Rep Proposal with PID = "); console.log(pid);
      await testSetup.cecil.voteRepProposal(pid,1,{from:accounts[2],gas:1000000});
      await testSetup.cecil.voteRepProposal(pid,1,{from:accounts[3],gas:1000000});
      console.log(">>account4 Admin rep",(await testSetup.cecil.reputationOfAdmin(accounts[4])).toNumber());







  /*    //try to do the same with a different seeds
      await web3.eth.sendTransaction({from:accounts[1],to:testSetup.plantoid.address, value:100,gas:7000000});
      var tx = await testSetup.plantoid.addProposal(1,"BBB",{from:accounts[2]});
      assert.equal(tx.logs[0].event, "NewProposal");
      var proposalId = tx.logs[0].args.pid;
      tx = await testSetup.plantoid.voteProposal(1,proposalId,1,{from:accounts[1]});
      assert.equal((await testSetup.plantoid.seeds(1)).status, 2);
      var amProposalId = (await testSetup.plantoid.seeds(1)).winpid;
      await testSetup.plantoid.voteAMProposal(1,amProposalId,1,{from:testSetup.artist,gas:1000000});
      assert.equal((await testSetup.plantoid.seeds(1)).status, 2);
      await testSetup.plantoid.voteAMProposal(1,amProposalId,1,{from:accounts[3],gas:1000000});
      assert.equal((await testSetup.plantoid.seeds(1)).status, 3);
*/
    });

});
