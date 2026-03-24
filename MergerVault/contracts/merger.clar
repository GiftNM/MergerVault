;; MergerVault - Cross-DAO Merger & Acquisition Protocol
;; Enables DAOs to propose, vote on, and execute mergers with treasury consolidation

;; Constants
(define-constant PROTOCOL_ADMIN tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_INVALID_AMOUNT (err u102))
(define-constant ERR_ALREADY_EXISTS (err u103))
(define-constant ERR_INVALID_STATUS (err u104))
(define-constant ERR_INSUFFICIENT_STAKE (err u105))
(define-constant ERR_VOTING_EXPIRED (err u106))

;; Data Variables
(define-data-var min-delegate-stake uint u1000000)
(define-data-var voting-window uint u1008)
(define-data-var delegate-incentive-pct uint u10)

;; Data Maps
(define-map dao-registrations
  principal
  {
    governance-score: uint,
    mergers-completed: uint,
    treasury-contributed: uint,
    disputes-won: uint,
    disputes-lost: uint,
    active: bool
  }
)

(define-map acquirer-registrations
  principal
  {
    proposals-submitted: uint,
    total-deployed: uint,
    governance-score: uint,
    active: bool
  }
)

(define-map merger-proposals
  uint
  {
    acquirer: principal,
    target-dao: principal,
    offer-amount: uint,
    terms: (string-ascii 500),
    status: (string-ascii 20),
    proposed-at: uint,
    finalized-at: (optional uint),
    contested-at: (optional uint)
  }
)

(define-map merger-assessments
  uint
  {
    acquirer-rating: uint,
    dao-rating: uint,
    acquirer-notes: (string-ascii 500),
    dao-notes: (string-ascii 500),
    assessed-at: uint
  }
)

(define-map merger-contests
  uint
  {
    proposal-id: uint,
    challenger: principal,
    grounds: (string-ascii 500),
    status: (string-ascii 20),
    filed-at: uint,
    decision-deadline: uint,
    arbiters: (list 5 principal),
    votes-for-acquirer: uint,
    votes-for-dao: uint,
    decided-in-favor-of: (optional principal)
  }
)

(define-map arbiter-bonds
  { contest-id: uint, arbiter: principal }
  { amount: uint, vote: (optional bool) }
)

(define-data-var next-proposal-id uint u1)
(define-data-var next-contest-id uint u1)

;; Public Functions

(define-public (register-dao)
  (let ((caller tx-sender))
    (asserts! (is-none (map-get? dao-registrations caller)) ERR_ALREADY_EXISTS)
    (ok (map-set dao-registrations caller {
      governance-score: u100,
      mergers-completed: u0,
      treasury-contributed: u0,
      disputes-won: u0,
      disputes-lost: u0,
      active: true
    }))
  )
)

(define-public (register-acquirer)
  (let ((caller tx-sender))
    (asserts! (is-none (map-get? acquirer-registrations caller)) ERR_ALREADY_EXISTS)
    (ok (map-set acquirer-registrations caller {
      proposals-submitted: u0,
      total-deployed: u0,
      governance-score: u100,
      active: true
    }))
  )
)

(define-public (submit-merger-proposal (target-dao principal) (offer-amount uint) (terms (string-ascii 500)))
  (let (
    (proposal-id (var-get next-proposal-id))
    (caller tx-sender)
  )
    (asserts! (> offer-amount u0) ERR_INVALID_AMOUNT)
    (asserts! (> (len terms) u0) ERR_INVALID_AMOUNT)
    (asserts! (is-some (map-get? acquirer-registrations caller)) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? dao-registrations target-dao)) ERR_NOT_FOUND)

    (try! (stx-transfer? offer-amount caller (as-contract tx-sender)))

    (map-set merger-proposals proposal-id {
      acquirer: caller,
      target-dao: target-dao,
      offer-amount: offer-amount,
      terms: terms,
      status: "pending",
      proposed-at: block-height,
      finalized-at: none,
      contested-at: none
    })

    (match (map-get? acquirer-registrations caller)
      acq-data (map-set acquirer-registrations caller (merge acq-data {
        proposals-submitted: (+ (get proposals-submitted acq-data) u1)
      }))
      false
    )

    (var-set next-proposal-id (+ proposal-id u1))
    (ok proposal-id)
  )
)

