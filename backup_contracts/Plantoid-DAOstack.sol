pragma solidity ^0.4.19;

import "@daostack/arc/contracts/controller/Reputation.sol";
import "@daostack/arc/contracts/VotingMachines/AbsoluteVote.sol";

contract Plantoid {

    event donation(address _donor, uint amount);
    event newBaby(uint _cnt);

    address public artist;
    uint public threshold;
    uint public weiRaised;
    uint public babiesCnt;

    /*enum Status { Proposals, Milestones };*/

    // Baby struct:
    struct Baby {
        Reputation repSystem;
        bytes32 propId;
        uint status;
    }

    mapping (uint=>Baby) public babies;

    function Plantoid(address _artist, uint _threshold) public {
        artist = _artist;
        threshold = _threshold;
        babies[0].repSystem = new Reputation();
    }

    function fund () payable public {
        require(msg.value > 0);
        donation(msg.sender, msg.value);
        _fund(msg.value);
    }

    function () payable public {
        fund();
    }

    // Internal functions:
    function _fund (uint _donation) internal {
        uint overflow;
        uint donation;

        // Check overflow:
        if (weiRaised + _donation > threshold) {
            overflow = weiRaised + _donation - threshold;
            donation = threshold - weiRaised;
        } else {
            donation = _donation;
        }

        weiRaised += donation;
        babies[babiesCnt].repSystem.mint(msg.sender, donation);

        // Create new Baby:
        if (weiRaised >= threshold) {
            babiesCnt++;
            newBaby(babiesCnt);
            weiRaised = 0;
            babies[babiesCnt].repSystem = new Reputation();
            /*if (overflow != 0) {
                _fund(overflow);
            }*/
        }
    }
}
