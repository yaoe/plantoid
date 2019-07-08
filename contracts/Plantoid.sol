pragma solidity ^0.5.4;

import "@daostack/infra/contracts/Reputation.sol";
import "@daostack/infra/contracts/VotingMachines/VotingMachineCallbacksInterface.sol";
import "@daostack/infra/contracts/VotingMachines/ProposalExecuteInterface.sol";
import "@daostack/infra/contracts/VotingMachines/GenesisProtocol.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";


contract Proxy {

    address public _implementation;

    address public owner;
    address payable public artist;
    address payable public parent;
    uint256 public threshold;

    uint256[11] public genesisProtocolParams;

    event OwnershipTransferred(
      address indexed previousOwner,
      address indexed newOwner
    );

    constructor(address payable _artist, address payable _parent, uint256 _threshold) public {
        artist = _artist;
        parent = _parent;
        threshold = _threshold;
        owner = msg.sender;
    }

    event Upgraded(address indexed implementation);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }


    function implementation() public view returns (address) {
        return _implementation;
    }

    function upgradeTo(address impl) public onlyOwner {
        require(_implementation != impl);
        _implementation = impl;
        emit Upgraded(impl);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
      require(_newOwner != address(0));
      emit OwnershipTransferred(owner, _newOwner);
      owner = _newOwner;
    }

    function () external payable {
        bytes memory data = msg.data;
        address _impl = implementation();
        require(_impl != address(0));

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

contract Plantoid is ProposalExecuteInterface, VotingMachineCallbacksInterface {

    event GotDonation(address _donor, uint256 amount, uint256 _seed);
    event AcceptedDonation(address _donor, uint256 amount, uint256 _seed);
    event Reproducing(uint256 seedCnt);
    event NewProposal(uint256 id, bytes32 pid, address _proposer, string url);
    event VotingProposal(uint256 id, bytes32 pid, address _voter, uint256 _reputation, uint256 _vote);
    event ExecuteProposal(uint256 id, bytes32 pid, int decision, address _proposer, uint256 b4balance);
    event NewVotingMachine(address voteMachine);
    event Execution(bytes32 pid, address addr, int _decision);
    event ApprovedExecution(bytes32 pid, address proposer);
    event ReputationOf(address _owner, uint256 rep);


// NEVER TOUCH
    uint256 public save1;
    //uint256 public save2;

    address public owner;
    address payable public  artist;
    address payable public parent;
    uint256 public threshold;

    uint256[11] public genesisProtocolParams;

    uint256 public seedCnt = 9;

    //mapping between proposal to seed index
    mapping (bytes32=>uint256) public pid2id;

// GENESIS PROTOCOL VARIABLES

    address public voteMachine;
    bytes32 public genesisParams;
    bytes32 public orgHash;

    mapping (uint256 => Seed) public seeds;
// TILL HERE

    //enum Phase { Capitalisation, Mating, Hiring, Finish }
    //Using "status" instead:
    // - 0: Collecting money
    // - 1: Bidding and Voting
    // - 2: Hiring and Milestones
    // - 3: Reproduction complete
    modifier ifStatus (uint256 _id, uint256 _status) {
        require(seeds[_id].status == _status);
        _;
    }

    modifier onlyVotingMachine() {
        require(msg.sender == voteMachine,"only VotingMachine");
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
    }

    struct Seed {
        uint256 id;
        uint256 status;
        uint256 weiRaised;
        Reputation reputation;
        uint256 nProposals;
        bytes32 winningProposal;
        mapping(bytes32=>Proposal) proposals;
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
    }

    function setVotingMachine(address _voteM) public onlyOwner {
        require(voteMachine == address(0));
        voteMachine = _voteM;
        emit NewVotingMachine(voteMachine);
        genesisParams = GenesisProtocol(voteMachine).setParameters(genesisProtocolParams, address(this));
        orgHash = keccak256(abi.encodePacked(genesisParams, IntVoteInterface(voteMachine), address(this)));
    }

    // Simple callback function
    function () external payable {
        fund();
    }

    function getSeed(uint256 _id)
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

    function addProposal(uint256 _id, string memory _url) public ifStatus(_id, 1) {
        Seed storage currSeed = seeds[_id]; // try with 'memory' instead of 'storage'
        Proposal memory newprop;
        newprop.id = GenesisProtocol(voteMachine).propose(2, genesisParams, msg.sender, address(0));

        newprop.proposer = msg.sender;
        newprop.url = _url;
        newprop.block = block.number;

        currSeed.proposals[newprop.id] = newprop;
        currSeed.nProposals++;
        emit NewProposal(_id, newprop.id, msg.sender, _url);
        //add the pid to the pid2id arrays (for the callback interface functions)
        pid2id[newprop.id] = _id;
    }

    function voteProposal(uint256 _id, bytes32 _pid, uint256 _vote) public ifStatus(_id, 1) {

        Seed storage currSeed = seeds[pid2id[_pid]];
        GenesisProtocol(voteMachine).vote(_pid, _vote, 0, msg.sender);
        emit VotingProposal(_id, _pid, msg.sender, currSeed.reputation.balanceOfAt(msg.sender,currSeed.proposals[_pid].block), _vote);
    }

    function getProposal(uint256 _id, bytes32 _pid) public view returns(bytes32 pid, address from, string memory url) {
        from = seeds[_id].proposals[_pid].proposer;
        url = seeds[_id].proposals[_pid].url;
        pid = seeds[_id].proposals[_pid].id;
    }

    // External fund function
    function fund() public payable {
        uint256 funds = msg.value;
        // Log that the Plantoid received a new donation
        emit GotDonation(msg.sender, msg.value, seedCnt);

        while (funds > 0) {
            funds = _fund(funds);
        }
    }

    // Internal fund function
    function _fund(uint256 _donation) internal returns(uint256 overflow) {

        uint256 donation;
        Seed storage currSeed = seeds[seedCnt];

      // Check if there is an overflow
        if (currSeed.weiRaised + _donation > threshold) {
            overflow = currSeed.weiRaised + _donation - threshold;
            donation = threshold - currSeed.weiRaised;
        } else {
            donation = _donation;

           emit AcceptedDonation(msg.sender, donation, seedCnt);
        }
      // Increase the amount of weiRaised (for that particular Seed)
        currSeed.weiRaised += donation;

      // instantiate a new Reputation system (DAOstack) if one doesnt exist
       if((seeds[seedCnt].reputation) == Reputation(0)) {
          seeds[seedCnt].reputation = new Reputation();
       }
      // Increase the reputation of the donor (for that particular Seed)
       seeds[seedCnt].reputation.mint(msg.sender, donation);

      if (currSeed.weiRaised >= threshold) {
          emit Reproducing(seedCnt);
            // change status of the seeds
          seeds[seedCnt].status = 1;
            // Create new Seed:
          seedCnt++;
          seeds[seedCnt].id = seedCnt;
          seeds[seedCnt].reputation = new Reputation();
        }
    }

// FUNCTIONS for ProposalExecuteInterface

    function executeProposal(bytes32 pid, int decision) external onlyVotingMachine  returns(bool) {

      uint256 id = pid2id[pid];

      require(seeds[id].status == 1,"require status to be 1");

      if(decision == 1) {
          seeds[id].status = 2;
          seeds[id].winningProposal = pid;
        }

        address proposer = seeds[id].proposals[pid].proposer;
        emit ExecuteProposal(id, pid, decision, proposer, proposer.balance );

    }

     function approveExecution(bytes32 _pid) public {
         require(msg.sender == artist);
         uint256 id = pid2id[_pid];
         require(seeds[id].winningProposal != 0,"require winning proposal");
         require(seeds[id].winningProposal == _pid, "require _pid is winningProposal");
         require(seeds[id].status == 2, "requiring status == 2");
         seeds[id].status = 3;

         uint256 portion = threshold/10;
         artist.transfer(portion);
         parent.transfer(portion);
         seeds[id].proposals[_pid].proposer.transfer(threshold - portion*2);

         emit ApprovedExecution(_pid, seeds[id].proposals[_pid].proposer);

     }

// FUNCTIONS for GenesisProtocolCallbacksInterface

    function getTotalReputationSupply(bytes32 pid) external view returns(uint256) {
        uint256 id = pid2id[pid];
        return seeds[id].reputation.totalSupplyAt(seeds[id].proposals[pid].block);
    }

    function mintReputation(uint256 _amount,address _beneficiary,bytes32 pid) external onlyVotingMachine returns(bool) {
      uint256 id = pid2id[pid];
      return seeds[id].reputation.mint(_beneficiary,_amount);
    }

    function burnReputation(uint256 _amount,address _beneficiary,bytes32 pid) external onlyVotingMachine returns(bool) {
      uint256 id = pid2id[pid];
      return seeds[id].reputation.burn(_beneficiary,_amount);
    }

    function reputationOf(address _owner,bytes32 pid) view external returns(uint256) {
        uint256 id = pid2id[pid];
        uint256 rep = seeds[id].reputation.balanceOfAt(_owner, seeds[id].proposals[pid].block);
        return rep;
    }

    function stakingTokenTransfer(IERC20 _stakingToken, address _beneficiary,uint256 _amount,bytes32) external onlyVotingMachine returns(bool) {
      return _stakingToken.transfer(_beneficiary,_amount);
    }

    function balanceOfStakingToken(IERC20, bytes32) external view returns(uint256) {
    }

}
