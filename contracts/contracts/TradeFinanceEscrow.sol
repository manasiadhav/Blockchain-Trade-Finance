// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * Blockchain in Trade Finance — Escrowed Smart Contract
 *
 * Single-trade contract that
 * 1) holds buyer funds in escrow
 * 2) records/validates trade docs via a hash
 * 3) tracks shipment state
 * 4) auto-releases payment to seller when conditions are met
 * 5) allows dispute + third-party resolution
 *
 * Roles:
 *  - buyer: funds the trade and confirms delivery
 *  - seller: ships goods
 *  - verifier: sets/approves the document hash (can be seller or a 3rd party)
 *  - arbitrator: resolves disputes
 */

contract TradeFinanceEscrow {
    // ---- State machine for shipment / deal lifecycle ----
    enum TradeState {
        Created,            // Contract deployed; waiting for buyer to fund
        Funded,             // Buyer deposit in escrow
        DocumentsVerified,  // Required trade documents verified via hash
        Shipped,            // Seller marked shipped
        Delivered,          // Buyer confirmed delivery
        Disputed,           // Any party raised a dispute
        Completed,          // Funds released to seller
        Cancelled           // Trade cancelled (pre-funding or arbitrator decision)
    }

    // ---- Parties ----
    address payable public buyer;
    address payable public seller;
    address public verifier;     // could be the seller or a 3rd party
    address public arbitrator;   // trusted dispute resolver

    // ---- Commercial terms ----
    uint256 public priceWei;          // escrow amount required (in wei)
    bytes32 public documentHash;      // e.g., keccak256 of Bill of Lading (or bundle)
    string public shipmentDetails;    // optional human-readable description

    // ---- Lifecycle ----
    TradeState public state;
    uint256 public fundedAt;          // timestamp when escrow funded

    // ---- Simple reentrancy guard ----
    bool private locked;

    // ---- Events (use these for screenshots in Remix) ----
    event Funded(address indexed buyer, uint256 amount);
    event DocumentVerified(address indexed verifier, bytes32 docHash);
    event Shipped(address indexed seller);
    event Delivered(address indexed buyer);
    event Disputed(address indexed raisedBy, string reason);
    event Resolved(address indexed arbitrator, string decision, uint256 sellerPayout, uint256 buyerRefund);
    event Released(address indexed seller, uint256 amount);
    event Cancelled(string reason);

    // ---- Modifiers ----
    modifier onlyBuyer() { require(msg.sender == buyer, "Only buyer"); _; }
    modifier onlySeller() { require(msg.sender == seller, "Only seller"); _; }
    modifier onlyVerifier() { require(msg.sender == verifier, "Only verifier"); _; }
    modifier onlyArbitrator() { require(msg.sender == arbitrator, "Only arbitrator"); _; }

    modifier nonReentrant() {
        require(!locked, "Reentrancy");
        locked = true;
        _;
        locked = false;
    }

    constructor(
        address payable _buyer,
        address payable _seller,
        address _verifier,
        address _arbitrator,
        uint256 _priceWei,
        string memory _shipmentDetails
    ) {
        require(_buyer != address(0) && _seller != address(0), "Invalid parties");
        require(_verifier != address(0) && _arbitrator != address(0), "Invalid roles");
        require(_priceWei > 0, "Price must be > 0");

        buyer = _buyer;
        seller = _seller;
        verifier = _verifier;
        arbitrator = _arbitrator;
        priceWei = _priceWei;
        shipmentDetails = _shipmentDetails;

        state = TradeState.Created;
    }

    // ----------- CORE FUNCTIONS -----------

    /// @notice Buyer deposits exact price into escrow.
    function fund() external payable onlyBuyer {
        require(state == TradeState.Created, "Not in Created");
        require(msg.value == priceWei, "Send exact price");
        fundedAt = block.timestamp;
        state = TradeState.Funded;
        emit Funded(msg.sender, msg.value);
    }

    /// @notice Verifier sets the canonical document hash (e.g., keccak256 of BoL PDF).
    /// A simple "hash set" acts as verification for this assignment.
    function setDocumentHash(bytes32 _hash) external onlyVerifier {
        require(state == TradeState.Funded || state == TradeState.Shipped, "Set hash after Funded");
        documentHash = _hash;
        if (state == TradeState.Funded) {
            state = TradeState.DocumentsVerified;
        }
        emit DocumentVerified(msg.sender, _hash);
    }

    /// @notice Seller marks goods as shipped.
    function markShipped() external onlySeller {
        require(
            state == TradeState.Funded || state == TradeState.DocumentsVerified,
            "Must be Funded/DocsVerified"
        );
        state = TradeState.Shipped;
        emit Shipped(msg.sender);
    }

    /// @notice Buyer confirms delivery.
    function confirmDelivery() external onlyBuyer {
        require(
            state == TradeState.Shipped || state == TradeState.DocumentsVerified,
            "Not ready for delivery"
        );
        state = TradeState.Delivered;
        emit Delivered(msg.sender);
    }

    /// @notice Release escrow to seller when *both* docs verified and delivery confirmed.
    function releasePayment() public nonReentrant {
        require(state == TradeState.Delivered, "Not Delivered");
        require(documentHash != bytes32(0), "Docs not verified");
        state = TradeState.Completed;

        uint256 amount = address(this).balance;
        (bool ok, ) = seller.call{value: amount}("");
        require(ok, "Payout failed");

        emit Released(seller, amount);
    }

    // ----------- DISPUTE HANDLING -----------

    /// @notice Any party can raise a dispute with a short text reason.
    function raiseDispute(string calldata reason) external {
        require(
            msg.sender == buyer || msg.sender == seller || msg.sender == verifier,
            "Only buyer/seller/verifier"
        );
        require(
            state == TradeState.Funded ||
            state == TradeState.DocumentsVerified ||
            state == TradeState.Shipped ||
            state == TradeState.Delivered,
            "Invalid state for dispute"
        );
        state = TradeState.Disputed;
        emit Disputed(msg.sender, reason);
    }

    /**
     * @notice Arbitrator resolves dispute by splitting escrow between parties.
     * @param payoutToSeller amount (wei) to send to seller; remainder (if any) goes back to buyer.
     * @param decision short text note (e.g., "Docs invalid", "Partial damage", etc.).
     */
    function resolveDispute(uint256 payoutToSeller, string calldata decision)
        external
        onlyArbitrator
        nonReentrant
    {
        require(state == TradeState.Disputed, "No dispute");

        uint256 bal = address(this).balance;
        require(payoutToSeller <= bal, "Exceeds escrow");

        uint256 refundToBuyer = bal - payoutToSeller;

        // Payouts
        if (payoutToSeller > 0) {
            (bool ok1, ) = seller.call{value: payoutToSeller}("");
            require(ok1, "Seller payout failed");
        }
        if (refundToBuyer > 0) {
            (bool ok2, ) = buyer.call{value: refundToBuyer}("");
            require(ok2, "Buyer refund failed");
        }

        // Final state
        state = (payoutToSeller > 0) ? TradeState.Completed : TradeState.Cancelled;

        emit Resolved(msg.sender, decision, payoutToSeller, refundToBuyer);
        if (state == TradeState.Cancelled) {
            emit Cancelled("Arbitrator cancelled");
        }
    }

    // ----------- SAFETY / ADMIN -----------

    /// @notice Buyer can cancel only before funding (no funds at risk).
    function cancelBeforeFunding(string calldata reason) external onlyBuyer {
        require(state == TradeState.Created, "Already funded");
        state = TradeState.Cancelled;
        emit Cancelled(reason);
    }

    /// @notice Helper: get human-readable state (for UI / screenshots).
    function stateString() external view returns (string memory) {
        if (state == TradeState.Created) return "Created";
        if (state == TradeState.Funded) return "Funded";
        if (state == TradeState.DocumentsVerified) return "DocumentsVerified";
        if (state == TradeState.Shipped) return "Shipped";
        if (state == TradeState.Delivered) return "Delivered";
        if (state == TradeState.Disputed) return "Disputed";
        if (state == TradeState.Completed) return "Completed";
        if (state == TradeState.Cancelled) return "Cancelled";
        return "Unknown";
    }

    // Fallbacks blocked to avoid accidental ETH
    receive() external payable {
        revert("Use fund()");
    }
    fallback() external payable {
        revert("No fallback");
    }
}
