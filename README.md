# TapeLock — Milestone Escrow for TapeOut Circuits

**X Layer TapeOut Accelerate (OKX) — submission deadline 7 Dec 2026 23:59 UTC (8 Dec 06:59 WIB). Prize pool 100,000 USDT.**

## Problem
Commissioning a custom on-chain circuit on TapeOut is trust-based today: the
buyer pays upfront and hopes the designer delivers, or the designer works
unpaid and hopes to get paid. There is no trust-minimized way to pay for a
tape-out.

## Product
TapeLock is a milestone escrow on X Layer. A buyer locks funds; a seller
delivers a taped-out circuit (TapeOut Circuit NFT / circuit ID); the escrow
verifies the tape-out **on-chain against TapeOut data** and releases the
funds. No delivery by the deadline → automatic refund. Dispute → arbiter.

- **Buyer:** creates an escrow with milestones, each tied to a TapeOut
  circuit ID + amount. Funds the full amount upfront.
- **Seller:** delivers each milestone by pointing at the taped-out circuit.
  The contract verifies the circuit exists (and is owned by the seller) via
  the TapeOut registry before any release.
- **Release:** verified delivery + buyer confirmation (or auto-release after
  the challenge window) → funds to the seller. Timeout without delivery →
  refund to the buyer.

## How it uses TapeOut
- Escrow milestones reference real TapeOut circuit IDs; release is gated on
  on-chain TapeOut circuit data (registry / Circuit NFT ownership).
- Demo frontend is served as a DeWEB site (TapeKit container) where
  feasible, otherwise as a static demo link.
- Interfaces and off-chain parts run outside circuits (allowed by the rules);
  the money logic and the verification hook live on-chain.

## Tech
- Contracts: Solidity + Foundry (`src/`), tests in `test/`
- Chain: X Layer testnet for the demo (mainnet-ready logic)
- Frontend: `app/` — static demo (create escrow, deliver, release, refund)

## Status
- 15 Nov 2026: rebuild from zero — the pre-reset code did not survive
  (no GitHub repo, no local files). Researching TapeOut contracts on
  X Layer + DeWEB deploy flow first; contract interface keeps the TapeOut
  verifier pluggable (`ITapeOutVerifier`) so the real registry address/ABI
  drops in when confirmed.

## Submission checklist
- [ ] Contracts deployed on X Layer testnet (addresses recorded)
- [ ] End-to-end escrow test with real transaction proof
- [ ] Demo link (DeWEB preferred)
- [ ] Demo video ≤ 3 min, no audio
- [ ] Write-up: product, users, revenue model, TapeOut usage
- [ ] Submit via official form before 7 Dec 2026 23:59 UTC

## Dev
```shell
forge install   # forge-std
forge build
forge test      # 10 tests: escrow flows + TapeOut verifier
```

## Deploy (X Layer testnet, chain 1952)
```shell
# fund the deployer with testnet OKB first (faucet), then:
export TAPELOCK_SELLER=<seller address>
export TAPELOCK_ARBITER=<arbiter address>
forge script --rpc-url https://testrpc.xlayer.tech \
  --private-key $PRIVATE_KEY --sender $DEPLOYER --legacy \
  --broadcast script/DeployTestnet.s.sol:DeployTestnet
```
See `DEPLOYMENT.md` for the live addresses + end-to-end tx proof.
Demo frontend: `app/` (static, open `index.html` or serve via GitHub Pages).
