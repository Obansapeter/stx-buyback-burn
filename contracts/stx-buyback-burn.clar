;; ------------------------------------------------------------
;; STX Buyback & Burn Mechanism
;; Author: Code-for-Stacks Prototype
;; Version: 1.0
;; ------------------------------------------------------------

;; Contract Purpose:
;; This smart contract enables a DAO, treasury, or admin
;; to periodically burn STX tokens in a transparent, auditable way.

;; ------------------------------------------------------------
;; DATA VARIABLES
;; ------------------------------------------------------------

(define-data-var admin principal tx-sender)
(define-data-var burn-interval uint u1000)             ;; blocks between burns
(define-data-var last-burn-height uint u0)
(define-data-var total-burned uint u0)
(define-data-var paused bool false)

;; Burn address a special address with no known private key.
(define-constant BURN-ADDRESS 'SP000000000000000000002Q6VF78.burn)

;; Record each burn event in a map
(define-map burns
  { id: uint }
  {
    executor: principal,
    amount: uint,
    block-height: uint,
    memo: (optional (buff 50))
  }
)

(define-data-var next-burn-id uint u1)

;; ------------------------------------------------------------
;; ERRORS
;; ------------------------------------------------------------

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-TOO-SOON (err u101))
(define-constant ERR-INSUFFICIENT-STX (err u102))
(define-constant ERR-PAUSED (err u103))

;; ------------------------------------------------------------
;; ADMIN FUNCTIONS
;; ------------------------------------------------------------

(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR-NOT-AUTHORIZED)
    (var-set admin new-admin)
    (ok new-admin)
  )
)

(define-public (set-burn-interval (interval uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR-NOT-AUTHORIZED)
    (var-set burn-interval interval)
    (ok interval)
  )
)

(define-public (toggle-paused)
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR-NOT-AUTHORIZED)
    (var-set paused (not (var-get paused)))
    (ok (var-get paused))
  )
)

;; ------------------------------------------------------------
;; CORE LOGIC
;; ------------------------------------------------------------

;; Deposit STX into contract for future burns
(define-public (deposit (amount uint))
  (begin
    (asserts! (> amount u0) (err u400))
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (ok { event: "deposit", from: tx-sender, amount: amount })
  )
)

;; Execute burn (only admin or DAO should call)
(define-public (execute-burn (amount uint) (memo (optional (buff 50))))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR-NOT-AUTHORIZED)
    (asserts! (not (var-get paused)) ERR-PAUSED)
    (asserts! (>= stacks-block-height
                  (+ (var-get last-burn-height) (var-get burn-interval)))
              ERR-TOO-SOON)
    (asserts! (<= amount (stx-get-balance (as-contract tx-sender)))
              ERR-INSUFFICIENT-STX)

    ;; burn STX by sending to burn address
    (try! (stx-transfer? amount (as-contract tx-sender) BURN-ADDRESS))

    ;; record event
    (let ((burn-id (var-get next-burn-id)))
      (map-set burns
        { id: burn-id }
        {
          executor: tx-sender,
          amount: amount,
          block-height: stacks-block-height,
          memo: memo
        })
      (var-set next-burn-id (+ burn-id u1))
    )

    ;; update state
    (var-set total-burned (+ (var-get total-burned) amount))
    (var-set last-burn-height stacks-block-height)

    (ok {
      event: "burn",
      burned: amount,
      executor: tx-sender,
      total-burned: (var-get total-burned),
      height: stacks-block-height
    })
  )
)

;; ------------------------------------------------------------
;; READ-ONLY FUNCTIONS
;; ------------------------------------------------------------

(define-read-only (get-total-burned)
  (ok (var-get total-burned))
)

(define-read-only (get-last-burn-height)
  (ok (var-get last-burn-height))
)

(define-read-only (get-burn-by-id (id uint))
  (match (map-get? burns { id: id })
    burn (ok burn)
    (err u404))
)

(define-read-only (get-admin)
  (ok (var-get admin))
)

(define-read-only (is-paused)
  (ok (var-get paused))
)
