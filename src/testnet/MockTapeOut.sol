// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice TapeOut-compatible testnet clone (minimal). Implements exactly the
/// selectors TapeOutVerifier reads — cpuCount/cpuAt/isCPU, accountOf/isOpened,
/// ownerOf, token() — so the verifier + escrow run the same code path on
/// testnet (1952) as they will on mainnet (196). NOT the real TapeOut
/// protocol; the submission states this honestly.
contract MockProcessor {
    string public name = "TapeLock Demo CPU";
    mapping(uint256 => address) private _owners;

    event Minted(address indexed to, uint256 indexed tokenId);

    function mint(address to, uint256 tokenId) external {
        require(_owners[tokenId] == address(0), "exists");
        _owners[tokenId] = to;
        emit Minted(to, tokenId);
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "no-such-token");
        return owner;
    }
}

contract MockOpener {
    mapping(address => mapping(uint256 => address)) private _accounts;
    mapping(address => mapping(uint256 => bool)) private _opened;

    function open(address processor, uint256 tokenId, address container) external {
        _accounts[processor][tokenId] = container;
        _opened[processor][tokenId] = true;
    }

    function accountOf(address processor, uint256 tokenId) external view returns (address) {
        return _accounts[processor][tokenId];
    }

    function isOpened(address processor, uint256 tokenId) external view returns (bool) {
        return _opened[processor][tokenId];
    }
}

contract MockFactory {
    address[] private _cpus;

    function addCPU(address processor) external returns (uint256) {
        _cpus.push(processor);
        return _cpus.length - 1;
    }

    function cpuCount() external view returns (uint256) {
        return _cpus.length;
    }

    function cpuAt(uint256 index) external view returns (address) {
        return _cpus[index];
    }

    function isCPU(address cpu) external view returns (bool) {
        for (uint256 i; i < _cpus.length; i++) {
            if (_cpus[i] == cpu) return true;
        }
        return false;
    }
}

contract MockContainer {
    uint256 private immutable _chainId;
    address private immutable _processor;
    uint256 private immutable _tokenId;

    constructor(uint256 chainId_, address processor_, uint256 tokenId_) {
        _chainId = chainId_;
        _processor = processor_;
        _tokenId = tokenId_;
    }

    function token() external view returns (uint256 chainId, address processor, uint256 tokenId) {
        return (_chainId, _processor, _tokenId);
    }
}
