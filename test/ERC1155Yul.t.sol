// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test } from "@forge-std/Test.sol";
import {console } from "@forge-std/console.sol";
import  {Vm } from "@forge-std/Vm.sol";

import { YulDeployer } from "./lib/YulDeployer.sol";
import { IERC1155 } from "./IERC1155.sol";

contract ERC1155YulTest is Test {

    address alice;
    address bob;

    YulDeployer yulDeployer = new YulDeployer();
    IERC1155 token;

    mapping(address => mapping(uint256 => uint256)) public userMintAmounts;
    mapping(address => mapping(uint256 => uint256)) public userTransferOrBurnAmounts;

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );
    event URI(string _value, uint256 indexed _id);

    function setUp() public {
        token = IERC1155(yulDeployer.deployContract("ERC1155Yul"));

        alice = makeAddr("Alice");
        bob = makeAddr("Bob");

        vm.label(alice, "Alice");
        vm.label(bob, "Bob");

        vm.label(address(this), "TestContract");
    }

    // function test_Test() public {
    //     console.logAddress(alice);
    //     assertEq(true, true);
    // }

    function testMintToEOA() public {
        token.mint(address(0xBEEF), 1337, 1, "");

        assertEq(token.balanceOf(address(0xBEEF), 1337), 1);
    }

}