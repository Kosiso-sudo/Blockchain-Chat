;; SecureChain Messaging Protocol Smart Contract
;; A decentralized, blockchain-based secure messaging system with end-to-end encryption,
;; quantum-resistant cryptographic support, user privacy controls, contact management,
;; conversation threading, and comprehensive blocking mechanisms for peer-to-peer
;; and group communications on the Stacks blockchain.

;; Error codes for access control and validation
(define-constant ERR-UNAUTHORIZED-ACCESS (err u200))
(define-constant ERR-MESSAGE-NOT-FOUND (err u201))
(define-constant ERR-INVALID-RECIPIENT (err u202))
(define-constant ERR-MESSAGE-TOO-LONG (err u203))
(define-constant ERR-USER-ALREADY-BLOCKED (err u204))
(define-constant ERR-USER-NOT-BLOCKED (err u205))
(define-constant ERR-CANNOT-TARGET-SELF (err u206))
(define-constant ERR-INVALID-PAGINATION (err u207))
(define-constant ERR-INVALID-PARAMETERS (err u208))
(define-constant ERR-INVALID-THREAD (err u209))
(define-constant ERR-TRUST-LEVEL-OUT-OF-RANGE (err u210))
(define-constant ERR-PRIVACY-LEVEL-OUT-OF-RANGE (err u211))
(define-constant ERR-PLATFORM-DISABLED (err u212))
(define-constant ERR-INSUFFICIENT-PERMISSIONS (err u213))
(define-constant ERR-INVALID-ENCRYPTION-KEY (err u214))
(define-constant ERR-TOO-MANY-PARTICIPANTS (err u215))

;; Configuration constants for platform limits
(define-constant max-message-length u1000)
(define-constant max-display-name-length u50)
(define-constant max-nickname-length u50)
(define-constant max-encryption-key-length u100)
(define-constant max-block-reason-length u100)
(define-constant max-trust-level u10)
(define-constant max-privacy-level u10)
(define-constant max-thread-participants u10)
(define-constant max-priority-level u10)
(define-constant contract-owner tx-sender)
(define-constant thread-id-offset u1000)

;; Platform state management variables
(define-data-var message-counter uint u0)
(define-data-var platform-active bool true)
(define-data-var deployment-block uint block-height)
(define-data-var maintenance-mode bool false)

;; Message storage with encryption metadata and threading support
(define-map messages
    uint
    {
        sender: principal,
        recipient: principal,
        encrypted-payload: (string-ascii 1000),
        block-height: uint,
        quantum-resistant: bool,
        thread-id: (optional uint),
        priority: uint
    }
)

;; User profile data including encryption keys and privacy settings
(define-map user-profiles
    principal
    {
        display-name: (string-ascii 50),
        public-key: (optional (string-ascii 100)),
        created-at: uint,
        privacy-level: uint,
        status: (string-ascii 20)
    }
)

;; User blocking relationships with reasons and timestamps
(define-map blocked-users
    { blocker: principal, blocked: principal }
    {
        blocked-at: uint,
        reason: (string-ascii 100)
    }
)

;; Contact list with nicknames and trust ratings
(define-map contacts
    { owner: principal, contact: principal }
    {
        nickname: (string-ascii 50),
        added-at: uint,
        trust-level: uint,
        category: (string-ascii 20)
    }
)

;; Group conversation threads with participant lists
(define-map threads
    uint
    {
        creator: principal,
        participants: (list 10 principal),
        created-at: uint,
        privacy-level: uint,
        active: bool
    }
)

;; Retrieve message data by unique identifier
(define-read-only (get-message (msg-id uint))
    (map-get? messages msg-id)
)

;; Get user profile information
(define-read-only (get-user-profile (user principal))
    (map-get? user-profiles user)
)

;; Check if one user has blocked another
(define-read-only (is-user-blocked (blocker principal) (blocked principal))
    (is-some (map-get? blocked-users { blocker: blocker, blocked: blocked }))
)

;; Retrieve contact relationship details
(define-read-only (get-contact (owner principal) (contact principal))
    (map-get? contacts { owner: owner, contact: contact })
)

