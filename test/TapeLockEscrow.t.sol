// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {TapeLockEscrow, ITapeOutVerifier} from "../src/TapeLockEscrow.sol";
import {MockTapeOutVerifier} from "./MockTapeOutVerifier.sol";

contract TapeLockEscrowTest is Test {
    TapeLockEscrow escrow;
    MockTapeOutVerifier verifier;
    address buyer = address(0xB0B);
    address seller = address(0x5E11);
    address arbiter = address(0xA181);

    uint256 constant CHALLENGE = 1 days;

    function setUp() public {
        verifier = new MockTapeOutVerifier();
        escrow = new TapeLockEscrow(address(verifier), CHALLENGE);
        vm.deal(buyer, 100 ether);
        vm.deal(seller, 1 ether);
    }

    function _create(uint256[] memory circuits, uint256[] memory amounts, uint256 value) internal returns (uint256) {
        vm.prank(buyer);
        return escrow.createEscrow{value: value}(seller, arbiter, block.timestamp + 7 days, circuits, amounts);
    }

    function testHappyPath() public {
        uint256[] memory circuits = new uint256[](1);
        circuits[0] = 4246;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1 ether;
        uint256 id = _create(circuits, amounts, 1 ether);

        verifier.setCircuit(4246, seller);
        vm.prank(seller);
        escrow.deliver(id, 0);

        uint256 before = seller.balance;
        vm.prank(buyer);
        escrow.confirmRelease(id, 0);
        assertEq(seller.balance, before + 1 ether);
    }

    function testDeliverUnverifiedReverts() public {
        uint256[] memory circuits = new uint256[](1);
        circuits[0] = 4246;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1 ether;
        uint256 id = _create(circuits, amounts, 1 ether);

        // circuit not registered -> deliver must revert
        vm.prank(seller);
        vm.expectRevert(TapeLockEscrow.NotVerified.selector);
        escrow.deliver(id, 0);

        // registered to someone else -> still reverts
        verifier.setCircuit(4246, buyer);
        vm.prank(seller);
        vm.expectRevert(TapeLockEscrow.NotVerified.selector);
        escrow.deliver(id, 0);
    }

    function testClaimAfterWindow() public {
        uint256[] memory circuits = new uint256[](1);
        circuits[0] = 7;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 2 ether;
        uint256 id = _create(circuits, amounts, 2 ether);

        verifier.setCircuit(7, seller);
        vm.prank(seller);
        escrow.deliver(id, 0);

        vm.prank(seller);
        vm.expectRevert(TapeLockEscrow.TooEarly.selector);
        escrow.claimAfterWindow(id, 0);

        vm.warp(block.timestamp + CHALLENGE + 1);
        uint256 before = seller.balance;
        vm.prank(seller);
        escrow.claimAfterWindow(id, 0);
        assertEq(seller.balance, before + 2 ether);
    }

    function testDisputeResolvedToBuyer() public {
        uint256[] memory circuits = new uint256[](1);
        circuits[0] = 9;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1 ether;
        uint256 id = _create(circuits, amounts, 1 ether);

        verifier.setCircuit(9, seller);
        vm.prank(seller);
        escrow.deliver(id, 0);
        vm.prank(buyer);
        escrow.dispute(id, 0);

        uint256 before = buyer.balance;
        vm.prank(arbiter);
        escrow.resolveDispute(id, 0, false);
        assertEq(buyer.balance, before + 1 ether);
    }

    function testRefundAfterDeadline() public {
        uint256[] memory circuits = new uint256[](1);
        circuits[0] = 11;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 3 ether;
        uint256 id = _create(circuits, amounts, 3 ether);

        vm.prank(buyer);
        vm.expectRevert(TapeLockEscrow.TooEarly.selector);
        escrow.refund(id, 0);

        vm.warp(block.timestamp + 7 days + 1);
        uint256 before = buyer.balance;
        vm.prank(buyer);
        escrow.refund(id, 0);
        assertEq(buyer.balance, before + 3 ether);
    }
}
