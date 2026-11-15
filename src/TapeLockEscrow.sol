// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Minimal interface to TapeOut on-chain data. The concrete adapter
/// (real TapeOut registry / Circuit NFT on X Layer) is plugged in at deploy
/// time; tests and the testnet demo use a mock with the same interface.
interface ITapeOutVerifier {
    /// @return true if `circuitId` exists on TapeOut and is owned by `owner`.
    function isCircuitOwnedBy(uint256 circuitId, address owner) external view returns (bool);
}

/// @title TapeLock — milestone escrow for commissioned TapeOut circuits.
/// @notice A buyer locks funds for a custom circuit. The seller delivers by
/// pointing at the taped-out circuit; the escrow verifies the tape-out
/// on-chain via ITapeOutVerifier before any funds move. No delivery by the
/// deadline -> refund. Dispute -> arbiter decides.
contract TapeLockEscrow {
    enum MilestoneState {
        Pending, // funded, not delivered
        Delivered, // seller delivered, awaiting buyer confirm / challenge window
        Released, // funds paid to seller
        Refunded, // funds returned to buyer
        Disputed // buyer disputed, awaiting arbiter
    }

    struct Milestone {
        uint256 amount;
        uint256 circuitId; // expected TapeOut circuit id
        MilestoneState state;
        uint256 deliveredAt;
    }

    struct Escrow {
        address buyer;
        address seller;
        address arbiter;
        uint256 deadline;
        Milestone[] milestones;
    }

    ITapeOutVerifier public immutable verifier;
    uint256 public immutable challengeWindow; // e.g. 1 day
    uint256 public nextEscrowId;
    mapping(uint256 => Escrow) private escrows;

    event EscrowCreated(uint256 indexed escrowId, address indexed buyer, address indexed seller, uint256 total);
    event Delivered(uint256 indexed escrowId, uint256 indexed milestone, uint256 circuitId);
    event Released(uint256 indexed escrowId, uint256 indexed milestone, uint256 amount);
    event Refunded(uint256 indexed escrowId, uint256 indexed milestone, uint256 amount);
    event Disputed(uint256 indexed escrowId, uint256 indexed milestone);
    event DisputeResolved(uint256 indexed escrowId, uint256 indexed milestone, bool releasedToSeller);

    error BadInput();
    error NotBuyer();
    error NotSeller();
    error NotArbiter();
    error WrongState();
    error NotVerified();
    error TooEarly();
    error Reentrancy();

    bool private locked;

    modifier nonReentrant() {
        if (locked) revert Reentrancy();
        locked = true;
        _;
        locked = false;
    }

    constructor(address _verifier, uint256 _challengeWindow) {
        if (_verifier == address(0)) revert BadInput();
        verifier = ITapeOutVerifier(_verifier);
        challengeWindow = _challengeWindow;
    }

    /// @notice Create an escrow. `msg.value` must equal the sum of amounts.
    function createEscrow(
        address seller,
        address arbiter,
        uint256 deadline,
        uint256[] calldata circuitIds,
        uint256[] calldata amounts
    ) external payable returns (uint256 escrowId) {
        if (seller == address(0) || seller == msg.sender) revert BadInput();
        if (deadline <= block.timestamp) revert BadInput();
        if (circuitIds.length == 0 || circuitIds.length != amounts.length) revert BadInput();

        uint256 total;
        for (uint256 i; i < amounts.length; i++) {
            if (amounts[i] == 0) revert BadInput();
            total += amounts[i];
        }
        if (msg.value != total) revert BadInput();

        escrowId = nextEscrowId++;
        Escrow storage e = escrows[escrowId];
        e.buyer = msg.sender;
        e.seller = seller;
        e.arbiter = arbiter;
        e.deadline = deadline;
        for (uint256 i; i < circuitIds.length; i++) {
            e.milestones.push(Milestone({amount: amounts[i], circuitId: circuitIds[i], state: MilestoneState.Pending, deliveredAt: 0}));
        }
        emit EscrowCreated(escrowId, msg.sender, seller, total);
    }

    /// @notice Seller delivers a milestone. Delivery is only accepted if the
    /// TapeOut verifier confirms the circuit exists and is owned by the seller.
    function deliver(uint256 escrowId, uint256 milestoneIndex) external {
        Escrow storage e = escrows[escrowId];
        if (msg.sender != e.seller) revert NotSeller();
        Milestone storage m = e.milestones[milestoneIndex];
        if (m.state != MilestoneState.Pending) revert WrongState();
        if (!verifier.isCircuitOwnedBy(m.circuitId, e.seller)) revert NotVerified();
        m.state = MilestoneState.Delivered;
        m.deliveredAt = block.timestamp;
        emit Delivered(escrowId, milestoneIndex, m.circuitId);
    }

    /// @notice Buyer confirms a delivered milestone -> funds to seller.
    function confirmRelease(uint256 escrowId, uint256 milestoneIndex) external nonReentrant {
        Escrow storage e = escrows[escrowId];
        if (msg.sender != e.buyer) revert NotBuyer();
        Milestone storage m = e.milestones[milestoneIndex];
        if (m.state != MilestoneState.Delivered) revert WrongState();
        m.state = MilestoneState.Released;
        (bool ok, ) = e.seller.call{value: m.amount}("");
        require(ok, "transfer failed");
        emit Released(escrowId, milestoneIndex, m.amount);
    }

    /// @notice Seller claims after the challenge window if the buyer neither
    /// confirmed nor disputed the delivery.
    function claimAfterWindow(uint256 escrowId, uint256 milestoneIndex) external nonReentrant {
        Escrow storage e = escrows[escrowId];
        if (msg.sender != e.seller) revert NotSeller();
        Milestone storage m = e.milestones[milestoneIndex];
        if (m.state != MilestoneState.Delivered) revert WrongState();
        if (block.timestamp < m.deliveredAt + challengeWindow) revert TooEarly();
        m.state = MilestoneState.Released;
        (bool ok, ) = e.seller.call{value: m.amount}("");
        require(ok, "transfer failed");
        emit Released(escrowId, milestoneIndex, m.amount);
    }

    /// @notice Buyer disputes a delivered milestone before it is released.
    function dispute(uint256 escrowId, uint256 milestoneIndex) external {
        Escrow storage e = escrows[escrowId];
        if (msg.sender != e.buyer) revert NotBuyer();
        Milestone storage m = e.milestones[milestoneIndex];
        if (m.state != MilestoneState.Delivered) revert WrongState();
        m.state = MilestoneState.Disputed;
        emit Disputed(escrowId, milestoneIndex);
    }

    /// @notice Arbiter resolves a dispute: true -> pay seller, false -> refund buyer.
    function resolveDispute(uint256 escrowId, uint256 milestoneIndex, bool releaseToSeller) external nonReentrant {
        Escrow storage e = escrows[escrowId];
        if (msg.sender != e.arbiter) revert NotArbiter();
        Milestone storage m = e.milestones[milestoneIndex];
        if (m.state != MilestoneState.Disputed) revert WrongState();
        address to = releaseToSeller ? e.seller : e.buyer;
        m.state = releaseToSeller ? MilestoneState.Released : MilestoneState.Refunded;
        (bool ok, ) = to.call{value: m.amount}("");
        require(ok, "transfer failed");
        emit DisputeResolved(escrowId, milestoneIndex, releaseToSeller);
    }

    /// @notice Buyer refunds a milestone that was never delivered past the deadline.
    function refund(uint256 escrowId, uint256 milestoneIndex) external nonReentrant {
        Escrow storage e = escrows[escrowId];
        if (msg.sender != e.buyer) revert NotBuyer();
        Milestone storage m = e.milestones[milestoneIndex];
        if (m.state != MilestoneState.Pending) revert WrongState();
        if (block.timestamp < e.deadline) revert TooEarly();
        m.state = MilestoneState.Refunded;
        (bool ok, ) = e.buyer.call{value: m.amount}("");
        require(ok, "transfer failed");
        emit Refunded(escrowId, milestoneIndex, m.amount);
    }

    // ---- views ----

    function getEscrow(uint256 escrowId)
        external
        view
        returns (address buyer, address seller, address arbiter, uint256 deadline, uint256 milestoneCount)
    {
        Escrow storage e = escrows[escrowId];
        return (e.buyer, e.seller, e.arbiter, e.deadline, e.milestones.length);
    }

    function getMilestone(uint256 escrowId, uint256 milestoneIndex)
        external
        view
        returns (uint256 amount, uint256 circuitId, MilestoneState state, uint256 deliveredAt)
    {
        Milestone storage m = escrows[escrowId].milestones[milestoneIndex];
        return (m.amount, m.circuitId, m.state, m.deliveredAt);
    }
}