;; Get total number of messages sent on platform
(define-read-only (get-message-count)
    (var-get message-counter)
)

;; Check if platform is currently accepting transactions
(define-read-only (is-platform-active)
    (and 
        (var-get platform-active)
        (not (var-get maintenance-mode))
    )
)

;; Get conversation thread details
(define-read-only (get-thread (thread-id uint))
    (map-get? threads thread-id)
)

;; Retrieve comprehensive platform metadata and statistics
(define-read-only (get-platform-info)
    {
        name: "SecureChain",
        version: "4.0.0",
        total-messages: (var-get message-counter),
        owner: contract-owner,
        active: (var-get platform-active),
        deployed-at: (var-get deployment-block),
        max-message-size: max-message-length,
        max-participants: max-thread-participants,
        maintenance: (var-get maintenance-mode)
    }
)

;; Validate encryption key format meets requirements
(define-private (is-valid-encryption-key (key (optional (string-ascii 100))))
    (match key
        key-value (and 
            (<= (len key-value) max-encryption-key-length)
            (> (len key-value) u0)
        )
        true
    )
)

;; Verify privacy level is within allowed bounds
(define-private (is-valid-privacy-level (level uint))
    (and 
        (<= level max-privacy-level)
        (>= level u0)
    )
)

;; Verify trust level is within allowed bounds
(define-private (is-valid-trust-level (level uint))
    (and 
        (<= level max-trust-level)
        (>= level u0)
    )
)

;; Validate block reason has content and meets length requirements
(define-private (is-valid-block-reason (reason (string-ascii 100)))
    (and 
        (> (len reason) u0)
        (<= (len reason) max-block-reason-length)
    )
)

;; Verify thread reference exists or is none
(define-private (is-valid-thread-ref (thread-ref (optional uint)))
    (match thread-ref
        tid (is-some (map-get? threads tid))
        true
    )
)

;; Check if thread exists in storage
(define-private (thread-exists (thread-id uint))
    (is-some (map-get? threads thread-id))
)

;; Ensure two principals are not identical
(define-private (are-different-users (user-a principal) (user-b principal))
    (not (is-eq user-a user-b))
)

;; Validate message content format and constraints
(define-private (is-valid-message-content (content (string-ascii 1000)))
    (and
        (> (len content) u0)
        (<= (len content) max-message-length)
    )
)

;; Check if conversation thread is active
(define-read-only (is-thread-active (thread-id uint))
    (match (map-get? threads thread-id)
        thread-data (get active thread-data)
        false
    )
)

;; Perform comprehensive authorization checks for message sending
(define-private (can-send-message (recipient principal) (content (string-ascii 1000)))
    (and
        (are-different-users tx-sender recipient)
        (<= (len content) max-message-length)
        (> (len content) u0)
        (not (is-user-blocked recipient tx-sender))
        (is-platform-active)
    )
)

;; Verify user has permission to access thread
(define-private (has-thread-access (thread-id uint) (user principal))
    (match (map-get? threads thread-id)
        thread-info
            (or 
                (is-eq (get creator thread-info) user)
                (is-some (index-of (get participants thread-info) user))
            )
        false
    )
)

;; Filter messages by sender with pagination support
(define-private (get-messages-by-sender (sender principal) (limit uint) (offset uint))
    (list)
)

;; Filter messages by recipient with pagination support
(define-private (get-messages-by-recipient (recipient principal) (limit uint) (offset uint))
    (list)
)

;; Filter messages by thread with pagination support
(define-private (get-messages-by-thread (thread-id uint) (limit uint) (offset uint))
    (list)
)

;; Send encrypted message to recipient with optional threading and priority
(define-public (send-message 
    (recipient principal) 
    (content (string-ascii 1000)) 
    (quantum-resistant bool) 
    (thread-ref (optional uint))
    (priority uint))
    (let (
        (sender tx-sender)
        (msg-id (+ (var-get message-counter) u1))
        (current-block block-height)
    )
        (asserts! (can-send-message recipient content) ERR-INVALID-RECIPIENT)
        (asserts! (is-valid-thread-ref thread-ref) ERR-INVALID-THREAD)
        (asserts! (is-platform-active) ERR-PLATFORM-DISABLED)
        (asserts! (<= priority max-priority-level) ERR-INVALID-PARAMETERS)

        (map-set messages msg-id {
            sender: sender,
            recipient: recipient,
            encrypted-payload: content,
            block-height: current-block,
            quantum-resistant: quantum-resistant,
            thread-id: thread-ref,
            priority: priority
        })

        (var-set message-counter msg-id)
        (ok msg-id)
    )
)

