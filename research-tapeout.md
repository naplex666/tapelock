# Riset TapeOut — untuk TapeLock (X Layer TapeOut Accelerate)

Tanggal riset: 15 Nov 2026. Deadline lomba: 7 Des 2026 23:59 UTC (8 Des 06:59 WIB).
Semua alamat/angka di bawah ini diverifikasi dari sumber primer (repo TapeKit, SPEC.md, chainid.network, OKX docs) dan/atau dicek live via `cast`/curl pada 15 Nov 2026. Jangan pakai alamat dari memori — pakai yang di sini.

## 0. Temuan kunci (baca dulu)

1. **Kontrak TapeOut ADA di X Layer mainnet (chain 196)** — factory, opener, SiteRegistry, DomainBinding. `cpuCount()` live = **420 processor**.
2. **TIDAK ADA deployment TapeOut di X Layer testnet.** TapeKit hanya mengenal 3 chain: BNB 56, X Layer 196, Base 8453. Testnet tidak ada di config mana pun.
3. **Konsekuensi arsitektur:** escrow di testnet **tidak bisa** membaca state registry TapeOut mainnet secara on-chain. Pilihan (lihat §8): (A) escrow + klon processor TapeOut di testnet (demo end-to-end mandiri), (B) escrow di mainnet + verifikasi circuit asli (butuh OKB asli → gas Zec), (C) escrow testnet + attestation off-chain (kepercayaan lebih lemah). Desain verifier pluggable yang sudah dibuat sudah benar — tinggal colok alamat di §1.
4. **PoD mining / BEM tetap di BNB.** Di X Layer tidak ada mining BEM. Yang bisa dilakukan di X Layer: buat processor, buka container (0,08 OKB), kirim pesan, host website.
5. **Jangan tertukar:** token `TAPEOUTX` di X Layer (`0x16aa672dda63f5acd0de098c04c4a3e957d1eeee`) adalah proyek LAIN, bukan TapeOut Protocol (tokennya BEM, di BNB).

## 1. Kontrak TapeOut di X Layer mainnet (chain 196)

Sumber: TapeKit README "Mainnet constants" + `kernel/src/config.js` (`L2_CONTRACTS` — alamat sama di X Layer dan Base, "same account deployed them in the same order").

| Kontrak | Alamat (X Layer + Base) |
|---|---|
| Processor factory (proxy) | `0x1f09DAeFA827f02CBb40967cc91b259763760761` |
| Container opener | `0x536adD8F30f03b69f6fbF29d425A816A0dC50106` |
| SiteRegistry (proxy) | `0xd6EFb7adCc9c83dC4924Ad56f6a8E4e969b9ADB6` |
| DomainBinding (proxy) | `0x68809Fd2fb343aA57D0aeB7f33Defe477c9666f9` |
| SiteRegistry implementation (pinned) | `0xa85c4143d1d4a77f54b8e4ecc9e6d1418afea45f` |
| DomainBinding implementation (pinned) | `0x5ebf29b80789e548907c707530c3c7607c4347df` |
| Factory seal — implementation (freeze 22 Okt 2026) | `0xb41c1e7602eb5734be2430b72178ccb814a5293d` |
| Factory seal — circuitBeacon | `0xf70d1ed4f62cf3780157b0b421b7e2f45bd0991c` |
| Factory seal — circuitImplementation | `0x977f217887e085d298cb3819cdad5a0ee35f29b2` |

- **Nama on-chain X Layer:** format `<#ID>.2.<processor>.tape` (area code 2), contoh `1.2.0.tape`.
- **Freeze 22 Okt 2026:** processor di BNB, X Layer, dan Base DIBEKUKAN — kedua processor beacon sudah tanpa owner, kode processor yang sudah ada tidak bisa diubah siapa pun. Factory-nya sendiri MASIH upgradeable (bisa ubah registry processor + tabel nomor processor, tapi tidak bisa lagi menyamar sebagai container circuit yang sudah ada).
- **TapeSend/DeWEB hub HANYA live di BNB** (`0xe61A9C7213a6Aa616C246a2B569e555B417b25ee`, impl v3 `0x80aFE7B77F2dFD08e9feab7675780baC34a7EE85`, masih upgradeable sampai disegel). Tidak ada alamat hub X Layer.

