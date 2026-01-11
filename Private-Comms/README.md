# SecureChain Messaging Protocol

A decentralized, blockchain-based secure messaging system built on the Stacks blockchain with end-to-end encryption, quantum-resistant cryptographic support, user privacy controls, contact management, conversation threading, and comprehensive blocking mechanisms.

## Overview

SecureChain provides a censorship-resistant messaging platform where users maintain complete control over their communications. All messages are stored on-chain with encryption metadata, ensuring transparency while preserving privacy through client-side encryption.

## Features

### Core Messaging
- End-to-end encrypted message transmission
- Quantum-resistant encryption support
- Message threading for organized conversations
- Priority-based message delivery
- Permanent on-chain message storage

### User Management
- Customizable user profiles with display names
- Public key registration for encryption
- Privacy level controls (0-10 scale)
- User status tracking

### Privacy and Security
- User blocking with documented reasons
- Contact list management with trust ratings
- Privacy level configurations
- Authorization checks for all operations

### Group Communications
- Thread creation with up to 10 participants
- Thread-based message organization
- Creator-controlled thread activation
- Privacy settings per thread

### Platform Administration
- Owner-controlled platform status
- Maintenance mode capabilities
- Emergency shutdown functionality
- Comprehensive statistics tracking

## Technical Specifications

### Limits and Constants
- Maximum message length: 1000 characters
- Maximum display name: 50 characters
- Maximum nickname: 50 characters
- Maximum encryption key: 100 characters
- Maximum block reason: 100 characters
- Maximum trust level: 10
- Maximum privacy level: 10
- Maximum thread participants: 10
- Maximum priority level: 10

### Data Structures

#### Messages
```clarity
{
    sender: principal,
    recipient: principal,
    encrypted-payload: (string-ascii 1000),
    block-height: uint,
    quantum-resistant: bool,
    thread-id: (optional uint),
    priority: uint
}
```

#### User Profiles
```clarity
{
    display-name: (string-ascii 50),
    public-key: (optional (string-ascii 100)),
    created-at: uint,
    privacy-level: uint,
    status: (string-ascii 20)
}
```

#### Blocked Users
```clarity
{
    blocked-at: uint,
    reason: (string-ascii 100)
}
```

#### Contacts
```clarity
{
    nickname: (string-ascii 50),
    added-at: uint,
    trust-level: uint,
    category: (string-ascii 20)
}
```

#### Threads
```clarity
{
    creator: principal,
    participants: (list 10 principal),
    created-at: uint,
    privacy-level: uint,
    active: bool
}
```

## Public Functions

### Messaging Operations

#### send-message
Send an encrypted message to a recipient.

Parameters:
- `recipient` (principal): Message recipient address
- `content` (string-ascii 1000): Encrypted message payload
- `quantum-resistant` (bool): Whether quantum-resistant encryption is used
- `thread-ref` (optional uint): Optional thread ID for threaded conversations
- `priority` (uint): Message priority level (0-10)

Returns: Message ID (uint)

Requirements:
- Sender and recipient must be different
- Content must be 1-1000 characters
- Recipient must not have blocked sender
- Platform must be active
- Thread reference must be valid if provided

#### get-sent-messages
Retrieve paginated list of sent messages.

Parameters:
- `sender` (principal): Sender address
- `limit` (uint): Number of results
- `offset` (uint): Starting position

Returns: List of messages

Authorization: Must be called by the sender

#### get-received-messages
Retrieve paginated list of received messages.

Parameters:
- `recipient` (principal): Recipient address
- `limit` (uint): Number of results
- `offset` (uint): Starting position

Returns: List of messages

Authorization: Must be called by the recipient

### Profile Management

#### create-profile
Create a new user profile.

Parameters:
- `name` (string-ascii 50): Display name
- `public-key` (optional string-ascii 100): Public encryption key
- `privacy-level` (uint): Privacy setting (0-10)

Returns: Success boolean

#### update-profile
Update existing user profile.

Parameters:
- `name` (string-ascii 50): Display name
- `public-key` (optional string-ascii 100): Public encryption key
- `privacy-level` (uint): Privacy setting (0-10)

Returns: Success boolean

### Blocking and Contact Management

#### block-user
Block a user from sending messages.

Parameters:
- `target` (principal): User to block
- `reason` (string-ascii 100): Reason for blocking

Returns: Success boolean

Requirements:
- Cannot block yourself
- User must not already be blocked
- Reason must be 1-100 characters

#### unblock-user
Remove a user from blocked list.

Parameters:
- `target` (principal): User to unblock

Returns: Success boolean

#### add-contact
Add a user to contact list.

