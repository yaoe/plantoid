pragma solidity ^0.4.19;

contract Upgradeable {
  //  mapping(bytes4=>uint32) _sizes;
    address public target;
    address public owner = msg.sender;

    event EventUpgrade(address target, address admin);

    modifier onlyAdmin() {
        checkAdmin();
        _;
    }

    function upgrade(address _target) public onlyAdmin {
        verifyTargetState(_target);
        verifyState(_target);
        target = _target;
        emit EventUpgrade(_target, msg.sender);
    }

    function checkAdmin() internal view {
        require(msg.sender == owner);
    }

    function verifyState(address) internal pure {
        // do something with testTarget
    }

    function delegateGet(address testTarget, string signature) internal returns (bytes32 result) {
        bytes4 targetCall = bytes4(keccak256(signature));
        assembly {
            let free:= mload(0x40)
            mstore(free, targetCall)
            let retVal := delegatecall(gas, testTarget, free, 4, free, 32)
            result := mload(free)
        }
    }

    function verifyTargetState(address testTarget) private {
        require(address(delegateGet(testTarget, "target()")) == target);
    }



    /**
         * This function is called using delegatecall from the dispatcher when the
         * target contract is first initialized. It should use this opportunity to
         * insert any return data sizes in _sizes, and perform any other upgrades
         * necessary to change over from the old contract implementation (if any).
         *
         * Implementers of this function should either perform strictly harmless,
         * idempotent operations like setting return sizes, or use some form of
         * access control, to prevent outside callers.
    */
//    function internal initialize();

    /**
         * Performs a handover to a new implementing contract.
    */

    /*
    function replace(address target) internal {
        _dest = target;
        target.delegatecall(bytes4(sha3("initialize()")));
    }
    */

/*    function initialize() {
        // Should only be called by on target contracts, not on the dispatcher
        assert(false);
    }*/

}

contract Dispatcher is Upgradeable {

  function Dispatcher(address _target) public {
        //replace(target);
        target = _target;
    }

/*    function initialize() {
        // Should only be called by on target contracts, not on the dispatcher
        throw;
    }
*/

    function() public payable {
    /*    bytes4 sig;
        assembly { sig := calldataload(0) }
        uint len = _sizes[sig];
        address target = _dest;
        assembly {
            // return _dest.delegatecall(msg.data)
            calldatacopy(0x0, 0x0, calldatasize)
            delegatecall(sub(gas, 10000), target, 0x0, calldatasize, 0, len)
            return(0, len)
        }
*/
        assembly {
            let _target := sload(0)
            calldatacopy(0x0, 0x0, calldatasize)
            let retval := delegatecall(gas, _target, 0x0, calldatasize, 0x0, 0)
            let returnsize := returndatasize
            returndatacopy(0x0, 0x0, returnsize)
            switch retval case 0 {revert(0, 0)} default {return (0, returnsize)}
        }
    }
}

contract Plantoid is Upgradeable {

    event GotDonation(address _donor, uint amount);
    event AcceptedDonation(address _donor, uint amount);
    event Reproducing(uint seedCnt);
    event NewProposal(uint id, address _proposer, string url);
    event VotingProposal(uint id, uint pid, address _voter, uint _reputation, bool _voted);
    event VotedProposal(uint id, uint pid, address _voter);
    event WinningProposal(uint id, uint pid);

    address public artist;
    uint public weiRaised;
    uint public threshold;
    uint public seedCnt = 0;

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
        uint id;
        address proposer;
        string url;
        uint votes;
    }

    struct Seed {
        uint id;
        uint status;
        mapping (address => uint) reputation;
        Proposal[] proposals;
        mapping (address => bool) voters;
        uint totVotes;
    }

    mapping (uint => Seed) public seeds;

    function Plantoid(address _artist, uint _threshold) public {
        artist = _artist;
        threshold = _threshold;
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
        newprop.id = currSeed.proposals.length;
        newprop.proposer = msg.sender;
        newprop.url = url;
        currSeed.proposals.push(newprop);
        emit NewProposal(id, msg.sender, url);

    }

    function voteProposal(uint256 id, uint pid) public ifStatus(id, 1) {
        Seed storage currSeed = seeds[id];

        emit VotingProposal(id, pid, msg.sender, currSeed.reputation[msg.sender], currSeed.voters[msg.sender]);


        assert(currSeed.reputation[msg.sender] != 0);
        assert(!currSeed.voters[msg.sender]);

        emit VotedProposal(id, pid, msg.sender);

        currSeed.proposals[pid].votes += currSeed.reputation[msg.sender];
        currSeed.voters[msg.sender] = true;
        currSeed.totVotes += currSeed.reputation[msg.sender];

        // check if we got a winner
        // Absolute majority
        if (currSeed.proposals[pid].votes > threshold / 2) {
            emit WinningProposal(id, pid);
        }

    }

    function nProposals(uint256 id) public constant returns (uint _id, uint n) {
        n = seeds[id].proposals.length;
        _id = id;
    }

    function getProposal(uint256 id, uint pid) public constant returns(uint _id, uint _pid, address _from, string _url, uint _votes) {
        _from = seeds[id].proposals[pid].proposer;
        _url = seeds[id].proposals[pid].url;
        _votes = seeds[id].proposals[pid].votes;
        _pid = seeds[id].proposals[pid].id;
        _id = id;
    }

    // External fund function
    function fund() public payable {
        require(msg.value > 0);

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
        } else {
            donation = _donation;
        }
      // Increase the amount of weiRaised (for that particular Seed)
        weiRaised += donation;
        emit AcceptedDonation(msg.sender, donation);

      // Increase the reputation of the donor (for that particular Seed)
        seeds[seedCnt].reputation[msg.sender] += donation;

        if (weiRaised >= threshold) {
            emit Reproducing(seedCnt);
            // change status of the seeds
            seeds[seedCnt].status = 1;

            // Create new Seed:
            seedCnt++;
            //Seed memory newseed; //= Seed(seedCnt, 0, new Proposal[](0)); // 'reputation' member doesn't count
            seeds[seedCnt].id = seedCnt;
            weiRaised = 0;
            // Feed the new seed if there was an overflow of donations
            // (overflow != 0) {  _fund(overflow); }
        }
    }


}
