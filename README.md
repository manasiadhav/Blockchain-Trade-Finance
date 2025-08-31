# 📦 Blockchain in Trade Finance  

## 📌 Abstract  
The globalization of markets has significantly increased the volume of international trade, making **efficiency, security, and transparency** critical requirements.  

Traditional trade finance mechanisms rely heavily on intermediaries such as **banks, letter of credit issuers, and document verification agencies**. Although effective, these intermediaries create delays, higher transaction costs, and risks of fraud.  

This project demonstrates a **blockchain-based escrow smart contract** using **Solidity** to automate:  
- ✅ Payment release  
- ✅ Document verification  
- ✅ Shipment tracking  
- ✅ Dispute resolution  

---

## 📖 Project Overview  

### 🔹 Background and Motivation  
International trade involves multiple parties and is subject to disputes regarding:  
- Quality of goods  
- Document validity  
- Shipment delays  
- Payment guarantees  

Blockchain offers **decentralization, immutability, and automation** through smart contracts.  

### 🔹 Objectives  
1. Design a trade finance escrow smart contract.  
2. Automate secure payment release.  
3. Provide dispute resolution.  
4. Test normal and dispute scenarios in Remix IDE.  

### 🔹 Scope  
The prototype simulates **Buyer, Seller, Verifier, and Arbitrator** roles on Ethereum (Remix IDE, Solidity 0.8.x).  
Deployment and execution are demonstrated using **test accounts in a simulated blockchain environment**.  

---

## ⚙️ Technical Architecture  

The technical architecture of the **Trade Finance Escrow smart contract** is shown below:  

![Architecture Diagram](images/architecture.png)  

**Lifecycle Stages:**  
1. **Funding Stage** – Buyer funds the escrow contract (e.g., 1 ETH).  
2. **Verification Stage** – Verifier sets document hash to ensure authenticity.  
3. **Shipment Stage** – Seller marks goods as shipped.  
4. **Delivery Confirmation** – Buyer confirms goods received.  
5. **Payment Release** – Verifier releases payment to Seller.  
6. **Dispute Handling** – Buyer can raise dispute, Arbitrator resolves by splitting funds.  
7. **Event Logging** – Every step emits blockchain events ensuring transparency.  

### 🔹 Example Accounts  
- **Buyer** → `0x5B38...beddC4`  
- **Seller** → `0xAb84...35cb2`  
- **Verifier** → `0x4B20...C02db`  
- **Arbitrator** → `0xd91...39138`  

---
