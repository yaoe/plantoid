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
    event NewProposal(uint256 id, bytes32 pid, address _proposer, string url, uint256 amount);
    event VotingProposal(uint256 id, bytes32 pid, address _voter, uint256 _reputation, uint256 _vote);
    event VotingAMProposal(uint256 id, bytes32 pid, address _voter, uint256 _reputation, uint256 _vote);
    event ExecuteProposal(uint256 id, bytes32 pid, int decision, address _proposer, uint256 b4balance, string url);
    event NewVotingMachine(address voteMachine);
    event Execution(bytes32 pid, address addr, int _decision);
    event ApprovedExecution(uint256 id, bytes32 winpid, bytes32 pid);
    event VetoedExecution(uint256 id, bytes32 winpid, bytes32 pid);
    event ReputationOf(address _owner, uint256 rep);
    event NewAMProposal(bytes32 pid, bytes32 winpid);
    event NewRepProposal(bytes32 pid, address receiver, int rep, uint256 typ);


// NEVER TOUCH

    address payable public  beneficiary;

// Variables formely assigned to Seed's
    uint256 public weiRaised;
    Reputation public reputation;
    uint256 public nProposals;
    bytes32 public winningProposal;  // the pid of the winningProposal
    bytes32 public winpid;            // the pid of winningProposal for the AM voting machine
    mapping(bytes32=>Proposal) public proposals;
    mapping(bytes32=>bytes32) public pid2AMpid;

    mapping(bytes32=>RepProposal) public repProposals;


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