Parameters:
- `contact` (principal): Contact address
- `nickname` (string-ascii 50): Contact nickname
- `trust-level` (uint): Trust rating (0-10)

Returns: Success boolean

#### remove-contact
Remove a user from contact list.

Parameters:
- `contact` (principal): Contact to remove

Returns: Success boolean

### Thread Management

#### create-thread
Create a group conversation thread.

Parameters:
- `participants` (list 10 principal): List of participant addresses
- `privacy-level` (uint): Thread privacy setting (0-10)

Returns: Thread ID (uint)

Requirements:
- At least 1 participant
- Maximum 10 participants
- Valid privacy level

#### set-thread-status
Activate or deactivate a thread.

Parameters:
- `thread-id` (uint): Thread identifier
- `status` (bool): Active status

Returns: Success boolean

Authorization: Must be thread creator

#### get-thread-messages
Retrieve paginated messages from a thread.

Parameters:
- `thread-id` (uint): Thread identifier
- `limit` (uint): Number of results
- `offset` (uint): Starting position

Returns: List of messages

Authorization: Must be thread creator or participant

### Administrative Functions

#### set-platform-status
Enable or disable platform operations.

Parameters:
- `status` (bool): Platform active status

Returns: Status boolean

Authorization: Contract owner only

#### set-maintenance-mode
Toggle maintenance mode.

Parameters:
- `enabled` (bool): Maintenance mode status

Returns: Status boolean

Authorization: Contract owner only

#### emergency-shutdown
Perform emergency platform shutdown.

Parameters:
- `reason` (string-ascii 200): Shutdown reason

Returns: Reason string

Authorization: Contract owner only

## Read-Only Functions

### get-message
Retrieve specific message by ID.

### get-user-profile
Get user profile information.

### is-user-blocked
Check if blocking relationship exists.

### get-contact
Retrieve contact relationship details.

### get-message-count
Get total platform message count.

### is-platform-active
Check if platform is operational.

### get-thread
Get thread details by ID.

### is-thread-active
Check if thread is active.

### get-platform-info
Retrieve comprehensive platform metadata.

### get-admin-info
Get administrative platform information (includes owner, status, deployment details).

### get-stats
Get comprehensive platform statistics.

## Error Codes

- `ERR-UNAUTHORIZED-ACCESS (u200)`: Insufficient permissions
- `ERR-MESSAGE-NOT-FOUND (u201)`: Message does not exist
- `ERR-INVALID-RECIPIENT (u202)`: Invalid or blocked recipient
- `ERR-MESSAGE-TOO-LONG (u203)`: Content exceeds maximum length
- `ERR-USER-ALREADY-BLOCKED (u204)`: User already in blocked list
- `ERR-USER-NOT-BLOCKED (u205)`: User not in blocked list
- `ERR-CANNOT-TARGET-SELF (u206)`: Cannot perform action on self
- `ERR-INVALID-PAGINATION (u207)`: Invalid pagination parameters
- `ERR-INVALID-PARAMETERS (u208)`: Invalid function parameters
- `ERR-INVALID-THREAD (u209)`: Thread does not exist or invalid
- `ERR-TRUST-LEVEL-OUT-OF-RANGE (u210)`: Trust level not 0-10
- `ERR-PRIVACY-LEVEL-OUT-OF-RANGE (u211)`: Privacy level not 0-10
- `ERR-PLATFORM-DISABLED (u212)`: Platform not accepting transactions
- `ERR-INSUFFICIENT-PERMISSIONS (u213)`: Lacks required permissions
- `ERR-INVALID-ENCRYPTION-KEY (u214)`: Encryption key format invalid
- `ERR-TOO-MANY-PARTICIPANTS (u215)`: Exceeds participant limit

## Usage Examples

### Sending a Message
```clarity
(contract-call? .securechain send-message 
    'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
    "encrypted_payload_here"
    true
    none
    u5)
```

### Creating a Profile
```clarity
(contract-call? .securechain create-profile 
    "Alice"
    (some "public_key_here")
    u7)
```

### Blocking a User
```clarity
(contract-call? .securechain block-user 
    'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
    "spam messages")
```

### Creating a Thread
```clarity
(contract-call? .securechain create-thread 
    (list 'ST1... 'ST2... 'ST3...)
    u5)
```

## Security Considerations

1. Messages are stored on-chain in encrypted form - ensure proper client-side encryption
2. Public keys are stored on-chain - use secure key management practices
3. Blocking relationships are public - consider privacy implications
4. All operations require platform to be active
5. Thread creators have administrative control over their threads
6. Only contract owner can perform administrative actions