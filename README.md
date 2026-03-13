# Secure P2P Escrow System

A professional smart contract designed for trustless Peer-to-Peer transactions. This repository provides a robust framework for holding funds in escrow until specific conditions are met, protecting both buyers and sellers in decentralized commerce.

### Core Features
* **Multi-Token Support:** Escrow any ERC-20 token or native ETH.
* **Escrow States:** Tracks lifecycle through `Created`, `Funded`, `Completed`, and `Disputed`.
* **Dispute Resolution:** Includes an optional Arbiter role who can rule in favor of the buyer or seller if a conflict arises.
* **Deadline Enforcement:** Automatic refund capability if a trade is not completed within a specified timeframe.

### Workflow
1. **Creation:** Buyer or Seller creates an escrow instance with a designated price and token.
2. **Funding:** The buyer deposits the funds into the contract.
3. **Execution:** Once the goods/services are received, the buyer releases the funds.
4. **Resolution:** If a dispute occurs, the Arbiter makes the final decision on fund distribution.

### Security
Uses the "Pull" over "Push" payment pattern and includes protection against reentrancy attacks.