### Verifikasi live (15 Nov 2026, RPC `https://rpc.xlayer.tech`)
- `cast chain-id` → **196** ✓
- Factory punya bytecode ✓
- `factory.cpuCount()` → **420** ✓
- `factory.cpuAt(0)` (Genesis) → `0x839bdD6fa7A66416A609A735e11DE5411B98574e` ✓
- `opener.accountOf(genesis, 1)` → container `0xE2E5FfD861C8a0b50Ce21A7bcbDD6Bb5aaC250aB` ✓
- `processor.ownerOf(1)` → `0x571d447f4f24688eC35Ccf07f1D6993655F6aF15` ✓
- `opener.isOpened(genesis, 1)` → **true** ✓

## 2. Interface/ABI verifier (cara membaca data circuit)

Sumber: TapeOut SPEC.md v0.2 §3.1–§3.3 + Appendix B, dan `kernel/src/selectors.js` di repo TapeKit (selector = 4 byte pertama keccak256(signature); unit test repo menghitung ulang semuanya).

### Alur resolusi (SPEC §3.2) — inilah yang dipakai verifier TapeLock
1. `factory.cpuCount()` → pastikan nomor processor < count, kalau tidak: `no-such-cpu`.
2. `factory.cpuAt(nomorProcessor)` → alamat kontrak processor.
3. `opener.accountOf(processor, #ID)` → alamat container.
4. `processor.ownerOf(#ID)` → pemilik saat ini (revert = `no-such-token`).
5. `opener.isOpened(processor, #ID)` → harus `true`, kalau tidak: `not-opened`.
6. Validasi balik: `container.token()` mengembalikan `(chainId, processor, #ID)`; `factory.isCPU(processor)` harus `true`; `opener.accountOf(...)` HARUS sama dengan alamat container input (mencegah kontrak yang sekadar mengaku container).

### Signature + selector (untuk verifier)

| Fungsi | Signature | Selector |
|---|---|---|
| Factory | `cpuCount()` → uint256 | `0xa94da8a7` |
| Factory | `cpuAt(uint256)` → address | `0x4bc7cbbd` |
| Factory | `isCPU(address)` → bool | `0x5f5a364f` |
| Opener | `accountOf(address,uint256)` → address | `0x0c1905e5` |
| Opener | `isOpened(address,uint256)` → bool | `0x8b508494` |
| Processor (ERC-721) | `ownerOf(uint256)` → address | `0x6352211e` |
| Processor | `name()` → string | `0x06fdde03` |
| Container (ERC-6551) | `token()` → (uint256 chainId, address processor, uint256 tokenId) | `0xfc0c546a` |
| SiteRegistry | `fileInfo(address,string)`, `read(address,string)`, `readRange(address,string,uint256,uint256)`, `pathCount(address)`, `pathsRange(address,uint256,uint256)`, `fallbackPath(address)` | lihat `kernel/src/selectors.js` |
| DomainBinding | `isLive(string,address)`, `paidUntil(bytes32,address)`, `monthlyFee()`, `containerPaidUntil(address)`, `isContainerLive(address)` | lihat `kernel/src/selectors.js` |

Catatan: repo TapeOutProtocol di GitHub TIDAK berisi source kontrak (hanya 3 repo publik: `TapeKit`, `TAPs`, `list` — akunnya user, bukan org, jadi `api.github.com/orgs/TapeOutProtocol` 404). ABI lengkap tidak dipublikasikan sebagai JSON; yang ada adalah signature + selector di atas (cukup untuk `cast`/ethers minimal ABI) dan interface di SPEC.md Appendix B. Kalau butuh ABI JSON penuh, ambil dari OKX explorer bila kontraknya terverifikasi di sana, atau susun minimal ABI dari signature di atas.

## 3. Referensi BNB Smart Chain (chain 56)

