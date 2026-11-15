// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {TapeOutVerifier} from "../src/TapeOutVerifier.sol";
import {TapeLockEscrow} from "../src/TapeLockEscrow.sol";
import {MockProcessor, MockOpener, MockFactory, MockContainer} from "../src/testnet/MockTapeOut.sol";

contract TapeOutVerifierTest is Test {
    MockProcessor processor;
    MockOpener opener;
    MockFactory factory;
    TapeOutVerifier verifier;
    TapeLockEscrow escrow;

    address seller = address(0x5E11);
    address buyer = address(0xB0B);
    uint256 constant CIRCUIT = 4246;

    function setUp() public {
        processor = new MockProcessor();
        opener = new MockOpener();
        factory = new MockFactory();
        factory.addCPU(address(processor)); // processor #0

        // tape-out: mint circuit NFT to seller + open its container
        processor.mint(seller, CIRCUIT);
        MockContainer container = new MockContainer(block.chainid, address(processor), CIRCUIT);
        opener.open(address(processor), CIRCUIT, address(container));

        verifier = new TapeOutVerifier(address(factory), address(opener), 0);
        escrow = new TapeLockEscrow(address(verifier), 1 days);
        vm.deal(buyer, 10 ether);
    }

    function testVerifierAcceptsRealCircuit() public view {
        assertTrue(verifier.isCircuitOwnedBy(CIRCUIT, seller));
    }

    function testVerifierRejectsWrongOwner() public view {
        assertFalse(verifier.isCircuitOwnedBy(CIRCUIT, buyer));
    }

    function testVerifierRejectsUnknownCircuit() public view {
        assertFalse(verifier.isCircuitOwnedBy(9999, seller));
    }

    function testVerifierRejectsUnopenedCircuit() public {
        processor.mint(seller, 777);
        // minted but container never opened
        assertFalse(verifier.isCircuitOwnedBy(777, seller));
    }

    function testEscrowEndToEndWithRealVerifier() public {
        uint256[] memory circuits = new uint256[](1);
        circuits[0] = CIRCUIT;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1 ether;

        vm.prank(buyer);
        uint256 id = escrow.createEscrow{value: 1 ether}(seller, address(0xA181), block.timestamp + 7 days, circuits, amounts);

        vm.prank(seller);
        escrow.deliver(id, 0);

        uint256 before = seller.balance;
        vm.prank(buyer);
        escrow.confirmRelease(id, 0);
        assertEq(seller.balance, before + 1 ether);
    }
}
