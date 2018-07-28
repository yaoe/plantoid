const Plantoid = artifacts.require("./Plantoid.sol");
var ERC827TokenMock = artifacts.require("./ERC827TokenMock.sol");
var GenesisProtocol = artifacts.require("./GenesisProtocol.sol");


class TestSetup {
  constructor() {
  }
}
let accounts = web3.eth.accounts;

export class GenesisProtocolParams {
  constructor() {
  }
}

const genesisProtocolParams = [
                              50,//_preBoostedVoteRequiredPercentage=50,
                              60,//_preBoostedVotePeriodLimit=60,
                              60,//_boostedVotePeriodLimit=60,
                              1,//_thresholdConstA=1,
                              1,//_thresholdConstB=1,
                              1,//_minimumStakingFee=0,
                              0,//_quietEndingPeriod=0,
                              60000,//_proposingRepRewardConstA=60000,
                              1000,//_proposingRepRewardConstB=1000,
                              10,//_stakerFeeRatioForVoters=10,
                              10,//_votersReputationLossRatio=10,
                              80,//_votersGainRepRatioFromLostRep=80,
                              15,//_daoBountyConst = 15,
                              10//_daoBountyLimt =10
                            ]

const setup = async function (artist=accounts[0], threshold=100) {
  var testSetup = new TestSetup();
  //deploy staking contract
  testSetup.stakingToken = await ERC827TokenMock.new(accounts[1],1000);
  //deploy plantoid
  testSetup.plantoid = await Plantoid.new(artist, threshold,testSetup.stakingToken.address);
  //deploy genesisProtocol
  testSetup.genesisProtocol = await GenesisProtocol.new(testSetup.stakingToken.address);
  //setup genesisProtocolParams
  await testSetup.plantoid.setGenesisProtocolParameters(
                                                          testSetup.genesisProtocol.address,
                                                          genesisProtocolParams
                                                        );
  //get paramsHash value from genesisProtocol
  testSetup.genesisProtocolParamsHash = await testSetup.genesisProtocol.getParametersHash(genesisProtocolParams,
                                                                                      [
                                                                                        testSetup.plantoid.address,//the organization
                                                                                        testSetup.plantoid.address//allow to voteOnBehalf
                                                                                      ]
                                                                                    );
  //set plantoid params hash
  await testSetup.plantoid.setParameters(testSetup.genesisProtocolParamsHash, //the voting machine params
                                        testSetup.genesisProtocol.address,    //the voting machine address
                                        testSetup.genesisProtocol.address);   //allow to execute


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

    it("Plantoid propose ,vote and execute ", async () => {
        let testSetup = await setup();
        //send funds to create new seed
        var tx = await testSetup.plantoid.fund({value:100});
        var proposer = accounts[1];
        //propose on previous seed
        tx = await testSetup.plantoid.addProposal(0,"url",{from:proposer});
        assert.equal(tx.logs.length, 1);
        assert.equal(tx.logs[0].event, "NewProposal");
        //get proposalId
        var proposalId = tx.logs[0].args._proposalId;
        //donor now has 100 reputation
        assert.equal(await testSetup.plantoid.reputationOf(accounts[0],proposalId),100);
        //get proposer balance before voting and execution.
        var proposerBalance = web3.eth.getBalance(proposer);
        //vote YES with 100 reputation ..should call execute because it is the only one with
        // reputation.
        tx = await testSetup.plantoid.vote(proposalId,1);
        assert.equal(tx.logs.length, 1);
        assert.equal(tx.logs[0].event,"WinningProposal");
        //check that the proposer get the funds transfer
        assert.equal(proposerBalance.toNumber()+100,web3.eth.getBalance(proposer).toNumber()+0);

    });


});
