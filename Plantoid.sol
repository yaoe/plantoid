pragma solidity ^0.4.21;

contract Plantoid {

  function () payable { }

  function getBalance() constant returns(uint256) {
    return this.balance;
  }

}
