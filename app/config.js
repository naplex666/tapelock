// TapeLock demo config — fill in after the testnet deploy.
// Chain: X Layer testnet (1952), RPC https://testrpc.xlayer.tech
const TAPELOCK_CONFIG = {
  chainId: 1952,
  chainName: "X Layer Testnet",
  rpcUrl: "https://testrpc.xlayer.tech",
  explorer: "https://web3.okx.com/explorer/x-layer-testnet",
  // Deployed on X Layer testnet (1952), 15 Nov 2026 — see DEPLOYMENT.md
  escrowAddress: "0xeF2C03258a5061a11d2223DfC6FCD6873fF9C859",
  verifierAddress: "0x04453a9723b4F452418c75AB58eCb6Cd8d8582e1",
  factoryAddress: "0xba541053ee789f37d557d6f9cabc111ffd65d8a8",
  processorAddress: "0x4016f84a30870c1dfca58ba71f6b6bedc74e2792",
  demoCircuitId: 4246,
  challengeWindowSeconds: 86400
};

const ESCROW_ABI = [
  "function createEscrow(address seller, address arbiter, uint256 deadline, uint256[] circuitIds, uint256[] amounts) payable returns (uint256)",
  "function deliver(uint256 escrowId, uint256 milestoneIndex)",
  "function confirmRelease(uint256 escrowId, uint256 milestoneIndex)",
  "function claimAfterWindow(uint256 escrowId, uint256 milestoneIndex)",
  "function dispute(uint256 escrowId, uint256 milestoneIndex)",
  "function resolveDispute(uint256 escrowId, uint256 milestoneIndex, bool releaseToSeller)",
  "function refund(uint256 escrowId, uint256 milestoneIndex)",
  "function getEscrow(uint256 escrowId) view returns (address buyer, address seller, address arbiter, uint256 deadline, uint256 milestoneCount)",
  "function getMilestone(uint256 escrowId, uint256 milestoneIndex) view returns (uint256 amount, uint256 circuitId, uint8 state, uint256 deliveredAt)",
  "event EscrowCreated(uint256 indexed escrowId, address indexed buyer, address indexed seller, uint256 total)",
  "event Delivered(uint256 indexed escrowId, uint256 indexed milestone, uint256 circuitId)",
  "event Released(uint256 indexed escrowId, uint256 indexed milestone, uint256 amount)",
  "event Refunded(uint256 indexed escrowId, uint256 indexed milestone, uint256 amount)"
];

const VERIFIER_ABI = [
  "function isCircuitOwnedBy(uint256 tokenId, address owner) view returns (bool)",
  "function factory() view returns (address)",
  "function opener() view returns (address)",
  "function processorNumber() view returns (uint256)"
];