(define-public (accept-merger-proposal (proposal-id uint))
  (let (
    (caller tx-sender)
    (proposal-data (unwrap! (map-get? merger-proposals proposal-id) ERR_NOT_FOUND))
  )
    (asserts! (is-eq caller (get target-dao proposal-data)) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status proposal-data) "pending") ERR_INVALID_STATUS)

    (ok (map-set merger-proposals proposal-id (merge proposal-data {
      status: "active"
    })))
  )
)

(define-public (finalize-merger (proposal-id uint))
  (let (
    (caller tx-sender)
    (proposal-data (unwrap! (map-get? merger-proposals proposal-id) ERR_NOT_FOUND))
    (target-dao (get target-dao proposal-data))
    (offer-amount (get offer-amount proposal-data))
  )
    (asserts! (is-eq caller (get acquirer proposal-data)) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status proposal-data) "active") ERR_INVALID_STATUS)

    (try! (as-contract (stx-transfer? offer-amount tx-sender target-dao)))

    (map-set merger-proposals proposal-id (merge proposal-data {
      status: "completed",
      finalized-at: (some block-height)
    }))

    (match (map-get? dao-registrations target-dao)
      dao-data (map-set dao-registrations target-dao (merge dao-data {
        mergers-completed: (+ (get mergers-completed dao-data) u1),
        treasury-contributed: (+ (get treasury-contributed dao-data) offer-amount),
        governance-score: (+ (get governance-score dao-data) u5)
      }))
      false
    )

    (match (map-get? acquirer-registrations caller)
      acq-data (map-set acquirer-registrations caller (merge acq-data {
        total-deployed: (+ (get total-deployed acq-data) offer-amount)
      }))
      false
    )

    (ok true)
  )
)

(define-public (submit-assessment (proposal-id uint) (rating uint) (notes (string-ascii 500)))
  (let (
    (caller tx-sender)
    (proposal-data (unwrap! (map-get? merger-proposals proposal-id) ERR_NOT_FOUND))
  )
    (asserts! (is-eq (get status proposal-data) "completed") ERR_INVALID_STATUS)
    (asserts! (and (>= rating u1) (<= rating u5)) ERR_INVALID_AMOUNT)
    (asserts! (or (is-eq caller (get acquirer proposal-data))
                  (is-eq caller (get target-dao proposal-data))) ERR_UNAUTHORIZED)
    (asserts! (> (len notes) u0) ERR_INVALID_AMOUNT)

    (let ((existing-assessment (map-get? merger-assessments proposal-id)))
      (if (is-some existing-assessment)
        (let ((assessment-data (unwrap-panic existing-assessment)))
          (if (is-eq caller (get acquirer proposal-data))
            (ok (map-set merger-assessments proposal-id (merge assessment-data {
              acquirer-rating: rating,
              acquirer-notes: notes
            })))
            (ok (map-set merger-assessments proposal-id (merge assessment-data {
              dao-rating: rating,
              dao-notes: notes
            })))
          )
        )
        (if (is-eq caller (get acquirer proposal-data))
          (ok (map-set merger-assessments proposal-id {
            acquirer-rating: rating,
            dao-rating: u0,
            acquirer-notes: notes,
            dao-notes: "",
            assessed-at: block-height
          }))
          (ok (map-set merger-assessments proposal-id {
            acquirer-rating: u0,
            dao-rating: rating,
            acquirer-notes: "",
            dao-notes: notes,
            assessed-at: block-height
          }))
        )
      )
    )
  )
)

