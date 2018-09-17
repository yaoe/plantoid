pragma solidity ^0.4.19;

import "@daostack/infra/contracts/Reputation.sol";
import "@daostack/infra/contracts/VotingMachines/GenesisProtocol.sol";
import "openzeppelin-solidity/contracts/token/ERC827/ERC827Token.sol";



contract Upgradable is GenesisProtocolExecuteInterface {

    uint32 public val = 5;

    function test(uint32 v) public returns(uint32, uint256) {
        val = v;
        return (val, address(this).balance);
    }

    function getTest() public view returns (uint32) {
        return val;
    }
}

contract Proxy  {

    address public ownerX;
    address public _implementation;

    address public artist;
    uint public threshold;

    uint[14] public genesisProtocolParams;



    function Proxy(address _owner, address _artist, uint _threshold) public {
        ownerX = _owner;
        artist = _artist;
        threshold = _threshold;

    }


    modifier onlyOwnerX() {
        require(msg.sender == ownerX);
        _;
    }

    event Upgraded(address indexed implementation);
    event FallingBack(address indexed implemantion, bytes data);





    function implementation() public view returns (address) {
        return _implementation;
    }

    function upgradeTo(address impl) public onlyOwnerX {
        require(_implementation != impl);
        _implementation = impl;
        emit Upgraded(impl);
// this is a trick to call a constructor in the case of a delegated contract
//        Plantoid(address(this)).setup();
    }

    function () public payable {
        // data = msg.data
        // sender = msg.sender
        // myGovContract.call(sender, data)

        // if (governanceContract.shouldCall(hash(msg.data)) {
        //     call(msg.data)
        // }

        bytes memory data = msg.data;
        address _impl = implementation();
        require(_impl != address(0));

        emit FallingBack(_impl, data);

        assembly {
            let result := delegatecall(gas, _impl, add(data, 0x20), mload(data), 0, 0)
            let size := returndatasize
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

}

contract Plantoid is GenesisProtocolExecuteInterface, GenesisProtocolCallbacksInterface {

    event GotDonation(address _donor, uint amount);
    event AcceptedDonation(address _donor, uint amount);
    event DebugDonation(address _donor, uint amount, uint _threshold, uint _overflow);
    event Reproducing(uint seedCnt);
    event NewProposal(uint id, bytes32 pid, address _proposer, string url);
    event VotingProposal(uint id, bytes32 pid, address _voter, uint _reputation, bool _voted);
    event VotedProposal(uint id, bytes32 pid, address _voter);
    event WinningProposal(uint id, bytes32 pid, address _proposer);
    event NewVotingMachine(address voteMachine);
    event Execution(bytes32 pid, address addr, int _decision);
    event ReputationOf(address _owner, uint rep);


// NEVER TOUCH
    uint public save1;
    uint public save2;

    address public artist;
    uint public threshold;

    uint[14] public genesisProtocolParams;

    uint public weiRaised;
    uint public seedCnt;

    mapping (uint => Seed) public seeds;
// TILL HERE

    //enum Phase { Capitalisation, Mating, Hiring, Finish }
    //Using "status" instead:
    // - 0: Collecting money
    // - 1: Bidding and Voting
    // - 2: Hiring and Milestones
    // - 3: Reproduction complete
    modifier ifStatus (uint _id, uint _status) {
        require(seeds[_id].status == _status);
        _;
    }

    struct Proposal {
        bytes32 id;
        address proposer;
        string url;
        uint votes;
        uint block;
    }

    struct Seed {
        uint id;
        uint status;
     //   mapping (address => uint) reputation;
        Reputation reputation;
        mapping(bytes32=>Proposal) proposals;
        uint nProposals;
        mapping (address => bool) voters;
        uint totVotes;
    }

    //mapping between proposal to seed index
    mapping (bytes32=>uint) public pid2id;

// GENESIS PROTOCOL VARIABLES

    address public VoteMachine;
    bytes32 public genesisParams;
    bytes32 public orgHash;


    function init() public {
      genesisProtocolParams = [
      50,     //_preBoostedVoteRequiredPercentage=50,
      1800,     //_preBoostedVotePeriodLimit=60, (in seconds)
      60,     //_boostedVotePeriodLimit=60,
      1,      //_thresholdConstA=1,
      1,      //_thresholdConstB=1,
      0,      //_minimumStakingFee=0,
      0,      //_quietEndingPeriod=0
      60000,      //_proposingRepRewardConstA=60000
      1000,      //_proposingRepRewardConstB=1000
      2,      //_stakerFeeRatioForVoters=10,
      0,      //_votersReputationLossRatio=10
      0,      //_votersGainRepRatioFromLostRep=80
      3,      //_daoBountyConst = 15,
      0      //_daoBountyLimit = 10
      ];
    }

    function setVotingMachine(address voteM) public { //onlyOwnerX {
        require(VoteMachine != voteM);
        VoteMachine = voteM;
        emit NewVotingMachine(VoteMachine);

        //require(orgHash == bytes32(0));
        genesisParams = GenesisProtocol(VoteMachine).setParameters(genesisProtocolParams, address(this));
        orgHash = keccak256(abi.encodePacked(genesisParams, IntVoteInterface(VoteMachine), address(this)));

    }





    // Simple callback function
    function () public payable {
        fund();
    }

    function getBalance() public constant returns(uint256) {
        return address(this).balance;
    }

    function getSeed(uint id) public constant returns(uint _id, uint _status, uint _weis, uint _thres) {
        _status = seeds[id].status;
        _thres = threshold;
        _id = id;
        if (_status == 1) { _weis = threshold; } else { _weis = weiRaised; }
    }

    function addProposal(uint256 id, string url) public ifStatus(id, 1) {
        Seed storage currSeed = seeds[id]; // try with 'memory' instead of 'storage'
        Proposal memory newprop;

        newprop.id = GenesisProtocol(VoteMachine).propose(2, genesisParams, msg.sender);
        //function propose(uint _numOfChoices, bytes32 _paramsHash, address _proposer)

        newprop.proposer = msg.sender;
        newprop.url = url;
        newprop.block = block.number;

        currSeed.proposals[newprop.id] = newprop;
        currSeed.nProposals++;
        emit NewProposal(id, newprop.id, msg.sender, url);

        //add the pid to the pid2id arrays (for the callback interface functions)
        pid2id[newprop.id] = id;

    }




    function voteProposal(uint256 id, bytes32 pid) public ifStatus(id, 1) {

        GenesisProtocol(VoteMachine).vote(pid, 1, msg.sender);
/*        Seed storage currSeed = seeds[id];


        emit VotingProposal(id, pid, msg.sender, currSeed.reputation.reputationOf(msg.sender), currSeed.voters[msg.sender]);


        assert(currSeed.reputation.reputationOf(msg.sender) != 0);
        assert(!currSeed.voters[msg.sender]);

        emit VotedProposal(id, pid, msg.sender);

        currSeed.proposals[pid].votes += currSeed.reputation.reputationOf(msg.sender);
        currSeed.voters[msg.sender] = true;
        currSeed.totVotes += currSeed.reputation.reputationOf(msg.sender);

        // check if we got a winner
        // Absolute majority
        if (currSeed.proposals[pid].votes > threshold / 2) {
            emit WinningProposal(id, pid, currSeed.proposals[pid].proposer);
            currSeed.proposals[pid].proposer.transfer(threshold);
        }
*/
    }

    function nProposals(uint256 id) public constant returns (uint _id, uint n) {
        n = seeds[id].nProposals;
        _id = id;
    }

    function getProposal(uint256 id, bytes32 pid) public constant returns(uint _id, bytes32 _pid, address _from, string _url, uint _votes) {
        _from = seeds[id].proposals[pid].proposer;
        _url = seeds[id].proposals[pid].url;
        _votes = seeds[id].proposals[pid].votes;
        _pid = seeds[id].proposals[pid].id;
        _id = id;
    }

    // External fund function
    function fund() public payable {
    //    require(msg.value > 0);

        uint funds = msg.value;

        // Log that the Plantoid received a new donation
        emit GotDonation(msg.sender, msg.value);

        while (funds > 0) {
            funds = _fund(funds);
        }


    }

    // Internal fund function
    function _fund(uint _donation) internal returns(uint overflow) {

        uint donation;

      // Check if there is an overflow
        if (weiRaised + _donation > threshold) {
            overflow = weiRaised + _donation - threshold;
            donation = threshold - weiRaised;

            emit DebugDonation(msg.sender, _donation, threshold, overflow);

            //emit DebugDonation(0x01, donation);

        } else {
            donation = _donation;

           emit AcceptedDonation(msg.sender, donation);
        }
      // Increase the amount of weiRaised (for that particular Seed)
        weiRaised += donation;


      // instantiate a new Reputation system (DAOstack) if one doesnt exist
      if((seeds[seedCnt].reputation) == Reputation(0)) { seeds[seedCnt].reputation = new Reputation(); }
      // Increase the reputation of the donor (for that particular Seed)
         seeds[seedCnt].reputation.mint(msg.sender, donation);

        if (weiRaised >= threshold) {
            emit Reproducing(seedCnt);
            // change status of the seeds
            seeds[seedCnt].status = 1;

            // Create new Seed:
            seedCnt++;
            //Seed memory newseed; //= Seed(seedCnt, 0, new Proposal[](0)); // 'reputation' member doesn't count
            seeds[seedCnt].id = seedCnt;
            seeds[seedCnt].reputation = new Reputation();
            weiRaised = 0;
            // Feed the new seed if there was an overflow of donations
            // (overflow != 0) {  _fund(overflow); }
        }
    }

// FUNCTIONS for ExecutableInterface

    function execute(bytes32, address , int) public returns(bool) {
    }

// FUNCTIONS for GenesisProtocolCallbacksInterface

    function getTotalReputationSupply(bytes32 pid) external view returns(uint256) {
        uint id = pid2id[pid];
        return seeds[id].reputation.totalSupply();
    }

    function mintReputation(uint _amount,address _beneficiary,bytes32 pid) external returns(bool) {
      uint id = pid2id[pid];
      require(msg.sender == VoteMachine);
      return seeds[id].reputation.mint(_beneficiary,_amount);
    }

    function burnReputation(uint _amount,address _beneficiary,bytes32 pid) external returns(bool) {
      uint id = pid2id[pid];
      require(msg.sender == VoteMachine);
      return seeds[id].reputation.burn(_beneficiary,_amount);
    }

    function reputationOf(address _owner,bytes32 pid) view external returns(uint) {
        uint id = pid2id[pid];
        uint rep = seeds[id].reputation.balanceOfAt(_owner, seeds[id].proposals[pid].block);
     //   emit ReputationOf(_owner, rep);
        return rep;
    }

    function stakingTokenTransfer(StandardToken _stakingToken, address _beneficiary,uint _amount,bytes32) external returns(bool) {
      require(msg.sender == VoteMachine);
      ERC827Token stakingTok = ERC827Token(GenesisProtocol(VoteMachine).stakingToken());
      return stakingTok.transfer(_beneficiary,_amount);
    }

    function executeProposal(bytes32 pid,int _decision) external returns(bool) {
      require(msg.sender == VoteMachine);
      emit Execution(pid, 0, _decision);
      return execute(pid, 0, _decision);
    }



}
