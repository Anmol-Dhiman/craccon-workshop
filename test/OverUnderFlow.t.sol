// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

/// @title contract to demo overflow and underflow
contract OverflowDemo {
    uint8 public smallNumber = 255; // max for uint8
    uint8 public zeroNumber = 0;

    // Force overflow
    function addOne() public {
        unchecked {
            smallNumber = smallNumber + 1; // 255 + 1 = 0 (wraps around)
        }
    }

    // Force underflow
    function subtractOne() public {
        unchecked {
            zeroNumber = zeroNumber - 1; // 0 - 1 = 255 (wraps around)
        }
    }
}

/// @title Test Overflow & Underflow
contract OverflowSimpleTest is Test {
    OverflowDemo demo;

    function setUp() public {
        demo = new OverflowDemo();
    }

    function testOverflow() public {
        demo.addOne();
        uint8 result = demo.smallNumber();

        emit log_named_uint("Overflow result", result);
        assertEq(result, 0, "255 + 1 should wrap to 0 in uint8");
    }

    function testUnderflow() public {
        demo.subtractOne();
        uint8 result = demo.zeroNumber();

        emit log_named_uint("Underflow result", result);
        assertEq(result, 255, "0 - 1 should wrap to 255 in uint8");
    }
}
