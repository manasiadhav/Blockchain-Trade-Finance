BLOCKCHAIN IN TRADE FINANCE

ABSTRACT
The globalization of markets has significantly increased the volume of international trade, making
efficiency, security, and transparency critical requirements. Traditional trade finance
mechanisms rely heavily on intermediaries such as banks, letter of credit issuers, and document
verification agencies. Although effective, these intermediaries create delays, higher transaction
costs, and risks of fraud. This project demonstrates a blockchain-based escrow smart contract
using Solidity to automate payment release, document verification, shipment tracking, and
dispute resolution in trade finance
1. PROJECT OVERVIEW
1.1 BACKGROUND AND MOTIVATION
International trade involves multiple parties and is subject to disputes regarding quality of goods,
document validity, shipment delays, and payment guarantees. Blockchain offers
decentralization, immutability, and automation through smart contracts.
1.2 OBJECTIVES
1. Design a trade finance escrow smart contract.
2. Automate secure payment release.
3. Provide dispute resolution.
4. Test normal and dispute scenarios in Remix IDE.
1.3 SCOPE
The prototype simulates Buyer, Seller, Verifier, and Arbitrator roles on Ethereum (Remix IDE,
Solidity 0.8.x). Deployment and execution are demonstrated using test accounts in a simulated
blockchain environment.
2. TECHNICAL ARCHITECTURE
The technical architecture of the Trade Finance Escrow smart contract is best illustrated
through the diagram shown above. It highlights the interaction between the key stakeholders—
Buyer, Seller, Verifier, Arbitrator, and the Escrow Contract—during the lifecycle of a trade
transaction.
1. Funding Stage
o The Buyer initiates the transaction by funding the escrow contract with the
agreed amount (e.g., 1 ETH).
o This ensures that the Seller has confidence in the Buyer’s commitment, while
funds remain securely locked in the contract.
2. Verification Stage
o The Verifier uploads and validates the trade documents by setting a document
hash on-chain.
o This step guarantees authenticity of the transaction and prevents fraudulent
claims.
3. Shipment Stage
o The Seller confirms shipment of goods by calling the markShipped() function.
o This action is logged on the blockchain, providing a tamper-proof record of
shipment.
4. Delivery Confirmation
o The Buyer, upon receiving the goods, confirms delivery by calling
confirmDelivery().
o This step signifies buyer satisfaction and readiness to proceed with payment
release.
5. Payment Release
o The Verifier (or an authorized authority) calls releasePayment().
o Funds are then transferred from the escrow contract to the Seller’s wallet,
completing the transaction.
6. Dispute Handling (Alternative Flow)
o If the Buyer is dissatisfied (e.g., goods not matching), they can raise a dispute by
calling raiseDispute().
o The Arbitrator steps in and resolves the dispute by invoking
resolveDispute(splitRatioBuyer, splitRatioSeller).
o Depending on the resolution, funds are split between Buyer and Seller in a fair
manner.
7. Event Logging & Transparency
o Each key action (Funded, Verified, Shipped, Delivered, Released, Disputed,
Resolved) emits blockchain events.
o These events provide an immutable audit trail for compliance and
accountability.
3. SMART CONTRACT CODE EXPLANATION
The code is divided into several logical modules:
3.1 State Variables
address public buyer;
address public seller;
address public verifier;
address public arbitrator;
uint public amount;
bytes32 public documentHash;
bool public isShipped;
bool public isDelivered;
bool public isDisputed;
These represent participants, funds, and transaction state flags.
3.2 Events
event Funded(address buyer, uint amount);
event DocumentVerified(address verifier, bytes32 documentHash);
event Shipped(address seller);
event Delivered(address buyer);
event Released(address seller, uint amount);
event DisputeRaised(address buyer, string reason);
event DisputeResolved(address arbitrator, uint sellerAmount, uint buyerAmount);
Events act as on-chain logs visible to all participants. They prove actions occurred.
3.3 Constructor
constructor(address _seller, address _verifier, address _arbitrator) payable {
 buyer = msg.sender;
 seller = _seller;
 verifier = _verifier;
 arbitrator = _arbitrator;
}
Executed only once during deployment. It binds roles to specific Ethereum addresses.
3.4 Core Functions
1. Funding Escrow (Buyer)
function fund() external payable {
 require(msg.sender == buyer, "Only buyer can fund");
 amount = msg.value;
 emit Funded(msg.sender, msg.value);
}
2. Document Verification (Verifier)
function setDocumentHash(bytes32 _hash) external {
 require(msg.sender == verifier, "Only verifier can set hash");
 documentHash = _hash;
 emit DocumentVerified(msg.sender, _hash);
}
3. Shipment Update (Seller)
function markShipped() external {
 require(msg.sender == seller, "Only seller can mark shipped");
 isShipped = true;
 emit Shipped(msg.sender);
}
4. Delivery Confirmation (Buyer)
function confirmDelivery() external {
 require(msg.sender == buyer, "Only buyer can confirm delivery");
 require(isShipped, "Shipment not marked");
 isDelivered = true;
 emit Delivered(msg.sender);
}
5. Payment Release (Verifier)
function releasePayment() external {
 require(msg.sender == verifier, "Only verifier can release payment");
 require(isDelivered, "Delivery not confirmed");
 payable(seller).transfer(amount);
 emit Released(seller, amount);
}
6. Dispute Raising (Buyer)
function raiseDispute(string memory reason) external {
 require(msg.sender == buyer, "Only buyer can raise dispute");
 isDisputed = true;
 emit DisputeRaised(msg.sender, reason);
}
7. Dispute Resolution (Arbitrator)
function resolveDispute(uint sellerPercent, uint buyerPercent) external {
 require(msg.sender == arbitrator, "Only arbitrator can resolve dispute");
 require(isDisputed, "No dispute raised");
 uint sellerShare = (amount * sellerPercent) / 100;
 uint buyerShare = (amount * buyerPercent) / 100;
 payable(seller).transfer(sellerShare);
 payable(buyer).transfer(buyerShare);
 emit DisputeResolved(msg.sender, sellerShare, buyerShare);
}
4. TESTING AND RESULTS
The project was tested on Remix IDE. Accounts were assigned to Buyer, Seller, Verifier, and
Arbitrator roles.
Steps:
1. Buyer funds contract.
2. Verifier sets document hash.
3. Seller marks shipment.
4. Buyer confirms delivery.
5. Verifier releases payment.
ACCOUNT
0x4B2...C02db (99.999999999999790192 ETH)
0x5B3...eddC4 (98.999999999989281856 ETH)
0xAb8...35cb2 (100.999999999999939818 ETH)
0x4B2...C02db (99.999999999999790192 ETH)
decoded output
logs
raw logs
"from": "Øxd9145CCE52D386f254917e481eB44e9943F39138",
"topic":
"Øxb21fb52d5749b80f3182f8c6992236b5e5576681880914484d7f4c9b062e619e",
"event": "Released",
"args": {
"0": "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2",
"1": "1000000000000000000"
}
"logIndex": "0x1",
"blockNumber": "Ox7",
"blockHash": "0x29bdeab72bf1034078e526bab6583196bd02b4407b75087080c0aa44f3877dof",
"transactionHash":
"0xe7a6dd292563d8d26257a97f851530422f0d89cef03e310ea08a0535a914a3e6",
"transactionIndex": "0x0",
"address": "0xd9145CCE52D386f254917e481eB44e9943F39138",
"data": "Øx0000000000000000000000000000000000000000000000000de0b6b3a7640000",
"topics": [
"Øxb21fb52d5749b80f3182f8c6992236b5e5576681880914484d7f4c9b062e619e",
0000000000000ab8483f64d9c6d1ecf9b849ae677dd3315835cb2"
REMIX v0.70.0
DEPLOY & RUN
TRANSACTIONS
Compile Π Home
default_workspace
Settings TradeFinanceEscrow.sol ☐ scenario.json Π CT
Duyer: Tunas the trade and contirms delivery
16 * seller: ships goods ENVIRONMENT Π Π Reset State 17 * verifier: sets/approves the document hash (can be seller or a 3rd par
Remix VM (Cancun) 18 * arbitrator: resolves disputes
19
VM
X Explain contract
ACCOUNT +
0x4B2...C02db (99.99999999...
GAS LIMIT
Estimated Gas
Π
Al copilot
0 Listen on all transactions 미 Filter with transaction hash or ad...
[vm] from: 0x4B2...C02db to: TradeFinanceEscrow.releasePayment() 0xd91...39138
value: 0 wei data: 0xd11...6c8c4 logs: 1 hash: 0xe7a...4а3еб Debug
status
Custom 3000000 transaction hash
VALUE
0
CONTRACT
0x1 Transaction mined and execution succeed
Øxe7a6dd292563d8d26257a97f851530422f0d89cef03e310ea08a0535a914a3e6
block hash 0x29bdeab72bf1034078e526bab6583196bd02b4407b75087080c0aa44f3877døf D
Wei block number 70
from 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
TradeFinanceEscrow.releasePayment() 0xd9145CCE52D386f254917e481eB44e9943F39138 to
TradeFinanceEscrow - contracts/Trade
gas 97391 gas
evm version: shanghai
transaction cost Deploy address_buyer, address_seller, Π
51830 gas
execution cost Publish to IPFS 43723 gas
input
At Address Load contract from Address
output
0xd11.. .6c8c4
0x
5. Conclusion
This project demonstrates how blockchain can transform trade finance by replacing traditional
intermediaries with secure, transparent, and automated smart contracts. The escrow system
implemented ensures fairness, reduces cost, and increases trust. Future extensions could
include IoT integration for shipment tracking and on-chain arbitration mechanisms for more
complex disputes.


