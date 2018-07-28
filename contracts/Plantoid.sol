pragma solidity ^0.4.23;

import "@daostack/infra/contracts/Reputation.sol";
import "openzeppelin-solidity/contracts/token/ERC827/ERC827Token.sol";
import "@daostack/infra/contracts/VotingMachines/GenesisProtocol.sol";
import "@daostack/infra/contracts/VotingMachines/GenesisProtocolCallbacksInterface.sol";
import "@daostack/infra/contracts/VotingMachines/ExecutableInterface.sol";

contract Plantoid is GenesisProtocolCallbacksInterface,ExecutableInterface {

    event GotDonation(address _donor, uint _amount);
    event AcceptedDonation(address _donor, uint _amount);
    event DebugDonation(address _donor, uint amount, uint _threshold, uint _overflow);
    event Reproducing(uint _seedCnt);
    event NewProposal(uint id, address _proposer, string url,bytes32 _proposalId);
    event VotingProposal(uint id, uint pid, address _voter, uint _reputation, bool _voted);
    event VotedProposal(uint id, uint pid, address _voter);
    event WinningProposal(uint id, bytes32 pid);
    event NewSeed(uint _cnt);


// NEVER TOUCH
    uint public save1;
    uint public save2;

    address public artist;
    uint public threshold;

    uint public weiRaised;
    uint public seedCnt;

    struct Proposal {
        bytes32 id;
        address proposer;
        string url;
        uint votes;
    }

    // Seed struct:
    struct Seed {
        Reputation repSystem;
        mapping(bytes32=>Proposal) proposals;
        uint status;
    }

    struct Parameters {
        bytes32 voteApproveParams;
        IntVoteInterface intVote;
        address allowToExecute;
    }

    mapping (uint=>Seed) public seeds;

    //mapping between proposal to seed index
    mapping (bytes32=>uint) public proposalToSeed;

    // A mapping from hashes to parameters (use to store a particular configuration on the controller)
    mapping(bytes32=>Parameters) public parameters;

    bytes32 public paramsHash;
    ERC827Token stakingToken;
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

    constructor(address _artist, uint _threshold,ERC827Token _stakingToken) public {
        seeds[0].repSystem = new Reputation();
        artist = _artist;
        threshold = _threshold;
        stakingToken = _stakingToken;
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


    function addProposal(uint256 id, string url) public ifStatus(id, 1) returns(bytes32){
        Seed storage currSeed = seeds[id]; // try with 'memory' instead of 'storage'

        Parameters storage params = parameters[paramsHash];
        bytes32 proposalId = params.intVote.propose(
            2,
            params.voteApproveParams,
           0,
           ExecutableInterface(this),
           msg.sender
        );
        Proposal memory newprop;
        newprop.id = proposalId;
        newprop.proposer = msg.sender;
        newprop.url = url;
        currSeed.proposals[proposalId] = newprop;
        proposalToSeed[proposalId] = id;
        emit NewProposal(id, msg.sender, url,proposalId);
        return proposalId;
    }

    function vote(bytes32 _proposalId,uint _vote) public returns(bool){
        uint id = proposalToSeed[_proposalId];
        require(seeds[id].status == 1);
        Parameters storage params = parameters[paramsHash];
        return params.intVote.vote(_proposalId,_vote,msg.sender);
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
        require(msg.value > 0);
        // Log that the Plantoid received a new donation
        emit GotDonation(msg.sender, msg.value);

        _fund(msg.value);
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

        seeds[seedCnt].repSystem.mint(msg.sender, donation);

        // Create new Baby:
        if (weiRaised >= threshold) {
            seeds[seedCnt].status = 1;
            emit Reproducing(seedCnt);
            seedCnt++;
            emit NewSeed(seedCnt);
            weiRaised = 0;
            seeds[seedCnt].repSystem = new Reputation();
            if (overflow != 0) {
                _fund(overflow);
            }
        }
    }

    /**
    * @dev hash the parameters, save them if necessary, and return the hash value
    */
    function setParameters(
        bytes32 _voteApproveParams,
        IntVoteInterface _intVote,
        address _allowToExecute
    ) public returns(bytes32)
    {
        //allow only one time call
        require(paramsHash == bytes32(0));
        bytes32 _paramsHash = getParametersHash(
            _voteApproveParams,
            _intVote,
            _allowToExecute
        );
        parameters[_paramsHash].voteApproveParams = _voteApproveParams;
        parameters[_paramsHash].intVote = _intVote;
        parameters[_paramsHash].allowToExecute = _allowToExecute;
        paramsHash = _paramsHash;
        return paramsHash;
    }

    /**
    * @dev return a hash of the given parameters
    * @param _voteApproveParams parameters for the voting machine.
    * @param _intVote the voting machine used to approve a contribution
    * @param _allowToExecute specify address which allow to call the genesisProtocolCallbacks.
    * @return a hash of the parameters
    */
    // TODO: These fees are messy. Better to have a _fee and _feeToken pair, just as in some other contract (which one?) with some sane default
    function getParametersHash(
        bytes32 _voteApproveParams,
        IntVoteInterface _intVote,
        address _allowToExecute
    ) public pure returns(bytes32)
    {
        return (keccak256(abi.encodePacked(_voteApproveParams, _intVote,_allowToExecute)));
    }

    function getTotalReputationSupply(bytes32 _proposalId) external returns(uint256) {
        uint id = proposalToSeed[_proposalId];
        return seeds[id].repSystem.totalSupply();
    }

    function mintReputation(uint _amount,address _beneficiary,bytes32 _proposalId) external returns(bool) {
        uint id = proposalToSeed[_proposalId];
        require(msg.sender == parameters[paramsHash].allowToExecute);
        return seeds[id].repSystem.mint(_beneficiary,_amount);
    }

    function burnReputation(uint _amount,address _beneficiary,bytes32 _proposalId) external returns(bool) {
        uint id = proposalToSeed[_proposalId];
        require(msg.sender == parameters[paramsHash].allowToExecute);
        return seeds[id].repSystem.burn(_beneficiary,_amount);
    }

    function reputationOf(address _owner,bytes32 _proposalId) external view returns(uint) {
        uint id = proposalToSeed[_proposalId];
        return seeds[id].repSystem.reputationOf(_owner);
    }

    function stakingTokenTransfer(address _beneficiary,uint _amount,bytes32 ) external returns(bool) {
        require(msg.sender == parameters[paramsHash].allowToExecute);
        return stakingToken.transfer(_beneficiary,_amount);
    }

    function setGenesisProtocolParameters(GenesisProtocol genesisProtocol , uint[14] _params) external returns(bytes32) {
        return genesisProtocol.setParameters(_params,address(this));
    }

    function executeProposal(bytes32 _proposalId,int _decision,ExecutableInterface ) external returns(bool) {
        require(msg.sender == parameters[paramsHash].allowToExecute);
        return execute(_proposalId, 0, _decision);
    }

    /**
  * @dev execution of proposals, can only be called by the voting machine in which the vote is held.
  * @param _proposalId the ID of the voting in the voting machine
  * @param _param a parameter of the voting result, 1 yes and 2 is no.
  */
  function execute(bytes32 _proposalId, address , int _param) public returns(bool) {
      // Check the caller is indeed the voting machine:
      require(msg.sender == parameters[paramsHash].allowToExecute);
      // Check if vote was successful:
      if (_param == 1) {
          emit WinningProposal(proposalToSeed[_proposalId], _proposalId);
          uint id = proposalToSeed[_proposalId];
          seeds[id].proposals[_proposalId].proposer.transfer(threshold);
      }
      return true;
  }
}
