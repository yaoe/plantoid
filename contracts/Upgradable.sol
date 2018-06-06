pragma solidity ^0.4.23;


contract Upgradable {

    uint32 public val = 5;

    function test(uint32 v) public returns(uint32, uint256) {
        val = v;
        return (val, address(this).balance);
    }

    function getTest() public view returns (uint32) {
        return val;
    }
}
