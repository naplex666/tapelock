# TapeLock — Testnet Deployment (X Layer testnet, chain 1952)

Deployed 15 Nov 2026 with 0.001 testnet OKB from the Zalalena faucet
(tx `0xa6397e8d7e3bf0277187c96d13748584783a94da1cac2afe5e971f13027bab44`).
Explorer: https://web3.okx.com/explorer/x-layer-testnet

## Contracts

| Contract | Address |
|---|---|
| MockFactory (TapeOut-compatible clone) | `0xba541053ee789f37d557d6f9cabc111ffd65d8a8` |
| MockProcessor (demo CPU, circuit NFT) | `0x4016f84a30870c1dfca58ba71f6b6bedc74e2792` |
| MockOpener | `0x7f8912fcd241fd2456874b14ba8939a64a0df3a1` |
| MockContainer (circuit 4246) | `0x2DB732BE5A46CBC103fc03F0F8174054AC0aFb66` |
| TapeOutVerifier | `0x04453a9723b4F452418c75AB58eCb6Cd8d8582e1` |
| TapeLockEscrow | `0xeF2C03258a5061a11d2223DfC6FCD6873fF9C859` |

## Accounts (demo only, testnet, no value)

- Buyer/deployer/arbiter: `0x3Fe20F12c3fc578D662d95F3e000426848e40274`
- Seller: `0x7479B51bA685eF17B3F578a5720337A98e53e3cb`

## End-to-end proof (escrow #0, circuit 4246, 0.0005 OKB)

| Step | Tx | Block | Result |
|---|---|---|---|
| Deploy escrow | `0xf3f599f68de9b98b36770d9788960ee730dae78a69acf906d7c1aa543bac1d33` | — | escrow deployed |
| createEscrow | `0x49d2653414aeb064b7d0309cfe102780648fa81188053439c52261d74b1da8a5` | — | escrow #0 funded 0.0005 OKB |
| deliver (seller) | `0x3247b77107f7ba5f64163807d3314cf19c300813bf18bd08ec341d21e819fe2e` | 46293440 | Delivered event, circuit 4246 verified on-chain |
| confirmRelease (buyer) | `0x7ebb5cdd1cdbd80392b1b314f2396a744195cb9220bb66d2d7d57d187dd164c3` | 46293456 | Released event; seller +0.0005 OKB exactly |

Final milestone state: `Released` (2). Seller balance went
`97776559888828` → `597776559888828` wei (+500000000000000 = 0.0005 OKB).

## Honest note for the submission

TapeOut has no deployment on X Layer testnet, so the demo runs against a
TapeOut-compatible processor clone (same selectors: `cpuCount`/`cpuAt`/
`isCPU`/`accountOf`/`isOpened`/`ownerOf`/`token()`). The verifier is the
exact code that reads the real registry — on mainnet (196) it points at
factory `0x1f09DAeFA827f02CBb40967cc91b259763760761` and opener
`0x536adD8F30f03b69f6fbF29d425A816A0dC50106`, verified against the live
Genesis circuit #1 on a mainnet fork (block 75980008): real owner → true,
wrong owner → false, nonexistent circuit → false.
