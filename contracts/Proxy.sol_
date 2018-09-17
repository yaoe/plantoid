pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";


contract Proxy is Ownable {

    address public _implementation;

    address public artist;
    uint public threshold;


    constructor(address _artist, uint _threshold) public {
        artist = _artist;
        threshold = _threshold;
    }


    event Upgraded(address indexed implementation);
    event FallingBack(address indexed implemantion, bytes data);


    function implementation() public view returns (address) {
        return _implementation;
    }

    function upgradeTo(address impl) public onlyOwner {
        require(_implementation != impl);
        _implementation = impl;
        emit Upgraded(impl);
        //Plantoid(address(this)).setup(_artist, _threshold);
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
