// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

// https://tintinweb.github.io/smart-contract-storage-viewer/
/// Simple proxy that delegates all calls to an implementation
contract Proxy {
    address public owner; // slot 0
    address public implementation; // slot 1

    constructor() {
        owner = msg.sender;
    }

    /// Owner can update the implementation contract
    function setImplementation(address _impl) public {
        require(msg.sender == owner, "Not owner");
        implementation = _impl;
    }

    /// Forward all calls to the implementation using delegatecall
    fallback() external payable {
        (bool ok, bytes memory data) = implementation.delegatecall(msg.data);
        require(ok, "delegatecall failed");
        assembly {
            return(add(data, 0x20), mload(data))
        }
    }
}

/// First implementation with correct storage layout
/// Matches the proxy: slots 0 and 1 are already used by proxy variables
contract ImplV1 {
    address public owner; // slot 0
    address public implementation; // slot 1
    uint256 public value; // slot 2

    function setValue(uint256 _v) public {
        value = _v;
    }

    function getValue() public view returns (uint256) {
        return value;
    }
}

/// Second implementation with a bad storage layout
/// A new variable was added at the top, shifting everything else down
/// This breaks the proxy storage layout
contract ImplV2 {
    uint256 public newVar; // now slot 0 (overwrites Proxy.owner)
    address public owner; // now slot 1 (used to be slot 0)
    address public implementation; // now slot 2 (used to be slot 1)
    uint256 public value; // now slot 3 (used to be slot 2)




    function setValue(uint256 _v) public {
        value = _v;
    }

    function getValue() public view returns (uint256) {
        return value;
    }
}

/// Foundry test that demonstrates the bug
contract DelegatecallUpgradeBugTest is Test {
    Proxy proxy;
    ImplV1 implV1;
    ImplV2 implV2;

    function setUp() public {
        proxy = new Proxy();
        implV1 = new ImplV1();
        implV2 = new ImplV2();

        // Proxy starts with ImplV1 (correct layout)
        proxy.setImplementation(address(implV1));
    }

    function testUpgradeBug() public {
        // Store value through ImplV1 via proxy
        ImplV1(address(proxy)).setValue(42);
        uint v1 = ImplV1(address(proxy)).getValue();
        emit log_named_uint("Value before upgrade", v1);
        assertEq(v1, 42);

        // Owner upgrades to ImplV2 (wrong layout)
        proxy.setImplementation(address(implV2));

        // Now reading value gives wrong result because storage slots shifted
        uint v2 = ImplV2(address(proxy)).getValue();
        emit log_named_uint("Value after upgrade", v2);

        // Value is no longer correct due to storage collision
        assertTrue(v2 != 42, "Storage should be corrupted after upgrade");
    }
}
