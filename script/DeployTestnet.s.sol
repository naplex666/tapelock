// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {MockProcessor, MockOpener, MockFactory, MockContainer} from "../src/testnet/MockTapeOut.sol";
import {TapeOutVerifier} from "../src/TapeOutVerifier.sol";
import {TapeLockEscrow} from "../src/TapeLockEscrow.sol";

/// @notice Deploys the full TapeLock demo stack on X Layer testnet (1952):
/// TapeOut-compatible mocks -> verifier -> escrow -> one funded demo escrow.
/// Env: PRIVATE_KEY (deployer/buyer), TAPELOCK_SELLER, TAPELOCK_ARBITER.
/// Deliver/confirm run afterwards with cast using the seller/buyer keys.
contract DeployTestnet is Script {
    uint256 constant CIRCUIT = 4246;
    // sized to the 0.001 OKB faucet balance: deploys ~0.0001 OKB at 0.02 gwei
    uint256 constant DEMO_AMOUNT = 0.0005 ether;

    function run() external {
        address seller = vm.envAddress("TAPELOCK_SELLER");
        address arbiter = vm.envAddress("TAPELOCK_ARBITER");

        // broadcaster comes from the CLI --private-key flag
        vm.startBroadcast();

        MockFactory factory = new MockFactory();
        MockProcessor processor = new MockProcessor();
        MockOpener opener = new MockOpener();
        factory.addCPU(address(processor));

        // tape-out the demo circuit to the seller + open its container
        processor.mint(seller, CIRCUIT);
        MockContainer container = new MockContainer(block.chainid, address(processor), CIRCUIT);
        opener.open(address(processor), CIRCUIT, address(container));

        TapeOutVerifier verifier = new TapeOutVerifier(address(factory), address(opener), 0);
        TapeLockEscrow escrow = new TapeLockEscrow(address(verifier), 1 days);

        // demo escrow: deployer is the buyer, one milestone for circuit 4246
        uint256[] memory circuits = new uint256[](1);
        circuits[0] = CIRCUIT;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = DEMO_AMOUNT;
        uint256 escrowId = escrow.createEscrow{value: DEMO_AMOUNT}(
            seller, arbiter, block.timestamp + 7 days, circuits, amounts
        );

        vm.stopBroadcast();

        console.log("chainId", block.chainid);
        console.log("factory", address(factory));
        console.log("processor", address(processor));
        console.log("opener", address(opener));
        console.log("container", address(container));
        console.log("verifier", address(verifier));
        console.log("escrow", address(escrow));
        console.log("demo escrowId", escrowId);
        console.log("seller", seller);
        console.log("buyer", msg.sender);
    }
}
