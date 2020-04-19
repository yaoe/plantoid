pragma solidity ^0.5.14;

import "@daostack/infra/contracts/Reputation.sol";
import "@daostack/infra/contracts/VotingMachines/VotingMachineCallbacksInterface.sol";
import "@daostack/infra/contracts/VotingMachines/ProposalExecuteInterface.sol";
import "@daostack/infra/contracts/VotingMachines/GenesisProtocol.sol";
import "@daostack/infra/contracts/VotingMachines/AbsoluteVote.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";




contract Cecil is ProposalExecuteInterface, VotingMachineCallbacksInterface {

    event GotDonation(address _donor, uint256 amount, uint256 _seed);
    event AcceptedDonation(address _donor, uint256 amount, uint256 _seed);
    event Reproducing(uint256 seedCnt);
    event NewProposal(uint256 id, bytes32 pid, address _proposer, string url);
    event VotingProposal(uint256 id, bytes32 pid, address _voter, uint256 _reputation, uint256 _vote);
    event VotingAMProposal(uint256 id, bytes32 pid, address _voter, uint256 _reputation, uint256 _vote);
    event ExecuteProposal(uint256 id, bytes32 pid, int decision, address _proposer, uint256 b4balance, string url);
    event NewVotingMachine(address voteMachine);
    event Execution(bytes32 pid, address addr, int _decision);
    event ApprovedExecution(uint256 id, bytes32 winpid, bytes32 pid);
    event VetoedExecution(uint256 id, bytes32 winpid, bytes32 pid);
    event ReputationOf(address _owner, uint256 rep);
    event NewAMProposal(bytes32 pid, bytes32 winpid);

// NEVER TOUCH
    uint256 public save1;
    //uint256 public save2;

    address public owner;
    address payable public  plantoid;
    address payable public parent;
    uint256 public threshold;

    //list of Seeds
  /*  mapping (uint256 => Seed) public seeds;
    uint256 public seedCnt = 9;

    //mapping between proposal to seed index
    mapping (bytes32=>uint256) public pid2id;
*/

// Variables formely assigned to Seed's
    uint256 public weiRaised;
    Reputation public reputation;
    uint256 public nProposals;
    bytes32 public winningProposal;  // the pid of the winningProposal
    bytes32 public winpid;            // the pid of winningProposal for the AM voting machine
    mapping(bytes32=>Proposal) public proposals;
    mapping(bytes32=>bytes32) public pid2AMpid;


    //list of the current administrators of the Plantoid
    address[] public administrators;
    Reputation public adminRep;


// GENESIS PROTOCOL VARIABLES

    address public hcVoteMachine;
    bytes32 public genesisParams;
    bytes32 public orgHash;

    uint256[11] public genesisProtocolParams;


// ABSOLUTE MAJORITY VM
    address public amVoteMachine;
    bytes32 public amParams;
    uint256 private constant TOTAL_AM_REP_SUPPLY = 1000;//cannot be less than 100
    //bytes32 public amOrgHash;



// TILL HERE

    //enum Phase { Capitalisation, Mating, Hiring, Finish }
    //Using "status" instead:
    // - 0: Collecting money
    // - 1: Bidding and Voting
    // - 2: Potential Winner awaiting approval
    // - 3: Approved Winner

    modifier ifStatus (bytes32 _pid, uint256 _status) {
        require(proposals[_pid].status == _status);
        _;
    }

    modifier onlyVotingMachine() {
        require((msg.sender == hcVoteMachine || msg.sender == amVoteMachine), "only VotingMachine");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    struct Proposal {
        bytes32 id;
        address payable proposer;
        string url;
        uint256 block;
        int decision;
        uint256 status;
        uint256 amount;
    }
/*
    struct Seed {
        uint256 id;
        uint256 status;
        uint256 weiRaised;
        Reputation reputation;
        uint256 nProposals;
        bytes32 winningProposal;  // the pid of the winningProposal
        bytes32 winpid;            // the pid of winningProposal for the AM voting machine
        mapping(bytes32=>Proposal) proposals;
        mapping(bytes32=>bytes32) pid2AMpid;
    }
*/


    constructor(address payable _plantoid) public {
        plantoid = _plantoid;
        owner = msg.sender;
    }

    // Simple callback function
    function () external payable {
        fund();
    }

    function mintReputation(uint256 _amount,address _beneficiary) external onlyVotingMachine returns(bool) {
      //  uint256 id = pid2id[pid];
        return reputation.mint(_beneficiary, _amount);
    }

    function burnReputation(uint256 _amount,address _beneficiary) external onlyVotingMachine returns(bool) {
      //  uint256 id = pid2id[pid];
        return reputation.burn(_beneficiary, _amount);
    }

    // FUNCTIONS for ProposalExecuteInterface
    function executeProposal(bytes32 pid, int decision) external onlyVotingMachine  returns(bool) {

      //  uint256 id = pid2id[pid];
        address proposer = proposals[pid].proposer;
        string memory url = proposals[pid].url;


        emit ExecuteProposal(0, pid, decision, proposer, proposer.balance, url);


        if (msg.sender == amVoteMachine) {
              //Founder decision
            require(proposals[pid].status == 2,"require status to be 2");
            if (decision == 1) {
                approveExecution(pid);
                return true;
            } else {
                vetoExecution(pid);
                return false;
              }
        }

          //else:  Contributor decision
        require(proposals[pid].status == 1, "require status to be 1");
        proposals[pid].decision = decision;

        if (decision == 1) {
            proposals[pid].status = 2;
            winningProposal = pid;
            addAMProposal(pid);
        }
    }

    function stakingTokenTransfer(IERC20 _stakingToken, address _beneficiary,uint256 _amount,bytes32)
    external
    onlyVotingMachine
    returns(bool) {
        return _stakingToken.transfer(_beneficiary,_amount);
    }

    function getAdmins() external view returns ( address[] memory){
        return administrators;
    }

    function getAdminBalance( address _admin) external view returns (address, uint256) {
        return (_admin, adminRep.balanceOf(_admin));
    }

    function balanceOfStakingToken(IERC20, bytes32) external view returns(uint256) {
    }

    // FUNCTIONS for GenesisProtocolCallbacksInterface
    function getTotalReputationSupply(bytes32 pid) external view returns(uint256) {
        if (msg.sender == amVoteMachine) {
            return adminRep.totalSupply();
        } else if (msg.sender == hcVoteMachine) {
          //  uint256 id = pid2id[pid];
            return reputation.totalSupplyAt(proposals[pid].block);
        }
    }

    // FUNCTIONS for GenesisProtocolCallbacksInterface
    function getAdminsTotalReputationSupply() external view returns(uint256) {
          return adminRep.totalSupply();
    }

    function reputationOfHC(address _owner, bytes32 pid) view external returns(uint256) {
      //Contributor vote
      //  uint256 id = pid2id[pid];
        return reputation.balanceOfAt(_owner, proposals[pid].block);
    }

    function reputationOf(address _owner, bytes32 pid) view external returns(uint256) {

        if (msg.sender == amVoteMachine) {
          //Founder vote
            return adminRep.balanceOf(_owner);

        } else if (msg.sender == hcVoteMachine) {
          //Contributor vote
          //  uint256 id = pid2id[pid];
            return reputation.balanceOfAt(_owner, proposals[pid].block);
        }
    }


    function init() public {
        genesisProtocolParams = [
        50,     //_queuedVoteRequiredPercentage=50,
        11557600,     //_queuedVotePeriodLimit=60, (in seconds) -- 3 months
        300,     //_boostedVotePeriodLimit=60,
        300,    //_preBoostedVotePeriodLimit
        2000,   //_thresholdConst
        60,     //_quietEndingPeriod
        0,      //_proposingRepReward
        0,      //_votersReputationLossRatio
        1 ether,      //_minimumDaoBounty
        10,      //_daoBountyConst = 15,
        0 //_activationTime
        ];

        reputation = new Reputation();
    }

    function setHCVotingMachine(address _voteM) public onlyOwner {
        require(hcVoteMachine == address(0));
        hcVoteMachine = _voteM;
        emit NewVotingMachine(hcVoteMachine);
        genesisParams = GenesisProtocol(hcVoteMachine).setParameters(genesisProtocolParams, address(this));
        //orgHash = keccak256(abi.encodePacked(genesisParams, IntVoteInterface(hcVoteMachine), address(this)));
    }

    function setAMVotingMachine(address _voteM, address[] memory _owners) public onlyOwner {
        require(amVoteMachine == address(0));
        amVoteMachine = _voteM;
        emit NewVotingMachine(amVoteMachine);
        amParams = AbsoluteVote(amVoteMachine).setParameters(50, address(this));
        //amOrgHash = keccak256(abi.encodePacked(amParams, IntVoteInterface(amVoteMachine), address(this)));

        adminRep = new Reputation();
        // Increase the reputation of the donor (for that particular Seed)
        for (uint256 i = 0; i < _owners.length; i++) {
            administrators.push(_owners[i]);
            adminRep.mint(_owners[i], TOTAL_AM_REP_SUPPLY/_owners.length);
        }
    }

    /*function getSeed(uint256 _id)
        public
        view
        returns(uint256 status,
                uint256 weis,
                address reputation,
                uint256 nProps,
                bytes32 winner)
    {
        Seed storage seed = seeds[_id];
        return (seed.status, seed.weiRaised, address(seed.reputation), seed.nProposals, seed.winningProposal);
    }
*/

    function getWinpid() public view returns (bytes32, bytes32) {
        bytes32 _winpid = winpid;
        return (winningProposal, _winpid);
    }

    function getAMpid(bytes32 _pid) public view returns (bytes32) {
      bytes32 ampid = pid2AMpid[_pid];
      return ampid;
    }

// this function is called when a user submits a new proposal from the interface
    function addProposal(string memory _url, uint256 _amount) public { //ifStatus(_id, 1) {
      //  Seed storage currSeed = seeds[_id]; // try with 'memory' instead of 'storage'
        Proposal memory newprop;
        newprop.id = GenesisProtocol(hcVoteMachine).propose(2, genesisParams, msg.sender, address(0));

        newprop.proposer = msg.sender;
        newprop.url = _url;
        newprop.amount = _amount;
        newprop.block = block.number;
        newprop.status = 1;

        proposals[newprop.id] = newprop;
        nProposals++;
        emit NewProposal(0, newprop.id, msg.sender, _url);
        //add the pid to the pid2id arrays (for the callback interface functions)
      //  pid2id[newprop.id] = _id;
    }

//this function is called when a submitted proposal is approved by the Contributor's reputation chamber
    function addAMProposal(bytes32 _pid) public ifStatus(_pid, 2) {
  //      Seed storage currSeed = seeds[_id]; // try with 'memory' instead of 'storage'

        winpid = AbsoluteVote(amVoteMachine).propose(2, amParams, msg.sender, address(0));
        pid2AMpid[_pid] = winpid;

        emit NewAMProposal(_pid, winpid);
        //add the pid to the pid2id arrays (for the callback interface functions)
        //pid2id[currSeed.winpid] = _id;

    }

    function voteProposal(bytes32 _pid, uint256 _vote) public { //ifStatus(_id, 1) {

        //Seed storage currSeed = seeds[pid2id[_pid]];
        GenesisProtocol(hcVoteMachine).vote(_pid, _vote, 0, msg.sender);
        emit VotingProposal(0,
                            _pid,
                            msg.sender,
                            reputation.balanceOfAt(msg.sender, proposals[_pid].block),
                            _vote);
    }

    function voteAMProposal(bytes32 _pid, uint256 _vote) public ifStatus(_pid, 2) {

        AbsoluteVote(amVoteMachine).vote(_pid, _vote, 0, msg.sender);
        emit VotingAMProposal(0, _pid, msg.sender, adminRep.balanceOf(msg.sender), _vote);
    }

    function getProposal(bytes32 _pid) public view returns(bytes32 pid, address from, string memory url) {
        from = proposals[_pid].proposer;
        url = proposals[_pid].url;
        pid = proposals[_pid].id;
    }

    // External fund function
    function fund() public payable {
        uint256 donation = msg.value;
        // Log that the Plantoid received a new donation
        emit GotDonation(msg.sender, msg.value, 0);

        reputation.mint(msg.sender, donation);

        // Increase the amount of weiRaised (for that particular Seed)
          weiRaised += donation;

          emit AcceptedDonation(msg.sender, donation, 0);

  //      while (funds > 0) {
  //          funds = _fund(funds);
  //      }
    }

    function approveExecution(bytes32 _pid) public {
         //require(msg.sender == artist);
        //uint256 id = pid2id[_pid];
        require(winningProposal != 0, "require winning proposal");
        require(winpid == _pid, "require _pid is winningProposal");
        require(proposals[_pid].status == 2, "requiring status == 2");

        proposals[_pid].status = 3;

        uint256 portion = proposals[_pid].amount/10;
        plantoid.transfer(portion);
      //  parent.transfer(portion);
        proposals[_pid].proposer.transfer(proposals[_pid].amount - portion);

        emit ApprovedExecution(0, _pid, winningProposal);
    }

    function vetoExecution(bytes32 _pid) public {
          //require(msg.sender == artist);
      //  uint256 id = pid2id[_pid];
        require(winpid == _pid, "required _pid is winnigProposal");
        require(proposals[_pid].status == 2, "requiring status == 2");

        emit VetoedExecution(0, _pid, winningProposal);

        proposals[_pid].status = 1;
        winningProposal = 0;
        winpid = 0;
        proposals[_pid].decision = 2;
     }

    // Internal fund function
  /*  function _fund(uint256 donation) internal { //returns(uint256 overflow) {

    //    uint256 donation;
    //    Seed storage currSeed = seeds[seedCnt];

      // Check if there is an overflow
    //    if (currSeed.weiRaised + _donation > threshold) {
    //        overflow = currSeed.weiRaised + _donation - threshold;
    //        donation = threshold - currSeed.weiRaised;
    //    } else {
    //        donation = _donation;
    //        emit AcceptedDonation(msg.sender, donation, 0);
    //    }


      // instantiate a new Reputation system (DAOstack) if one doesnt exist
      //  if ((reputation) == Reputation(0)) {
      //      reputation = new Reputation();
      //  }
      // Increase the reputation of the donor (for that particular Seed)

        reputation.mint(msg.sender, donation);

        // Increase the amount of weiRaised (for that particular Seed)
          weiRaised += donation;

          emit AcceptedDonation(msg.sender, donation, 0);


        if (currSeed.weiRaised >= threshold) {
            emit Reproducing(seedCnt);
            // change status of the seeds
            seeds[seedCnt].status = 1;
            // Create new Seed:
            seedCnt++;
            seeds[seedCnt].id = seedCnt;
            seeds[seedCnt].reputation = new Reputation();
        }


    }  */

}
