# MergerVault — Cross-DAO Merger & Acquisition Protocol

MergerVault is a decentralized protocol built on Stacks that enables DAOs to propose, negotiate, and execute structured mergers and acquisitions with on-chain treasury consolidation and arbiter-based dispute resolution.

## Overview

The protocol facilitates trustless M&A activity between decentralized organizations. Acquirers lock offer funds in escrow, target DAOs accept or contest terms, and an elected arbiter panel resolves disputes — all enforced by smart contract logic.

## Core Features

- **DAO & Acquirer Registration** — Both sides onboard with governance scores tracked on-chain
- **Escrow-Backed Proposals** — Offer funds are locked at proposal time, eliminating counterparty risk
- **Structured Merger Lifecycle** — Proposals move through `pending → active → completed` (or `disputed`)
- **Post-Merger Assessments** — Both parties submit rated notes for protocol-level reputation tracking
- **Arbiter Panel Disputes** — Bonded arbiters are elected per contest and vote to resolve disagreements
- **Governance Score Progression** — Completed mergers increase participant governance scores on-chain

## Contract Architecture

| Map | Purpose |
|---|---|
| `dao-registrations` | DAO governance metadata and merger history |
| `acquirer-registrations` | Acquirer profile and deployment totals |
| `merger-proposals` | Core proposal data with escrow linkage |
| `merger-assessments` | Post-completion bilateral ratings |
| `merger-contests` | Dispute records with arbiter panel and vote tallies |
| `arbiter-bonds` | Individual arbiter stakes and votes per contest |

## Workflow

### Standard Merger
1. Acquirer calls `register-acquirer`, DAO calls `register-dao`
2. Acquirer calls `submit-merger-proposal` — funds enter escrow
3. Target DAO calls `accept-merger-proposal`
4. Acquirer calls `finalize-merger` — funds released to DAO
5. Both parties call `submit-assessment` with ratings

### Disputed Merger
1. Either party calls `file-contest` during `active` phase
2. Five community members call `enroll-as-arbiter` (each bonds 1 STX)
3. All arbiters call `cast-arbiter-vote`
4. Majority vote determines resolution

## Parameters

| Variable | Default | Description |
|---|---|---|
| `min-delegate-stake` | 1,000,000 µSTX (1 STX) | Arbiter bond requirement |
| `voting-window` | 1,008 blocks (~7 days) | Contest voting deadline |
| `delegate-incentive-pct` | 10% | Incentive allocation for arbiters |

## Error Codes

| Code | Constant | Meaning |
|---|---|---|
| u100 | `ERR_UNAUTHORIZED` | Caller is not the expected party |
| u101 | `ERR_NOT_FOUND` | Proposal, DAO, or contest does not exist |
| u102 | `ERR_INVALID_AMOUNT` | Zero amount or empty string passed |
| u103 | `ERR_ALREADY_EXISTS` | Profile or vote already registered |
| u104 | `ERR_INVALID_STATUS` | Action not valid for current status |
| u105 | `ERR_INSUFFICIENT_STAKE` | Bond amount below minimum |
| u106 | `ERR_VOTING_EXPIRED` | Contest deadline has passed |

## Getting Started

Deploy the contract to Stacks testnet using Clarinet:
```bash