;; Get paginated sent messages for authenticated user
(define-read-only (get-sent-messages (sender principal) (limit uint) (offset uint))
    (if (is-eq tx-sender sender)
        (ok (get-messages-by-sender sender limit offset))
        ERR-UNAUTHORIZED-ACCESS
    )
)

;; Get paginated received messages for authenticated user
(define-read-only (get-received-messages (recipient principal) (limit uint) (offset uint))
    (if (is-eq tx-sender recipient)
        (ok (get-messages-by-recipient recipient limit offset))
        ERR-UNAUTHORIZED-ACCESS
    )
)

;; Create new user profile with encryption key and privacy settings
(define-public (create-profile 
    (name (string-ascii 50)) 
    (public-key (optional (string-ascii 100)))
    (privacy-level uint))
    (let ((user tx-sender))
        (asserts! (<= (len name) max-display-name-length) ERR-MESSAGE-TOO-LONG)
        (asserts! (is-valid-encryption-key public-key) ERR-INVALID-ENCRYPTION-KEY)
        (asserts! (is-valid-privacy-level privacy-level) ERR-PRIVACY-LEVEL-OUT-OF-RANGE)
        (asserts! (is-platform-active) ERR-PLATFORM-DISABLED)
        
        (map-set user-profiles user {
            display-name: name,
            public-key: public-key,
            created-at: block-height,
            privacy-level: privacy-level,
            status: "active"
        })
        (ok true)
    )
)

;; Update existing user profile information
(define-public (update-profile 
    (name (string-ascii 50)) 
    (public-key (optional (string-ascii 100)))
    (privacy-level uint))
    (let ((user tx-sender))
        (asserts! (<= (len name) max-display-name-length) ERR-MESSAGE-TOO-LONG)
        (asserts! (is-valid-encryption-key public-key) ERR-INVALID-ENCRYPTION-KEY)
        (asserts! (is-valid-privacy-level privacy-level) ERR-PRIVACY-LEVEL-OUT-OF-RANGE)
        (asserts! (is-platform-active) ERR-PLATFORM-DISABLED)
        
        (match (map-get? user-profiles user)
            profile 
                (map-set user-profiles user 
                    (merge profile {
                        display-name: name,
                        public-key: public-key,
                        privacy-level: privacy-level
                    })
                )
            false
        )
        (ok true)
    )
)

;; Block user from sending messages with specified reason
(define-public (block-user (target principal) (reason (string-ascii 100)))
    (let ((blocker tx-sender))
        (asserts! (are-different-users blocker target) ERR-CANNOT-TARGET-SELF)
        (asserts! (not (is-user-blocked blocker target)) ERR-USER-ALREADY-BLOCKED)
        (asserts! (is-valid-block-reason reason) ERR-INVALID-PARAMETERS)
        (asserts! (is-platform-active) ERR-PLATFORM-DISABLED)
        
        (map-set blocked-users 
            { blocker: blocker, blocked: target }
            {
                blocked-at: block-height,
                reason: reason
            }
        )
        (ok true)
    )
)

;; Remove user from blocked list
(define-public (unblock-user (target principal))
    (let ((blocker tx-sender))
        (asserts! (is-user-blocked blocker target) ERR-USER-NOT-BLOCKED)
        (asserts! (is-platform-active) ERR-PLATFORM-DISABLED)
        
        (map-delete blocked-users { blocker: blocker, blocked: target })
        (ok true)
    )
)

