// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test } from "@forge-std/Test.sol";
import {console } from "@forge-std/console.sol";
import  {Vm } from "@forge-std/Vm.sol";

import { YulDeployer } from "./lib/YulDeployer.sol";
import { IERC1155 } from "../src/IERC1155.sol";
// import { ERC1155Recipient } from "../src/ERC1155Recipient.sol";


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

    function testMintToEOA() public {

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit TransferSingle(address(this), address(0x0), address(0xBEEF), 1337, 1);

        token.mint(address(0xBEEF), 1337, 1, "");

        assertEq(token.balanceOf(address(0xBEEF), 1337), 1);
    }

    function testBatchMintToEOA() public {
        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory amounts = new uint256[](5);
        amounts[0] = 100;
        amounts[1] = 200;
        amounts[2] = 300;
        amounts[3] = 400;
        amounts[4] = 500;

        token.batchMint(address(0xBEEF), ids, amounts, "");

        assertEq(token.balanceOf(address(0xBEEF), 1337), 100);
        assertEq(token.balanceOf(address(0xBEEF), 1338), 200);
        assertEq(token.balanceOf(address(0xBEEF), 1339), 300);
        assertEq(token.balanceOf(address(0xBEEF), 1340), 400);
        assertEq(token.balanceOf(address(0xBEEF), 1341), 500);

    }

    function testApproveAll() public {
        token.setApprovalForAll(address(0xBEEF), true);

        assertTrue(token.isApprovedForAll(address(this), address(0xBEEF)));
    }

    function testSafeTransferFromToEOA() public {
        address from = address(0xABCD);

        token.mint(from, 1337, 100, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit TransferSingle(address(this), from, address(0xBEEF), 1337, 70);
        token.safeTransferFrom(from, address(0xBEEF), 1337, 70, "");

        assertEq(token.balanceOf(address(0xBEEF), 1337), 70);
        assertEq(token.balanceOf(from, 1337), 30);
    }

    function testSafeTransferFromSelf() public {
        token.mint(address(this), 1337, 100, "");

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit TransferSingle(address(this), address(this), address(0xBEEF), 1337, 70);
        token.safeTransferFrom(address(this), address(0xBEEF), 1337, 70, "");

        assertEq(token.balanceOf(address(0xBEEF), 1337), 70);
        assertEq(token.balanceOf(address(this), 1337), 30);
    }

    function testSafeBatchTransferFromToEOA() public {
        address from = address(0xABCD);

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        uint256[] memory transferAmounts = new uint256[](5);
        transferAmounts[0] = 50;
        transferAmounts[1] = 100;
        transferAmounts[2] = 150;
        transferAmounts[3] = 200;
        transferAmounts[4] = 250;

        token.batchMint(from, ids, mintAmounts, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit TransferBatch(address(this), from, address(0xBEEF), ids, transferAmounts);
        token.safeBatchTransferFrom(from, address(0xBEEF), ids, transferAmounts, "");

        assertEq(token.balanceOf(from, 1337), 50);
        assertEq(token.balanceOf(address(0xBEEF), 1337), 50);

        assertEq(token.balanceOf(from, 1338), 100);
        assertEq(token.balanceOf(address(0xBEEF), 1338), 100);

        assertEq(token.balanceOf(from, 1339), 150);
        assertEq(token.balanceOf(address(0xBEEF), 1339), 150);

        assertEq(token.balanceOf(from, 1340), 200);
        assertEq(token.balanceOf(address(0xBEEF), 1340), 200);

        assertEq(token.balanceOf(from, 1341), 250);
        assertEq(token.balanceOf(address(0xBEEF), 1341), 250);
    }

    function testBatchBalanceOf() public {
        address[] memory tos = new address[](5);
        tos[0] = address(0xBEEF);
        tos[1] = address(0xCAFE);
        tos[2] = address(0xFACE);
        tos[3] = address(0xDEAD);
        tos[4] = address(0xFEED);

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        token.mint(address(0xBEEF), 1337, 100, "");
        token.mint(address(0xCAFE), 1338, 200, "");
        token.mint(address(0xFACE), 1339, 300, "");
        token.mint(address(0xDEAD), 1340, 400, "");
        token.mint(address(0xFEED), 1341, 500, "");

        uint256[] memory balances = token.balanceOfBatch(tos, ids);

        assertEq(balances[0], 100);
        assertEq(balances[1], 200);
        assertEq(balances[2], 300);
        assertEq(balances[3], 400);
        assertEq(balances[4], 500);
    }

    function testFailMintToZero() public {
        token.mint(address(0), 1337, 1, "");
    }

    function testFailSafeTransferFromInsufficientBalance() public {
        address from = address(0xABCD);

        token.mint(from, 1337, 70, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, address(0xBEEF), 1337, 100, "");
    }

    function testFailSafeTransferFromSelfInsufficientBalance() public {
        token.mint(address(this), 1337, 70, "");
        token.safeTransferFrom(address(this), address(0xBEEF), 1337, 100, "");
    }

    function testFailSafeTransferFromToZero() public {
        token.mint(address(this), 1337, 100, "");
        token.safeTransferFrom(address(this), address(0), 1337, 70, "");
    }


    function testFailSafeBatchTransferInsufficientBalance() public {
        address from = address(0xABCD);

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);

        mintAmounts[0] = 50;
        mintAmounts[1] = 100;
        mintAmounts[2] = 150;
        mintAmounts[3] = 200;
        mintAmounts[4] = 250;

        uint256[] memory transferAmounts = new uint256[](5);
        transferAmounts[0] = 100;
        transferAmounts[1] = 200;
        transferAmounts[2] = 300;
        transferAmounts[3] = 400;
        transferAmounts[4] = 500;

        token.batchMint(from, ids, mintAmounts, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeBatchTransferFrom(from, address(0xBEEF), ids, transferAmounts, "");
    }

    function testFailSafeBatchTransferFromToZero() public {
        address from = address(0xABCD);

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        uint256[] memory transferAmounts = new uint256[](5);
        transferAmounts[0] = 50;
        transferAmounts[1] = 100;
        transferAmounts[2] = 150;
        transferAmounts[3] = 200;
        transferAmounts[4] = 250;

        token.batchMint(from, ids, mintAmounts, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeBatchTransferFrom(from, address(0), ids, transferAmounts, "");
    }

    function testFailSafeBatchTransferFromWithArrayLengthMismatch() public {
        address from = address(0xABCD);

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        uint256[] memory transferAmounts = new uint256[](4);
        transferAmounts[0] = 50;
        transferAmounts[1] = 100;
        transferAmounts[2] = 150;
        transferAmounts[3] = 200;

        token.batchMint(from, ids, mintAmounts, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeBatchTransferFrom(from, address(0xBEEF), ids, transferAmounts, "");
    }


    function testFailBatchMintToZero() public {
        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        token.batchMint(address(0), ids, mintAmounts, "");
    }

    function testFailBatchMintWithArrayMismatch() public {
        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 100;
        amounts[1] = 200;
        amounts[2] = 300;
        amounts[3] = 400;

        token.batchMint(address(0xBEEF), ids, amounts, "");
    }

    function testFailBalanceOfBatchWithArrayMismatch() public view {
        address[] memory tos = new address[](5);
        tos[0] = address(0xBEEF);
        tos[1] = address(0xCAFE);
        tos[2] = address(0xFACE);
        tos[3] = address(0xDEAD);
        tos[4] = address(0xFEED);

        uint256[] memory ids = new uint256[](4);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;

        token.balanceOfBatch(tos, ids);
    }

    function testMintToEOA(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory mintData
    ) public {
        if (to == address(0)) to = address(0xBEEF);

        if (uint256(uint160(to)) <= 18 || to.code.length > 0) return;

        token.mint(to, id, amount, mintData);

        assertEq(token.balanceOf(to, id), amount);
    }


    function testApproveAll(address to, bool approved) public {
        token.setApprovalForAll(to, approved);

        assertEq(token.isApprovedForAll(address(this), to), approved);
    }

    function testSafeTransferFromToEOA(
        uint256 id,
        uint256 mintAmount,
        bytes memory mintData,
        uint256 transferAmount,
        address to,
        bytes memory transferData
    ) public {
        if (to == address(0)) to = address(0xBEEF);

        if (uint256(uint160(to)) <= 18 || to.code.length > 0) return;

        transferAmount = bound(transferAmount, 0, mintAmount);

        address from = address(0xABCD);

        token.mint(from, id, mintAmount, mintData);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, to, id, transferAmount, transferData);

        if (to == from) {
            assertEq(token.balanceOf(to, id), mintAmount);
        } else {
            assertEq(token.balanceOf(to, id), transferAmount);
            assertEq(token.balanceOf(from, id), mintAmount - transferAmount);
        }
    }

    function testSafeTransferFromSelf(
        uint256 id,
        uint256 mintAmount,
        bytes memory mintData,
        uint256 transferAmount,
        address to,
        bytes memory transferData
    ) public {
        if (to == address(0)) to = address(0xBEEF);

        if (uint256(uint160(to)) <= 18 || to.code.length > 0) return;

        transferAmount = bound(transferAmount, 0, mintAmount);

        token.mint(address(this), id, mintAmount, mintData);

        token.safeTransferFrom(address(this), to, id, transferAmount, transferData);

        assertEq(token.balanceOf(to, id), transferAmount);
        assertEq(token.balanceOf(address(this), id), mintAmount - transferAmount);
    }

    function testFailMintToZero(
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
        token.mint(address(0), id, amount, data);
    }

    function testFailSafeTransferFromInsufficientBalance(
        address to,
        uint256 id,
        uint256 mintAmount,
        uint256 transferAmount,
        bytes memory mintData,
        bytes memory transferData
    ) public {
        address from = address(0xABCD);

        transferAmount = bound(transferAmount, mintAmount + 1, type(uint256).max);

        token.mint(from, id, mintAmount, mintData);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, to, id, transferAmount, transferData);
    }

    function testFailSafeTransferFromSelfInsufficientBalance(
        address to,
        uint256 id,
        uint256 mintAmount,
        uint256 transferAmount,
        bytes memory mintData,
        bytes memory transferData
    ) public {
        transferAmount = bound(transferAmount, mintAmount + 1, type(uint256).max);

        token.mint(address(this), id, mintAmount, mintData);
        token.safeTransferFrom(address(this), to, id, transferAmount, transferData);
    }

    function testFailSafeTransferFromToZero(
        uint256 id,
        uint256 mintAmount,
        uint256 transferAmount,
        bytes memory mintData,
        bytes memory transferData
    ) public {
        transferAmount = bound(transferAmount, 0, mintAmount);

        token.mint(address(this), id, mintAmount, mintData);
        token.safeTransferFrom(address(this), address(0), id, transferAmount, transferData);
    }

    function testFailSafeBatchTransferFromWithArrayLengthMismatch(
        address to,
        uint256[] memory ids,
        uint256[] memory mintAmounts,
        uint256[] memory transferAmounts,
        bytes memory mintData,
        bytes memory transferData
    ) public {
        address from = address(0xABCD);

        if (ids.length == transferAmounts.length) revert();

        token.batchMint(from, ids, mintAmounts, mintData);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeBatchTransferFrom(from, to, ids, transferAmounts, transferData);
    }

    function testFailBatchMintWithArrayMismatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory mintData
    ) public {
        if (ids.length == amounts.length) revert();

        token.batchMint(address(to), ids, amounts, mintData);
    }


    function testFailBalanceOfBatchWithArrayMismatch(address[] memory tos, uint256[] memory ids) public view {
        if (tos.length == ids.length) revert();

        token.balanceOfBatch(tos, ids);
    }

}