// TapeLock demo frontend — talks to the escrow + verifier on X Layer testnet.
const $ = (id) => document.getElementById(id);
const logEl = $("log");
const STATES = ["Pending", "Delivered", "Released", "Refunded", "Disputed"];

function log(msg) {
  logEl.textContent += "\n" + msg;
  logEl.scrollTop = logEl.scrollHeight;
}

let provider, signer, escrow, verifier;

async function getContracts() {
  if (!signer) throw new Error("Connect your wallet first.");
  if (!escrow) {
    provider = new ethers.BrowserProvider(window.ethereum);
    signer = await provider.getSigner();
    escrow = new ethers.Contract(TAPELOCK_CONFIG.escrowAddress, ESCROW_ABI, signer);
    verifier = new ethers.Contract(TAPELOCK_CONFIG.verifierAddress, VERIFIER_ABI, signer);
  }
  return { escrow, verifier };
}

function needAddresses() {
  if (TAPELOCK_CONFIG.escrowAddress.startsWith("0x0000")) {
    throw new Error("Demo contracts are not deployed yet — addresses still placeholders.");
  }
}

$("connectBtn").onclick = async () => {
  try {
    if (!window.ethereum) return log("No wallet found. Install MetaMask or OKX Wallet.");
    provider = new ethers.BrowserProvider(window.ethereum);
    await provider.send("eth_requestAccounts", []);
    signer = await provider.getSigner();
    $("account").textContent = "Connected: " + (await signer.getAddress());
    log("Wallet connected.");
  } catch (e) { log("Connect failed: " + (e.reason || e.message)); }
};

$("networkBtn").onclick = async () => {
  try {
    await window.ethereum.request({
      method: "wallet_addEthereumChain",
      params: [{
        chainId: "0x7a0",
        chainName: "X Layer Testnet",
        nativeCurrency: { name: "OKB", symbol: "OKB", decimals: 18 },
        rpcUrls: [TAPELOCK_CONFIG.rpcUrl],
        blockExplorerUrls: [TAPELOCK_CONFIG.explorer]
      }]
    });
    log("Switched to X Layer Testnet (1952).");
  } catch (e) { log("Network switch failed: " + (e.reason || e.message)); }
};

$("createBtn").onclick = async () => {
  try {
    needAddresses();
    const { escrow } = await getContracts();
    const amount = ethers.parseEther($("amount").value);
    const deadline = Math.floor(Date.now() / 1000) + Number($("days").value) * 86400;
    const tx = await escrow.createEscrow(
      $("seller").value, $("arbiter").value, deadline,
      [Number($("circuitId").value)], [amount], { value: amount }
    );
    log("createEscrow sent: " + tx.hash);
    const rc = await tx.wait();
    const evt = rc.logs.map((l) => { try { return escrow.interface.parseLog(l); } catch { return null; } }).find(Boolean);
    if (evt) { $("escrowId").value = evt.args.escrowId.toString(); log("Escrow created, ID " + evt.args.escrowId); }
  } catch (e) { log("Create failed: " + (e.reason || e.message)); }
};

async function act(fnName, label) {
  try {
    needAddresses();
    const { escrow } = await getContracts();
    const id = Number($("escrowId").value);
    const tx = await escrow[fnName](id, 0);
    log(label + " sent: " + tx.hash);
    await tx.wait();
    log(label + " confirmed.");
    refreshStatus();
  } catch (e) { log(label + " failed: " + (e.reason || e.message)); }
}

$("deliverBtn").onclick = () => act("deliver", "Deliver");
$("confirmBtn").onclick = () => act("confirmRelease", "Confirm release");
$("claimBtn").onclick = () => act("claimAfterWindow", "Claim after window");
$("refundBtn").onclick = () => act("refund", "Refund");

async function refreshStatus() {
  try {
    needAddresses();
    const { escrow } = await getContracts();
    const id = Number($("escrowId").value);
    const e = await escrow.getEscrow(id);
    const m = await escrow.getMilestone(id, 0);
    $("status").textContent =
      `Escrow #${id} — buyer ${e[0].slice(0, 10)}…, seller ${e[1].slice(0, 10)}…, ` +
      `deadline ${new Date(Number(e[3]) * 1000).toLocaleString()}, ` +
      `milestone 0: ${ethers.formatEther(m[0])} OKB, circuit #${m[1]}, state ${STATES[m[2]]}.`;
  } catch (e) { $("status").textContent = "Status failed: " + (e.reason || e.message); }
}
$("refreshBtn").onclick = refreshStatus;

$("verifyBtn").onclick = async () => {
  try {
    needAddresses();
    const { verifier } = await getContracts();
    const ok = await verifier.isCircuitOwnedBy(Number($("verifyCircuit").value), $("verifyOwner").value);
    $("verifyResult").textContent = ok
      ? "✅ Circuit exists on TapeOut and is owned by that address."
      : "❌ Not verified — circuit missing, not opened, or owned by someone else.";
  } catch (e) { $("verifyResult").textContent = "Verify failed: " + (e.reason || e.message); }
};

log("Ready. Connect a wallet on X Layer Testnet to begin.");
