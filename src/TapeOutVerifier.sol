// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ITapeOutVerifier} from "./TapeLockEscrow.sol";

interface ITapeOutFactory {
    function cpuCount() external view returns (uint256);
    function cpuAt(uint256 index) external view returns (address);
    function isCPU(address cpu) external view returns (bool);
}

interface ITapeOutOpener {
    function accountOf(address processor, uint256 tokenId) external view returns (address);
    function isOpened(address processor, uint256 tokenId) external view returns (bool);
}

interface ITapeOutProcessor {
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface ITapeOutContainer {
    function token() external view returns (uint256 chainId, address processor, uint256 tokenId);
}

/// @title TapeOutVerifier — TapeLock's proof hook into TapeOut.
/// @notice Verifies a circuit following TapeOut SPEC.md §3.2 resolution:
/// factory.cpuAt(processorNumber) -> processor; opener.isOpened must be true;
/// opener.accountOf must match the container; container.token() must round-trip
/// to (chainId, processor, tokenId); processor.ownerOf(tokenId) == owner.
/// @dev Same code runs against the real mainnet registry (chain 196:
/// factory 0x1f09DAeFA827f02CBb40967cc91b259763760761,
/// opener 0x536adD8F30f03b69f6fbF29d425A816A0dC50106) and against the
/// TapeOut-compatible testnet clone in src/testnet/ — swapping chains is a
/// one-line address change at deploy time.
contract TapeOutVerifier is ITapeOutVerifier {
    address public immutable factory;
    address public immutable opener;
    uint256 public immutable processorNumber;
    uint256 public immutable chainId;

    constructor(address _factory, address _opener, uint256 _processorNumber) {
        factory = _factory;
        opener = _opener;
        processorNumber = _processorNumber;
        chainId = block.chainid;
    }

    function isCircuitOwnedBy(uint256 tokenId, address owner) external view returns (bool) {
        ITapeOutFactory f = ITapeOutFactory(factory);
        if (processorNumber >= f.cpuCount()) return false;
        address processor = f.cpuAt(processorNumber);
        if (!f.isCPU(processor)) return false;

        ITapeOutOpener o = ITapeOutOpener(opener);
        if (!o.isOpened(processor, tokenId)) return false;
        address container = o.accountOf(processor, tokenId);
        if (container == address(0)) return false;

        (uint256 cChain, address cProc, uint256 cId) = ITapeOutContainer(container).token();
        if (cChain != chainId || cProc != processor || cId != tokenId) return false;

        // ownerOf reverts for nonexistent tokens (ERC-721) — treat as not verified.
        try ITapeOutProcessor(processor).ownerOf(tokenId) returns (address currentOwner) {
            return currentOwner == owner;
        } catch {
            return false;
        }
    }
}
