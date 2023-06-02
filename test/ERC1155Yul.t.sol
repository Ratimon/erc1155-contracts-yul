// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test } from "@forge-std/Test.sol";
import {console } from "@forge-std/console.sol";
import  {Vm } from "@forge-std/Vm.sol";
import "./lib/YulDeployer.sol";

interface YulContract {}

contract ERC1155YulTest is Test {
    YulDeployer yulDeployer = new YulDeployer();
    YulContract yulContract;

    address alice;
    address bob;

    function setUp() public {
        yulContract = YulContract(yulDeployer.deployContract("ERC1155Yul"));

        alice = makeAddr("Alice");
        bob = makeAddr("Bob");

        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        
        vm.label(address(this), "TestContract");
    }

    function test_Test() public {
        console.logAddress(alice);
        assertEq(true, true);
    }
}