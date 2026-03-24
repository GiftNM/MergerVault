# MergerVault - Cross-DAO Merger & Acquisition Protocol

A decentralized protocol that enables DAOs to propose, vote on, and execute mergers with automatic treasury consolidation. Built on Stacks blockchain using Clarity smart contracts.

## Overview

MergerVault is a comprehensive smart contract system designed to facilitate transparent and secure DAO mergers and acquisitions. The protocol handles proposal submission, voting mechanisms, dispute resolution, and treasury transfers with built-in governance scoring and reputation tracking.

## Key Features

- **DAO Registration**: DAOs can register to participate in mergers while building governance reputation
- **Merger Proposals**: Acquirers submit acquisition offers with specific terms and treasury amounts
- **Acceptance & Finalization**: Target DAOs review and accept proposals, with acquirers finalizing the transaction
- **Assessment System**: Both parties can rate and provide feedback on completed mergers
- **Dispute Resolution**: Built-in contest mechanism with arbiter voting for resolving disagreements
- **Governance Scoring**: Dynamic reputation system that tracks DAO performance and participation
- **Treasury Consolidation**: Automatic STX transfers upon merger finalization

## Smart Contract Functions

### Registration

- **`register-dao`**: Register a DAO as a participant (governance-score starts at 100)
- **`register-acquirer`**: Register as an acquirer entity

### Merger Workflow

- **`submit-merger-proposal`**: Submit a merger offer with terms and amount (transitions proposal to "pending")
- **`accept-merger-proposal`**: Target DAO accepts the proposal (transitions to "active")
- **`finalize-merger`**: Acquirer executes the merger and transfers treasury funds (transitions to "completed")

### Post-Merger

- **`submit-assessment`**: Both parties rate the merger on a scale of 1-5 with written notes

### Dispute Management

- **`file-contest`**: Challenge a proposal or active merger with grounds for dispute
- **`enroll-as-arbiter`**: Register as an arbiter with a bond (min 1M STX by default)
- **`cast-arbiter-vote`**: Vote on dispute resolution during voting window

### Read Functions

- **`get-dao-registration`**: Retrieve DAO profile and statistics
- **`get-acquirer-registration`**: Retrieve acquirer profile and statistics
- **`get-merger-proposal`**: View proposal details and status
- **`get-merger-assessment`**: Access ratings and feedback
- **`get-merger-contest`**: View contest details and voting results
- **`get-next-proposal-id`**: Get the next available proposal ID
- **`get-next-contest-id`**: Get the next available contest ID

## Data Structures

### DAO Registration
```
{
  governance-score: uint,        // Reputation score (starts at 100)
  mergers-completed: uint,       // Count of successful mergers
  treasury-contributed: uint,    // Total STX contributed
  disputes-won: uint,            // Successful contest outcomes
  disputes-lost: uint,           // Lost contest outcomes
  active: bool                   // Registration status
}
```

### Merger Proposal
```
{
  acquirer: principal,           // Acquiring party address
  target-dao: principal,         // Target DAO address
  offer-amount: uint,            // STX amount being offered
  terms: string-ascii,           // Proposal terms (max 500 chars)
  status: string-ascii,          // pending | active | completed | disputed
  proposed-at: uint,             // Block height of proposal
  finalized-at: optional uint,   // Block height of finalization
  contested-at: optional uint    // Block height of contest
}
```

### Merger Assessment
```
{
  acquirer-rating: uint,         // 1-5 rating from acquirer
  dao-rating: uint,              // 1-5 rating from DAO
  acquirer-notes: string-ascii,  // Acquirer feedback (max 500 chars)
  dao-notes: string-ascii,       // DAO feedback (max 500 chars)
  assessed-at: uint              // Block height of assessment
}
```

### Merger Contest
```
{
  proposal-id: uint,             // Associated proposal ID
  challenger: principal,         // Who filed the contest
  grounds: string-ascii,         // Dispute reasoning (max 500 chars)
  status: string-ascii,          // open | voting | closed
  filed-at: uint,                // Block height of contest filing
  decision-deadline: uint,       // Block height voting ends
  arbiters: list,                // Up to 5 arbiters (list of principals)
  votes-for-acquirer: uint,      // Arbiter votes supporting acquirer
  votes-for-dao: uint,           // Arbiter votes supporting DAO
  decided-in-favor-of: optional  // Final decision (principal or none)
}
```

## Configuration Constants

- **`min-delegate-stake`**: 1,000,000 STX (minimum bond for arbiters)
- **`voting-window`**: 1,008 blocks (~7 days on Bitcoin L2 timeline)
- **`delegate-incentive-pct`**: 10% (incentive percentage for arbiters)

## Error Codes

| Code | Error | Meaning |
|------|-------|---------|
| u100 | ERR_UNAUTHORIZED | Caller lacks required permissions |
| u101 | ERR_NOT_FOUND | Proposal or data not found |
| u102 | ERR_INVALID_AMOUNT | Amount or parameter invalid |
| u103 | ERR_ALREADY_EXISTS | Entity already registered |
| u104 | ERR_INVALID_STATUS | Transaction invalid for current status |
| u105 | ERR_INSUFFICIENT_STAKE | Insufficient arbiter bond |
| u106 | ERR_VOTING_EXPIRED | Voting deadline has passed |

## Proposal Lifecycle

```
pending → active → completed
           ↓
        disputed → voting → resolved
```

1. **Pending**: Acquirer submits proposal, waiting for DAO acceptance
2. **Active**: DAO accepts, acquirer prepares finalization
3. **Completed**: Funds transferred, treasury consolidated
4. **Disputed**: Contest filed during active period
5. **Voting**: Arbiters cast votes during voting window

## Security Features

- **Access Control**: Role-based permissions (DAOs, acquirers, arbiters)
- **Bond System**: Arbiters stake STX to prevent frivolous disputes
- **Voting Window**: Time-limited dispute resolution (1,008 blocks)
- **Assessment Tracking**: Post-merger feedback for reputation building
- **Treasury Escrow**: Funds held in contract until finalization

## Usage Example

```clarity
;; 1. Register as a DAO
(register-dao)

;; 2. Register as an acquirer
(register-acquirer)

;; 3. Submit merger proposal
(submit-merger-proposal target-principal u5000000 "Merge tech stacks, consolidate operations")

;; 4. Target DAO accepts
(accept-merger-proposal u1)

;; 5. Acquirer finalizes
(finalize-merger u1)

;; 6. Both parties submit assessments
(submit-assessment u1 u5 "Great partnership, seamless integration")

;; 7. If disputed, arbiters enroll and vote
(enroll-as-arbiter contest-id)
(cast-arbiter-vote contest-id true)  ;; Vote for acquirer
```

## Deployment

Deploy this Clarity contract to the Stacks blockchain network. Ensure:
- Contract owner is set correctly (protocol admin)
- Network has sufficient liquidity for proposed mergers
- Arbiters are recruited for dispute resolution

## Support

For questions, disputes, or technical issues, contact the protocol arbiters or governance committee.
