# STX Buyback & Burn

A transparent, auditable smart contract for the Stacks blockchain that enables DAOs, treasuries, and admins to periodically burn STX tokens.

## Overview

This contract provides a secure mechanism to remove STX from circulation through controlled burns. It includes administrative controls, configurable burn intervals, and a complete audit trail of all burn events.

## Features

- **Periodic Burns**: Execute burns on a configurable interval (measured in blocks)
- **Admin Controls**: Pause/resume functionality and admin management
- **Audit Trail**: Complete history of all burn events with executor, amount, block height, and optional memo
- **Authorization**: Role-based access control for sensitive operations
- **Transparent**: Read-only functions for querying burn history and contract state

## Contract Functions

### Admin Functions

- `set-admin(new-admin: principal)` - Transfer admin privileges
- `set-burn-interval(interval: uint)` - Configure blocks between burns
- `toggle-paused()` - Pause or resume burn operations

### Core Functions

- `deposit(amount: uint)` - Deposit STX into the contract for future burns
- `execute-burn(amount: uint, memo: (optional (buff 50)))` - Execute a burn operation

### Read-Only Functions

- `get-total-burned()` - Query total STX burned
- `get-last-burn-height()` - Get block height of last burn
- `get-burn-by-id(id: uint)` - Retrieve specific burn event details
- `get-admin()` - Get current admin address
- `is-paused()` - Check if contract is paused

## Constants

- **BURN-ADDRESS**: `SP000000000000000000002Q6VF78.burn` - Destination for burned STX
- **Default Burn Interval**: 1000 blocks

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100 | ERR-NOT-AUTHORIZED | Caller is not authorized (not admin) |
| 101 | ERR-TOO-SOON | Burn interval has not elapsed |
| 102 | ERR-INSUFFICIENT-STX | Contract lacks sufficient STX balance |
| 103 | ERR-PAUSED | Contract is paused |
| 400 | - | Deposit amount must be > 0 |
| 404 | - | Burn event not found |

## Usage Example

```clarity
;; Deposit 100 STX
(contract-call? .stx-buyback-burn deposit u100000000)

;; Execute a burn of 50 STX with memo
(contract-call? .stx-buyback-burn execute-burn 
  u50000000 
  (some 0x71756172746572327265647563746f72))

;; Check total burned
(contract-call? .stx-buyback-burn get-total-burned)
```

## Security Considerations

- Admin-only execution prevents unauthorized burns
- Configurable intervals prevent excessive burns
- Pause mechanism provides emergency control
- Block height validation ensures minimum interval between burns
- Complete audit trail for transparency