| Kontrak | Alamat |
|---|---|
| Processor factory | `0x68224F668083c29e9800Be2a646d42d18cedF7e2` |
| Container opener | `0x021745DE2f42A7839d96f2d3634d0294487D81F1` |
| Container implementation | `0xAf4E78a2257C9c5480c2F8310E3b00437260751d` |
| SiteRegistry (proxy) | `0xd006ffdd5Ae313B17729621A00999cD3C71CE5e6` |
| DomainBinding (proxy) | `0x861EE183de2BBE4a6ecf9D15812C123b566a3DB7` |
| DomainBinding implementation (2026-09-13) | `0xaa226181a6588d3f9AC0035e5f3dBaF311039bCE` (sebelumnya `0x4E8684EaEA48b524245B2191DeE451eAa1c1cA94`) |
| BEM token | `0x5ce033b2bfca3af30b3e8c8457deaf776a8b695a` |
| Contoh situs | `4246.0.tape` = container `0x86DDaEF00401E3F10418398D67D7189fc458eA95` |

## 4. DeWEB / TapeKit — cara deploy website on-chain

Repo: https://github.com/TapeOutProtocol/TapeKit (MIT, spec CC0). Gateway: https://tapekit.org/ — contoh situs live: https://4246-0.tapekit.org/ (dibaca dari BNB Chain).

### Langkah minimal (Site Owner Handbook, TapeKit README)
1. **Siapkan folder statis:** `index.html` di root, asset di subfolder. Path relatif saja (`./app.js`), TIDAK BOLEH URL `https://` ke file sendiri. Nama file harus Unicode NFC (pakai ASCII saja, paling aman). Hitung SHA-256 tiap file.
2. **Punya circuit + container yang sudah dibuka (opened).** Di X Layer: buat processor → buka container (biaya buka container 0,08 OKB menurut panduan TapeOut v1.5).
3. **Publish — dua cara:**
   - **A. HashPort console** (hosted, wallet-signed): pilih circuit, upload folder, sign transaksi. Hash, split chunk, fallback path diurus console.
   - **B. Direct contract calls** ke SiteRegistry (oleh holder atau operator via `setOperator`):
     - `putFile(container, path, contentType, sha256Hash, firstChunk)` — chunk pertama ≤ 24.000 byte; kalau file sudah ada, ini MENGGANTI seluruh file.
     - `appendChunk(container, path, expectIndex, chunk)` — per chunk 24.000 byte, `expectIndex` = 1, 2, 3… (index salah = revert, jadi retry tidak bisa append dobel).
     - Opsional `setFallback(container, path)` untuk SPA routing (fallback ke `index.html`).
     - `removeFile(container, path)` untuk hapus.
   - Biaya: tiap chunk di-deploy sebagai kontrak kecil — kira-kira 200 gas per byte + overhead. Minify + kompres gambar dulu; jangan publish source map / `node_modules`.
4. **Aktivasi nama:** `DomainBinding.bind("<#ID>.2.<processor>.tape", container, months)` dengan `msg.value = months × monthlyFee`. Di BNB `monthlyFee` = 0,08 BNB / 30 hari, 1–120 bulan sekali transaksi. **Di X Layer JANGAN asumsi 0,08 OKB — baca `monthlyFee()` dari kontrak DomainBinding X Layer dulu** (`0x68809Fd2fb343aA57D0aeB7f33Defe477c9666f9`). Satu pembayaran per container (kalau container sudah bayar untuk satu domain, nama on-chain ikut aktif).
5. **Tes sebelum bayar:** jalankan viewer lokal `npm run dev:viewer`, buka `http://127.0.0.1:8095/viewer/?dev#/4246.0.tape` — flag `?dev` (localhost saja) bisa preview nama yang belum diaktivasi.

### Batasan
- Chunk 24.000 byte; satu file max 350 chunk = 8,4 MB; manifest max 5.000 path; baca sekali panggil max 96 KB.
- Badge "100% on-chain" hanya kalau: tidak ada referensi off-chain di HTML/CSS (tidak ada `https://…`, CDN, font eksternal, analytics), tidak ada fetch runtime ke host luar, path relatif saja. Baca data chain via wallet provider (`window.ethereum`) BOLEH dan tidak dihitung off-chain.
- **Bisa dipakai dari X Layer testnet? TIDAK.** TapeKit hanya mengenal BNB 56, X Layer 196, Base 8453 — semuanya mainnet. Tidak ada config testnet di repo. DeWEB di testnet tidak didukung tooling resmi.