// REPUTATION TYPE CONSTANTS
    uint256 private constant ADMIN = 1;
    uint256 private constant CONTRIB = 2;

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


    struct Proposal {
        bytes32 id;
        address payable proposer;
        string url;
        uint256 block;
        int decision;
        uint256 status;
        uint256 amount;
    }

    struct RepProposal {
        bytes32 id;
        int decision;
        address receiver;
        int256 rep;
        uint256 typ; // 1 = ADMIN; 2 = CONTRIB;
    }

    /**
    * @dev initialize
    */
    function initialize(address _amVotingMachine,
                        address _hcVotingMachine,
                        address[] calldata _owners,
                        address payable _beneficiary)
    external
    initializer {
        amVotingMachine = _amVotingMachine;
        hcVotingMachine = _hcVotingMachine;
        beneficiary = _beneficiary;
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

    // Simple callback function
    function () external payable {
        fund();
    }

    function mintReputation(uint256 _amount, address _beneficiary, bytes32) external onlyVotingMachine returns(bool) {

        return reputation.mint(_beneficiary, _amount);
    }

    function burnReputation(uint256 _amount, address _beneficiary, bytes32) external onlyVotingMachine returns(bool) {

        return reputation.burn(_beneficiary, _amount);
    }

    // FUNCTIONS for ProposalExecuteInterface
    function executeProposal(bytes32 pid, int decision) external onlyVotingMachine  returns(bool) {

        if (msg.sender == amVoteMachine) {     //Administrator's decision
            if (repProposals[pid].id != 0) {   // Reputation proposal  (the pid exists in the mapping array)

                Reputation  rep;

                if (decision == 1) {
                    if (repProposals[pid].typ == ADMIN) {
                        rep = adminRep;
                    } else if (repProposals[pid].typ == CONTRIB) { rep = reputation; }

                    if (repProposals[pid].rep > 0) {
                        rep.mint(repProposals[pid].receiver, uint256(repProposals[pid].rep));
                    } else {
                        rep.burn(repProposals[pid].receiver, uint256(-repProposals[pid].rep));
                    }
                  }
                } // end repProposal

          else {                  // AM proposal

            require(proposals[winningProposal].status == 2,"require status to be 2 (in Execute AM Proposal)");

            if (decision == 1) {
                approveExecution(pid);
                return true;

            } else {
                vetoExecution(pid);
                return false;
              }
        }

      } else {    //else:  Contributor decision

        require(proposals[pid].status == 1, "require status to be 1");

        address proposer = proposals[pid].proposer;
        string memory url = proposals[pid].url;

        emit ExecuteProposal(0, pid, decision, proposer, proposer.balance, url);

        proposals[pid].decision = decision;

        if (decision == 1) {
            proposals[pid].status = 2;
            winningProposal = pid;
            addAMProposal(pid);
        }
    }
  }

    function stakingTokenTransfer(IERC20 _stakingToken, address _beneficiary,uint256 _amount,bytes32)
    external onlyVotingMachine returns(bool) {
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

    function isAdmin(address _account) external view returns(bool) {

        uint256 i;
        for (i = 0; i < administrators.length; i++) {
            if (administrators[i] == _account) {
                return true;
            }
        }
        return false;
    }

    // FUNCTIONS for GenesisProtocolCallbacksInterface
    function getTotalReputationSupply(bytes32 pid) external view returns(uint256) {
        if (msg.sender == amVoteMachine) {
            return adminRep.totalSupply();

        } else if (msg.sender == hcVoteMachine) {
          //  uint256 id = pid2id[pid];
            return reputation.totalSupplyAt(proposals[pid].block);
        }
        else {   // if called by the web interface
            uint256 rep = reputation.totalSupplyAt(proposals[pid].block);
            return rep;
        }
    }

    // FUNCTIONS for GenesisProtocolCallbacksInterface
    function getAdminsTotalReputationSupply() external view returns(uint256) {
        return adminRep.totalSupply();
    }

    function reputationOfHC(address _owner, bytes32 pid) view external returns(uint256) {

        return reputation.balanceOfAt(_owner, proposals[pid].block);
    }

    function reputationOfAdmin(address _owner) view external returns(uint256) {

        return adminRep.balanceOf(_owner);
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
        emit NewProposal(0, newprop.id, msg.sender, _url, _amount);
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

    function addRepProposal(address _receiver, int256 _rep, uint256 _type) public { // type 1 = Admin, 2 = Contributors
        require(isAdmin(msg.sender), "only admin can propose");
        require(_rep != 0, "reputation proposed cannot be zero");

        RepProposal memory repprop;
        repprop.id = AbsoluteVote(amVoteMachine).propose(2, amParams, msg.sender, address(0));
        repprop.receiver = _receiver;
        repprop.rep = _rep;
        repprop.typ = _type;

        emit NewRepProposal(repprop.id, _receiver, _rep, _type);

        repProposals[repprop.id] = repprop;

    }

    function voteRepProposal(bytes32 _pid, uint256 _vote) public {

        AbsoluteVote(amVoteMachine).vote(_pid, _vote, 0, msg.sender);

    }

    function voteProposal(bytes32 _pid, uint256 _vote) public { //ifStatus(_id, 1) {

        GenesisProtocol(hcVoteMachine).vote(_pid, _vote, 0, msg.sender);
        emit VotingProposal(0,
                            _pid,
                            msg.sender,
                            reputation.balanceOfAt(msg.sender, proposals[_pid].block),
                            _vote);
    }

    function voteAMProposal(bytes32 _pid, uint256 _vote) public ifStatus(_pid, 2) {

        bytes32 amPid = pid2AMpid[_pid];
        emit VotingAMProposal(0, amPid, msg.sender, adminRep.balanceOf(msg.sender), _vote);

        AbsoluteVote(amVoteMachine).vote(amPid, _vote, 0, msg.sender);
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
    }

    function approveExecution(bytes32 _pid) public {
         //require(msg.sender == artist);
        //uint256 id = pid2id[_pid];
        require(winningProposal != 0, "require winning proposal");
        require(winpid == _pid, "require _pid is winningProposal");
        require(proposals[winningProposal].status == 2, "requiring status == 2 (in Approve Execution)");

        proposals[winningProposal].status = 3;

        uint256 portion = proposals[winningProposal].amount/10;
      //  require(portion == 10, "asserting that portion is 10");

        beneficiary.transfer(portion);
        proposals[winningProposal].proposer.transfer(proposals[winningProposal].amount - portion);

        emit ApprovedExecution(0, _pid, winningProposal);

    }

    function vetoExecution(bytes32 _pid) public {
        require(winpid == _pid, "required _pid is winnigProposal");
        require(proposals[winningProposal].status == 2, "requiring status == 2");

        emit VetoedExecution(0, _pid, winningProposal);

        proposals[winningProposal].status = 1;
        winningProposal = 0;
        winpid = 0;
        proposals[_pid].decision = 2;
    }

}
