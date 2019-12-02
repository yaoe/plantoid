LEX Plantoid.

    event GotDonation(address _donor, uint amount);
    event AcceptedDonation(address _donor, uint amount);
    event DebugDonation(address _donor, uint amount, uint _threshold, uint _overflow);
    event NewProposal(uint id, address _proposer, string url);
    event VotingProposal(uint id, uint pid, address _voter, uint _reputation, bool _voted);
    event VotedProposal(uint id, uint pid, address _voter);
    event WinningProposal(uint id, uint pid);


    "Artist" is a person.
    "Threshold" is an amount.
    "Wei Raised" is an amount.
    "Seed Count" is an amount.

    mapping (uint => Seed) public seeds;



  CONTRACTS per Proposal:
    "Id" is a number;
    "Proposer" is a person;
    "URL" is a text;
    "Votes" is a number;

    CLAUSE Add Proposal.
    If the Status of a Seed is "bidding" then
    any Person may create a new Proposal for the Seed with that Person as Proposer and a given URL.
    Notify of the new proposal, Proposer, and URL.

    struct Seed {
        uint id;
        uint status;
        mapping (address => uint) reputation;
        Proposal[] proposals;
        mapping (address => bool) voters;
        uint totVotes;
    }

CONTRACTS per Seed:
"Status" is "collecting", "bidding", "hiring", or "complete".
"Donors" is a list of Donors.
"Proposals" is a list of Proposals.
"Total Votes" is a number.

CLAUSE Status Verification.
"Status Verification" is defined as the Status equalling a given Value.


CONTRACTS per Donor:
"Has Voted" is binary.
"Has Voted" is binary.





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
            currSeed.proposals[pid].proposer.transfer(threshold);
        }

    }

CLAUSE Count of Proposals.
"Count of Proposals" is defined as the count of Proposals of a Seed.

CLAUSE Proposal Status.
"Proposal Status" is defined as the data of the Proposal of a Seed.



CLAUSE Fund.

        uint funds = msg.value;

        // Log that the Plantoid received a new donation
        Notify of the Donation from a Person.
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