### Catatan keamanan TapeKit
- Status 13 Sep 2026: unit test 22/22, mainnet read-only 9/9, gateway E2E 25/25. **Belum diaudit independen** (per README). Kernel + gateway direncanakan diaudit; CLI publishing open-source masih di roadmap.

## 5. X Layer testnet (chain 1952) — terverifikasi

Sumber: chainid.network (data ChainList), diverifikasi live.

| Item | Nilai |
|---|---|
| Chain ID | **1952** (`0x7a0`) — terverifikasi live: `eth_chainId` ke `https://testrpc.xlayer.tech` mengembalikan `0x7a0` |
| RPC publik | `https://testrpc.xlayer.tech`, `https://xlayertestrpc.okx.com` |
| Explorer | https://web3.okx.com/explorer/x-layer-testnet (OKLink) |
| Gas token | OKB (testnet, tanpa nilai) |
| Info | https://web3.okx.com/xlayer |

**PERHATIAN:** alamat RPC yang sering disebut-sebut `https://testnet-rpc.xlayer.tech` SALAH — host itu tidak menjawab (tunnel error). Yang benar `testrpc.xlayer.tech`.

### Faucet OKB testnet
- **Resmi OKX — Faucet Center:** https://www.okx.com/web3/faucet (terverifikasi, mencantumkan "X Layer Testnet"). Syarat: connect OKX Wallet, **saldo wallet minimal 10 USD**, klaim tiap beberapa jam, max 3 alamat wallet per network address. Faucet khusus X Layer juga terdaftar di chain registry: https://www.okx.com/xlayer/faucet.
- **Chainlink Faucet:** https://faucets.chain.link/xlayer-testnet — dispenser resmi Chainlink, kirim testnet LINK + native test token untuk Xlayer Testnet (connect wallet, pilih faucet).
- **thirdweb universal faucet:** halaman chain X Layer Testnet di thirdweb, 0,01 OKB per 24 jam.
- **Zalalena (pihak ketiga, bukan OKX):** https://faucet.zalalena.com/xlayer — tanpa login, hCaptcha, max 10 klaim/hari, cooldown 60 menit. Cadangan saja.

## 6. X Layer mainnet (chain 196) — terverifikasi

| Item | Nilai |
|---|---|
| Chain ID | **196** (`0xc4`) — terverifikasi live via `cast chain-id` |
| RPC publik | `https://rpc.xlayer.tech`, `https://xlayerrpc.okx.com`, `https://xlayer.drpc.org`, `https://196.rpc.thirdweb.com` |
| Explorer | https://www.okx.com/web3/explorer/xlayer (juga https://www.oklink.com/xlayer) |
| Gas token | OKB (supply tetap 21 juta) |

Catatan TapeKit (diuji 19 Sep 2026): di X Layer hanya ada 2 operator RPC independen (OKX + dRPC); thirdweb meneruskan OKX. Untuk pembacaan yang wajib konsisten antar-node (aturan TapeKit: minimal 2 operator independen sepakat), pakai OKX + dRPC.

## 7. Contoh proyek ekosistem TapeOut (escrow/pembayaran)

- **Prom — delivery-verified payments (USD1):** diumumkan dalam TapeOut Weekly Report 12–18 Okt 2026 sebagai "three-way deal" bersama Mova: pembayaran yang diverifikasi berdasarkan pengiriman barang (delivery-verified), settlement dalam USD1. **Tidak ditemukan detail teknis publik** (tidak ada docs, alamat kontrak, atau repo) — hanya baris pengumuman itu. Ini preseden konsep yang paling dekat dengan TapeLock (bayar setelah bukti pengiriman), tapi tidak bisa dijadikan referensi implementasi.
- **Mova — stablecoin settlement:** mitra yang sama dalam deal di atas (Mova Chain: L1 untuk pembayaran + RWA, fokus settlement stablecoin). Juga hanya sebatas pengumuman.
- **Lainnya (bukan escrow):** tapeXO (raffle X terverifikasi), Tapestry (sosial fully on-chain), BEM-DRAW (raffle circuit on-chain), TapeHub (launchpad + mining economy), TapeUp (ledger lintas chain di atas DeWEB).

