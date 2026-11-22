# TapeLock — Submission Package (X Layer TapeOut Accelerate)

## Links
- Repo: https://github.com/naplex666/tapelock
- Demo app: https://naplex666.github.io/tapelock/app/
- Demo video (YouTube, public, 22 Nov 2026): https://www.youtube.com/watch?v=5Lvn3qxlvNY
  (file: `video/tapelock-demo.mp4`, 1:19, silent; channel Pojok Kanan, @pojokkanan1405.
  First upload went to the wrong channel @pojokkanan8937 by mistake and was deleted.)
- X Layer testnet explorer: https://web3.okx.com/explorer/x-layer-testnet

## What it is
TapeLock is a milestone escrow for commissioned TapeOut circuits.
A buyer locks funds; a circuit designer delivers a taped-out circuit;
the escrow verifies the tape-out **on-chain against the TapeOut registry**
before releasing funds. No delivery by the deadline → automatic refund.
Disputes go to a named arbiter.

## Problem
Custom circuits are commissioned on pure trust today: buyers pay upfront
and risk never receiving the circuit; designers work unpaid and risk never
being paid. There is no delivery-verified payment anywhere in the
TapeOut ecosystem.

## Target users & how to reach them
- **Buyers:** teams that need custom on-chain logic (games, DeFi, AI agents)
  but cannot design circuits themselves. Reached via the TapeOut community,
  X Layer builders, and hackathon/demo channels.
- **Sellers:** circuit designers (TapeOut creators, PoD miners, hardware
  engineers) who want paid commissions without chasing invoices.
- **Why they pay & stay:** the escrow removes the trust problem on both
  sides; the verifier makes delivery provable, so repeat commissions can
  run through the same contract without renegotiating trust.

## Revenue model
A small protocol fee (e.g. 1% of released milestones) on each escrow,
paid from the released amount. No fee on refunds. Fee switchable by
governance later; the demo charges 0%.

## How TapeOut is used
- The verifier contract resolves a circuit ID through the real TapeOut
  registry: `factory.cpuAt(n)` → processor, `opener.accountOf` →
  container, `processor.ownerOf(id)` → owner, plus `isOpened` and
  `token()` checks (SPEC §3.2). Delivery only succeeds when the circuit
  exists, is opened, and is owned by the seller.
- Processor contract (mainnet, X Layer 196): `0x839bdD6fa7A66416A609A735e11DE5411B98574e`
  (Genesis, cpu #0). Registry factory: `0x1f09DAeFA827f02CBb40967cc91b259763760761`.
- Circuit ID in the demo: **4246**.
- Verified against the live mainnet registry on a fork (block 75980008):
  real owner → true, wrong owner → false, nonexistent circuit → false.

## Deployed demo (X Layer testnet, chain 1952)
- Escrow: `0xeF2C03258a5061a11d2223DfC6FCD6873fF9C859`
- Verifier: `0x04453a9723b4F452418c75AB58eCb6Cd8d8582e1`
- Demo processor (TapeOut-compatible clone): `0x4016f84a30870c1dfca58ba71f6b6bedc74e2792`
- Full tx proof in `DEPLOYMENT.md`: createEscrow → deliver (circuit 4246
  verified, block 46293440) → confirmRelease (seller paid exactly
  0.0005 OKB, block 46293456).

## Honest note (also in DEPLOYMENT.md)
TapeOut has no deployment on X Layer **testnet**, so the demo runs against
a TapeOut-compatible processor clone with the exact same selectors.
The verifier is the same code that reads the real registry — on mainnet
it points at the real factory/opener above.

## Status
- 10/10 Foundry tests pass (escrow flows + verifier incl. end-to-end).
- Deployed + end-to-end proven on testnet 15 Nov 2026.
- Demo app live on GitHub Pages; video ready (1:19, no audio).

## Remaining step for the final submit (via main chat)
1. Fill the official form at web3.okx.com/xlayer/build-x-series with the
   write-up above + the YouTube link + repo/demo links.
2. Submit before **7 Dec 2026 23:59 UTC (8 Dec 06:59 WIB)**.
   (Video already public on YouTube since 22 Nov 2026 — no further step needed from Zec.)