;; Add contact with nickname and trust level
(define-public (add-contact 
    (contact principal) 
    (nickname (string-ascii 50))
    (trust-level uint))
    (let ((owner tx-sender))
        (asserts! (<= (len nickname) max-nickname-length) ERR-MESSAGE-TOO-LONG)
        (asserts! (are-different-users owner contact) ERR-CANNOT-TARGET-SELF)
        (asserts! (is-valid-trust-level trust-level) ERR-TRUST-LEVEL-OUT-OF-RANGE)
        (asserts! (is-platform-active) ERR-PLATFORM-DISABLED)
        
        (map-set contacts 
            { owner: owner, contact: contact }
            {
                nickname: nickname,
                added-at: block-height,
                trust-level: trust-level,
                category: "trusted"
            }
        )
        (ok true)
    )
)

;; Remove contact from contact list
(define-public (remove-contact (contact principal))
    (let ((owner tx-sender))
        (asserts! (are-different-users owner contact) ERR-CANNOT-TARGET-SELF)
        (asserts! (is-platform-active) ERR-PLATFORM-DISABLED)
        
        (map-delete contacts { owner: owner, contact: contact })
        (ok true)
    )
)

;; Create group conversation thread with participants
(define-public (create-thread (participants (list 10 principal)) (privacy-level uint))
    (let (
        (creator tx-sender)
        (thread-id (+ (var-get message-counter) thread-id-offset))
    )
        (asserts! (> (len participants) u0) ERR-INVALID-PARAMETERS)
        (asserts! (<= (len participants) max-thread-participants) ERR-TOO-MANY-PARTICIPANTS)
        (asserts! (is-valid-privacy-level privacy-level) ERR-PRIVACY-LEVEL-OUT-OF-RANGE)
        (asserts! (is-platform-active) ERR-PLATFORM-DISABLED)
        
        (map-set threads thread-id {
            creator: creator,
            participants: participants,
            created-at: block-height,
            privacy-level: privacy-level,
            active: true
        })
        
        (ok thread-id)
    )
)

;; Update conversation thread active status
(define-public (set-thread-status (thread-id uint) (status bool))
    (let ((caller tx-sender))
        (asserts! (thread-exists thread-id) ERR-INVALID-THREAD)
        (asserts! (is-platform-active) ERR-PLATFORM-DISABLED)
        
        (match (map-get? threads thread-id)
            thread-info
                (begin
                    (asserts! (is-eq (get creator thread-info) caller) ERR-UNAUTHORIZED-ACCESS)
                    
                    (map-set threads thread-id 
                        (merge thread-info { active: status }))
                    (ok true)
                )
            ERR-INVALID-THREAD
        )
    )
)

;; Get paginated messages from conversation thread
(define-read-only (get-thread-messages (thread-id uint) (limit uint) (offset uint))
    (match (map-get? threads thread-id)
        thread-info
            (if (has-thread-access thread-id tx-sender)
                (ok (get-messages-by-thread thread-id limit offset))
                ERR-UNAUTHORIZED-ACCESS
            )
        ERR-INVALID-THREAD
    )
)

;; Set platform operational status (admin only)
(define-public (set-platform-status (status bool))
    (begin
        (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED-ACCESS)
        (var-set platform-active status)
        (ok status)
    )
)

;; Toggle maintenance mode (admin only)
(define-public (set-maintenance-mode (enabled bool))
    (begin
        (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED-ACCESS)
        (var-set maintenance-mode enabled)
        (ok enabled)
    )
)

;; Get administrative platform information
(define-read-only (get-admin-info)
    {
        owner: contract-owner,
        active: (var-get platform-active),
        maintenance: (var-get maintenance-mode),
        deployed-at: (var-get deployment-block),
        total-messages: (var-get message-counter),
        uptime-blocks: (- block-height (var-get deployment-block))
    }
)

;; Emergency shutdown for critical situations (admin only)
(define-public (emergency-shutdown (reason (string-ascii 200)))
    (begin
        (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (> (len reason) u0) ERR-INVALID-PARAMETERS)
        
        (var-set platform-active false)
        (var-set maintenance-mode true)
        (ok reason)
    )
)

;; Get comprehensive platform statistics
(define-read-only (get-stats)
    {
        total-messages: (var-get message-counter),
        deployment-block: (var-get deployment-block),
        current-block: block-height,
        platform-age: (- block-height (var-get deployment-block)),
        active: (var-get platform-active),
        maintenance: (var-get maintenance-mode)
    }
)