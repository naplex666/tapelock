// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ITapeOutVerifier} from "../src/TapeLockEscrow.sol";

/// @notice Test stand-in for the real TapeOut registry. The production
/// adapter will read the real Circuit NFT / registry on X Layer.
contract MockTapeOutVerifier is ITapeOutVerifier {
    mapping(uint256 => address) public circuitOwner;

    function setCircuit(uint256 circuitId, address owner) external {
        circuitOwner[circuitId] = owner;
    }

    function isCircuitOwnedBy(uint256 circuitId, address owner) external view returns (bool) {
        return circuitOwner[circuitId] != address(0) && circuitOwner[circuitId] == owner;
    }
}
