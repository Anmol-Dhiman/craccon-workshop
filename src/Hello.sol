// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
contract Hello {
    uint public x = 123123;
    bool public b = true;

    function udpate(uint _x) public {
        x = _x;
    }

     function get() public view returns (uint) {
          return x;
     }
}