(define-public (file-contest (proposal-id uint) (grounds (string-ascii 500)))
  (let (
    (caller tx-sender)
    (proposal-data (unwrap! (map-get? merger-proposals proposal-id) ERR_NOT_FOUND))
    (contest-id (var-get next-contest-id))
  )
    (asserts! (or (is-eq caller (get acquirer proposal-data))
                  (is-eq caller (get target-dao proposal-data))) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status proposal-data) "active") ERR_INVALID_STATUS)
    (asserts! (> (len grounds) u0) ERR_INVALID_AMOUNT)

    (map-set merger-proposals proposal-id (merge proposal-data {
      status: "disputed",
      contested-at: (some block-height)
    }))

    (map-set merger-contests contest-id {
      proposal-id: proposal-id,
      challenger: caller,
      grounds: grounds,
      status: "open",
      filed-at: block-height,
      decision-deadline: (+ block-height (var-get voting-window)),
      arbiters: (list),
      votes-for-acquirer: u0,
      votes-for-dao: u0,
      decided-in-favor-of: none
    })

    (var-set next-contest-id (+ contest-id u1))
    (ok contest-id)
  )
)

(define-public (enroll-as-arbiter (contest-id uint))
  (let (
    (caller tx-sender)
    (contest-data (unwrap! (map-get? merger-contests contest-id) ERR_NOT_FOUND))
    (bond-amount (var-get min-delegate-stake))
  )
    (asserts! (is-eq (get status contest-data) "open") ERR_INVALID_STATUS)
    (asserts! (< (len (get arbiters contest-data)) u5) ERR_INVALID_STATUS)

    (try! (stx-transfer? bond-amount caller (as-contract tx-sender)))

    (map-set merger-contests contest-id (merge contest-data {
      arbiters: (unwrap! (as-max-len? (append (get arbiters contest-data) caller) u5) ERR_INVALID_STATUS),
      status: (if (is-eq (+ (len (get arbiters contest-data)) u1) u5) "voting" "open")
    }))

    (map-set arbiter-bonds { contest-id: contest-id, arbiter: caller } {
      amount: bond-amount,
      vote: none
    })

    (ok true)
  )
)

(define-public (cast-arbiter-vote (contest-id uint) (vote-for-acquirer bool))
  (let (
    (caller tx-sender)
    (contest-data (unwrap! (map-get? merger-contests contest-id) ERR_NOT_FOUND))
    (bond-data (unwrap! (map-get? arbiter-bonds { contest-id: contest-id, arbiter: caller }) ERR_UNAUTHORIZED))
  )
    (asserts! (is-eq (get status contest-data) "voting") ERR_INVALID_STATUS)
    (asserts! (< block-height (get decision-deadline contest-data)) ERR_VOTING_EXPIRED)
    (asserts! (is-none (get vote bond-data)) ERR_ALREADY_EXISTS)

    (map-set arbiter-bonds { contest-id: contest-id, arbiter: caller } (merge bond-data {
      vote: (some vote-for-acquirer)
    }))

    (if vote-for-acquirer
      (map-set merger-contests contest-id (merge contest-data {
        votes-for-acquirer: (+ (get votes-for-acquirer contest-data) u1)
      }))
      (map-set merger-contests contest-id (merge contest-data {
        votes-for-dao: (+ (get votes-for-dao contest-data) u1)
      }))
    )

    (ok true)
  )
)

(define-read-only (get-dao-registration (dao principal))
  (map-get? dao-registrations dao)
)

(define-read-only (get-acquirer-registration (acquirer principal))
  (map-get? acquirer-registrations acquirer)
)

(define-read-only (get-merger-proposal (proposal-id uint))
  (map-get? merger-proposals proposal-id)
)

(define-read-only (get-merger-assessment (proposal-id uint))
  (map-get? merger-assessments proposal-id)
)

(define-read-only (get-merger-contest (contest-id uint))
  (map-get? merger-contests contest-id)
)

(define-read-only (get-next-proposal-id)
  (var-get next-proposal-id)
)

(define-read-only (get-next-contest-id)
  (var-get next-contest-id)
)