## 8. Implikasi untuk arsitektur TapeLock

Fakta yang mengikat: registry TapeOut hanya ada di mainnet (196). Escrow demo di testnet (1952) tidak bisa `CALL` registry mainnet.

| Opsi | Cara | Kelebihan | Kekurangan |
|---|---|---|---|
| **A. Testnet mandiri (disarankan untuk demo)** | Deploy escrow + klon minimal processor factory TapeOut (interface sama: `cpuCount/cpuAt/accountOf/isOpened/ownerOf`) di testnet 1952; tape-out circuit demo di factory klon itu; escrow verifikasi dari klon | End-to-end 100% gratis, bisa diuji siapa pun, semua langkah tercatat di testnet | Bukan registry TapeOut asli — harus dijelaskan jujur di submission ("TapeOut-compatible processor di testnet; registry produksi di mainnet 196, alamat …") |
| **B. Mainnet langsung** | Escrow deploy di mainnet 196, verifier menunjuk factory/opener asli (§1) | Integrasi TapeOut asli 100%, paling kuat di mata juri | Butuh OKB asli untuk gas + dana escrow demo; butuh persetujuan Zec sebelum keluar dana |
| **C. Testnet + attestation** | Escrow di testnet, verifier off-chain (relayer) membaca mainnet lalu submit bukti/attestation | Demo gratis + data circuit asli | Kepercayaan pindah ke relayer; lebih lemah secara trust; lebih banyak komponen |

Rekomendasi: **bangun A sekarang** (demo + video + submission lengkap tanpa biaya), dan siapkan **B sebagai upgrade** (satu ganti alamat verifier + redeploy) kalau Zec menggas OKB untuk mainnet sebelum 7 Des.

## 9. Peringatan

- Token `TAPEOUTX` (`0x16aa672dda63f5acd0de098c04c4a3e957d1eeee`, X Layer) BUKAN TapeOut Protocol. Jangan sentuh, jangan sebut di submission.
- PoD mining & BEM hanya di BNB. Klaim "mining di X Layer" = salah.
- Factory TapeOut masih upgradeable; processor sudah frozen (beacon ownerless) sejak 22 Okt 2026 — bagus untuk narasi keamanan, tapi sebutkan factory-nya masih upgradeable.
- TapeKit belum diaudit independen. Jangan klaim sudah diaudit.
- Dokumen panduan komunitas (TapeOut Complete Beginner's Guide v1.5, tapeoutdaily.ai) berguna tapi sekunder — semua alamat di atas diambil dari repo/sumber primer, bukan dari panduan itu.

## 10. Sumber

- Lomba: https://web3.okx.com/xlayer/build-x-series (deadline 7 Des 2026 23:59 UTC, pool 100.000 USDT)
- TapeKit repo: https://github.com/TapeOutProtocol/TapeKit (README Mainnet constants; `kernel/src/config.js` L2_CONTRACTS; `kernel/src/selectors.js`; SPEC.md v0.2 §3.1–§3.3 + Appendix B)
- TapeOut Protocol Proposals: https://github.com/TapeOutProtocol/TAPs
- X Layer dev docs: https://web3.okx.com/onchainos/dev-docs/xlayer/developer/build-on-xlayer/about-xlayer
- Chain registry (testnet 1952 + mainnet 196): https://chainid.network/chains.json
- Faucet resmi OKX: https://www.okx.com/web3/faucet ; faucet X Layer: https://www.okx.com/xlayer/faucet
- Chainlink faucet: https://faucets.chain.link/xlayer-testnet
- TapeOut overview (konteks): https://www.odaily.news/en/post/5213070 ; https://www.kucoin.com/blog/what-is-bem-token-tapeout-protocol-proof-of-design (alamat BEM); https://www.panews.io/articles/01a00fff-7b7f-70ff-a188-0448b4d31797
- Weekly report 12–18 Okt 2026 (Prom/Mova): https://teletype.in/@wessd6/tapeoutweekrep
