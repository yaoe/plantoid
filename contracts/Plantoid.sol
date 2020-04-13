pragma solidity ^0.5.17;

import "@daostack/infra/contracts/Reputation.sol";
import "@daostack/infra/contracts/VotingMachines/VotingMachineCallbacksInterface.sol";
import "@daostack/infra/contracts/VotingMachines/ProposalExecuteInterface.sol";
import "@daostack/infra/contracts/VotingMachines/GenesisProtocol.sol";
import "@daostack/infra/contracts/VotingMachines/AbsoluteVote.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";


contract Plantoid is ProposalExecuteInterface, VotingMachineCallbacksInterface, Initializable {

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
    event NewAMProposal(uint256 id, bytes32 winpid);
    event UpgradeProposal(bytes32 indexed _pid);


    address payable public artist;
    address payable public parent;
    uint256 public threshold;
    //mapping between proposal to new implemntation address
    mapping (bytes32 => address) public upgradedProxyProposals;
    //list of Seeds
    mapping (uint256 => Seed) public seeds;
    uint256 public seedCnt;

    //mapping between proposal to seed index
    mapping (bytes32=>uint256) public pid2id;


    //list of the current administrators of the Plantoid
    address[] public administrators;
    Reputation public adminRep;


// GENESIS PROTOCOL VARIABLES

    address public hcVotingMachine;
    address public votingMachine;
    bytes32 public genesisParams;

// ABSOLUTE MAJORITY VM
    address public amVotingMachine;
    bytes32 public amParams;
    uint256 private constant TOTAL_AM_REP_SUPPLY = 1000;//cannot be less than 100
// TILL HERE

    //enum Phase { Capitalisation, Mating, Hiring, Finish }
    //Using "status" instead:
    // - 0: Collecting money
    // - 1: Bidding and Voting
    // - 2: Potential Winner awaiting approval
    // - 3: Approved Winner
    modifier ifStatus (uint256 _id, uint256 _status) {
        require(seeds[_id].status == _status);
        _;
    }

    modifier onlyVotingMachine() {
        require((msg.sender == hcVotingMachine || msg.sender == amVotingMachine), "only VotingMachine");
        _;
    }

    struct Proposal {
        bytes32 id;
        address payable proposer;
        string url;
        uint256 block;
        int decision;
    }

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

    // Simple callback function
    function () external payable {
        fund();
    }

    /**
    * @dev initialize
    */
    function initialize(address payable _artist,
                        address payable _parent,
                        uint256 _threshold,
                        address _amVotingMachine,
                        address _hcVotingMachine,
                        address[] calldata _owners)
    external
    initializer {
        artist = _artist;
        parent = _parent;
        threshold = _threshold;
        amVotingMachine = _amVotingMachine;
        hcVotingMachine = _hcVotingMachine;
        uint256[11] memory genesisProtocolParams = [
            uint256(50),     //_queuedVoteRequiredPercentage=50,
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
        genesisParams = GenesisProtocol(hcVotingMachine).setParameters(genesisProtocolParams, address(this));
        amParams = AbsoluteVote(amVotingMachine).setParameters(50, address(this));
        adminRep = new Reputation();
        // Increase the reputation of the donor (for that particular Seed)
        for (uint256 i = 0; i < _owners.length; i++) {
            administrators.push(_owners[i]);
            adminRep.mint(_owners[i], TOTAL_AM_REP_SUPPLY/_owners.length);
        }
    }

    function mintReputation(uint256 _amount, address _beneficiary, bytes32 pid)
    external
    onlyVotingMachine
    returns(bool) {
        uint256 id = pid2id[pid];
        return seeds[id].reputation.mint(_beneficiary, _amount);
    }

    function burnReputation(uint256 _amount, address _beneficiary, bytes32 pid)
    external
    onlyVotingMachine
    returns(bool) {
        uint256 id = pid2id[pid];
        return seeds[id].reputation.burn(_beneficiary, _amount);
    }

    // FUNCTIONS for ProposalExecuteInterface
    function executeProposal(bytes32 pid, int decision) external onlyVotingMachine  returns(bool) {

        uint256 id = pid2id[pid];
        address proposer = seeds[id].proposals[pid].proposer;
        string memory url = seeds[id].proposals[pid].url;
        emit ExecuteProposal(id, pid, decision, proposer, proposer.balance, url);

        if (msg.sender == amVotingMachine) {
            if (upgradedProxyProposals[pid] != address(0)) {
                address newImplemntation = upgradedProxyProposals[pid];
                upgradedProxyProposals[pid] = address(0);
                if (decision == 1) {
                    (bool success, ) =
                    // solhint-disable-next-line avoid-low-level-calls
                    address(this).call(abi.encodeWithSignature("upgradeTo(address)", newImplemntation));
                    require(success, "upgrade platoind failed");
                }
                return true;
            } else {
            //Founder decision
                require(seeds[id].status == 2, "require status to be 2");
                if (decision == 1) {
                    approveExecution(pid);
                    return true;
                } else {
                    vetoExecution(pid);
                    return false;
                }
            }
        }

          //else:  Contributor decision
        require(seeds[id].status == 1, "require status to be 1");
        seeds[id].proposals[pid].decision = decision;

        if (decision == 1) {
            seeds[id].status = 2;
            seeds[id].winningProposal = pid;
            addAMProposal(id);
        }
    }

    function stakingTokenTransfer(IERC20 _stakingToken, address _beneficiary, uint256 _amount, bytes32)
    external
    onlyVotingMachine
    returns(bool) {
        return _stakingToken.transfer(_beneficiary, _amount);
    }

    function upgradedProxyProposal(address _newImplemetation)
    external {
        bytes32 pid = AbsoluteVote(amVotingMachine).propose(2, amParams, msg.sender, address(0));
        upgradedProxyProposals[pid] = _newImplemetation;
        emit UpgradeProposal(pid);
    }

    function getAdmins() external view returns ( address[] memory) {
        return administrators;
    }

    function getAdminBalance( address _admin) external view returns (address, uint256) {
        return (_admin, adminRep.balanceOf(_admin));
    }

    // solhint-disable-next-line no-empty-blocks
    function balanceOfStakingToken(IERC20, bytes32) external view returns(uint256) {
    }

    // FUNCTIONS for GenesisProtocolCallbacksInterface
    function getTotalReputationSupply(bytes32 pid) external view returns(uint256) {
        if (msg.sender == amVotingMachine) {
            return adminRep.totalSupply();
        } else if (msg.sender == hcVotingMachine) {
            uint256 id = pid2id[pid];
            return seeds[id].reputation.totalSupplyAt(seeds[id].proposals[pid].block);
        }
    }

    // FUNCTIONS for GenesisProtocolCallbacksInterface
    function getAdminsTotalReputationSupply() external view returns(uint256) {
        return adminRep.totalSupply();
    }

    function reputationOfHC(address _owner, bytes32 pid) external view returns(uint256) {
      //Contributor vote
        uint256 id = pid2id[pid];
        return seeds[id].reputation.balanceOfAt(_owner, seeds[id].proposals[pid].block);
    }

    function reputationOf(address _owner, bytes32 pid) external view returns(uint256) {

        if (msg.sender == amVotingMachine) {
          //Founder vote
            return adminRep.balanceOf(_owner);

        } else if (msg.sender == hcVotingMachine) {
          //Contributor vote
            uint256 id = pid2id[pid];
            return seeds[id].reputation.balanceOfAt(_owner, seeds[id].proposals[pid].block);
        }
    }

// this function is called when a user submits a new proposal from the interface
    function addProposal(uint256 _id, string memory _url) public ifStatus(_id, 1) {
        Seed storage currSeed = seeds[_id]; // try with 'memory' instead of 'storage'
        Proposal memory newprop;
        newprop.id = GenesisProtocol(hcVotingMachine).propose(2, genesisParams, msg.sender, address(0));

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
        GenesisProtocol(hcVotingMachine).vote(_pid, _vote, 0, msg.sender);
        emit VotingProposal(_id,
                            _pid,
                            msg.sender,
                            currSeed.reputation.balanceOfAt(msg.sender, currSeed.proposals[_pid].block),
                            _vote);
    }

    function voteAMProposal(uint256 _id, bytes32 _pid, uint256 _vote) public ifStatus(_id, 2) {

        AbsoluteVote(amVotingMachine).vote(_pid, _vote, 0, msg.sender);
        emit VotingAMProposal(_id, _pid, msg.sender, adminRep.balanceOf(msg.sender), _vote);
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

    function approveExecution(bytes32 _pid) public {
         //require(msg.sender == artist);
        uint256 id = pid2id[_pid];
        require(seeds[id].winningProposal != 0, "require winning proposal");
        require(seeds[id].winpid == _pid, "require _pid is winningProposal");
        require(seeds[id].status == 2, "requiring status == 2");

        seeds[id].status = 3;

        uint256 portion = threshold/10;
        artist.transfer(portion);
        parent.transfer(portion);
        seeds[id].proposals[_pid].proposer.transfer(threshold - portion*2);

        emit ApprovedExecution(id, _pid, seeds[id].winningProposal);
    }

    function vetoExecution(bytes32 _pid) public {
          //require(msg.sender == artist);
        uint256 id = pid2id[_pid];
        require(seeds[id].winpid == _pid, "required _pid is winnigProposal");
        require(seeds[id].status == 2, "requiring status == 2");

        emit VetoedExecution(id, _pid, seeds[id].winningProposal);

        seeds[id].status = 1;
        seeds[id].winningProposal = 0;
        seeds[id].winpid = 0;
        seeds[id].proposals[_pid].decision = 2;
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

    function getWinpid4Seed(uint256 _id) public view returns (bytes32, bytes32) {
        return (seeds[_id].winningProposal, seeds[_id].winpid);
    }

    function getAMpid4Seed(uint256 _id, bytes32 _pid) public view returns (bytes32) {
        return seeds[_id].pid2AMpid[_pid];
    }

    function getProposal(uint256 _id, bytes32 _pid) public view returns(bytes32 pid, address from, string memory url) {
        from = seeds[_id].proposals[_pid].proposer;
        url = seeds[_id].proposals[_pid].url;
        pid = seeds[_id].proposals[_pid].id;
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
        if ((seeds[seedCnt].reputation) == Reputation(0)) {
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

    //this function is called when a submitted proposal is approved by the Contributor's reputation chamber
    function addAMProposal(uint256 _id) private ifStatus(_id, 2) {
        Seed storage currSeed = seeds[_id]; // try with 'memory' instead of 'storage'

        currSeed.winpid = AbsoluteVote(amVotingMachine).propose(2, amParams, msg.sender, address(0));
        currSeed.pid2AMpid[currSeed.winningProposal] = currSeed.winpid;

        emit NewAMProposal(_id, currSeed.winpid);
        //add the pid to the pid2id arrays (for the callback interface functions)
        pid2id[currSeed.winpid] = _id;
    }

}
