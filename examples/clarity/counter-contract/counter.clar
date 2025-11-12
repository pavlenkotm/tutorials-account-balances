;; Simple Counter Contract
;; A production-ready counter with ownership and access control

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-underflow (err u101))
(define-constant err-overflow (err u102))

;; Data Variables
(define-data-var counter uint u0)
(define-data-var total-increments uint u0)
(define-data-var total-decrements uint u0)

;; Data Maps
(define-map user-counts principal uint)
(define-map user-last-action principal uint)

;; Read-only functions

;; Get current counter value
(define-read-only (get-counter)
    (ok (var-get counter))
)

;; Get total increments
(define-read-only (get-total-increments)
    (ok (var-get total-increments))
)

;; Get total decrements
(define-read-only (get-total-decrements)
    (ok (var-get total-decrements))
)

;; Get user's action count
(define-read-only (get-user-count (user principal))
    (ok (default-to u0 (map-get? user-counts user)))
)

;; Get user's last action block height
(define-read-only (get-user-last-action (user principal))
    (ok (default-to u0 (map-get? user-last-action user)))
)

;; Get contract owner
(define-read-only (get-owner)
    (ok contract-owner)
)

;; Check if caller is owner
(define-read-only (is-owner)
    (ok (is-eq tx-sender contract-owner))
)

;; Public functions

;; Increment the counter
(define-public (increment)
    (let
        (
            (current-value (var-get counter))
            (user-count (default-to u0 (map-get? user-counts tx-sender)))
        )
        ;; Check for overflow
        (asserts! (< current-value u340282366920938463463374607431768211455) err-overflow)

        ;; Update counter
        (var-set counter (+ current-value u1))

        ;; Update total increments
        (var-set total-increments (+ (var-get total-increments) u1))

        ;; Update user stats
        (map-set user-counts tx-sender (+ user-count u1))
        (map-set user-last-action tx-sender block-height)

        ;; Print event
        (print {
            event: "increment",
            user: tx-sender,
            new-value: (+ current-value u1),
            block: block-height
        })

        (ok (+ current-value u1))
    )
)

;; Decrement the counter
(define-public (decrement)
    (let
        (
            (current-value (var-get counter))
            (user-count (default-to u0 (map-get? user-counts tx-sender)))
        )
        ;; Check for underflow
        (asserts! (> current-value u0) err-underflow)

        ;; Update counter
        (var-set counter (- current-value u1))

        ;; Update total decrements
        (var-set total-decrements (+ (var-get total-decrements) u1))

        ;; Update user stats
        (map-set user-counts tx-sender (+ user-count u1))
        (map-set user-last-action tx-sender block-height)

        ;; Print event
        (print {
            event: "decrement",
            user: tx-sender,
            new-value: (- current-value u1),
            block: block-height
        })

        (ok (- current-value u1))
    )
)

;; Increment by a specific amount
(define-public (increment-by (amount uint))
    (let
        (
            (current-value (var-get counter))
            (user-count (default-to u0 (map-get? user-counts tx-sender)))
        )
        ;; Check for overflow
        (asserts! (<= amount (- u340282366920938463463374607431768211455 current-value)) err-overflow)

        ;; Update counter
        (var-set counter (+ current-value amount))

        ;; Update total increments
        (var-set total-increments (+ (var-get total-increments) amount))

        ;; Update user stats
        (map-set user-counts tx-sender (+ user-count u1))
        (map-set user-last-action tx-sender block-height)

        ;; Print event
        (print {
            event: "increment-by",
            user: tx-sender,
            amount: amount,
            new-value: (+ current-value amount),
            block: block-height
        })

        (ok (+ current-value amount))
    )
)

;; Reset the counter (owner only)
(define-public (reset)
    (begin
        ;; Check if caller is owner
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)

        ;; Reset counter
        (var-set counter u0)

        ;; Print event
        (print {
            event: "reset",
            user: tx-sender,
            block: block-height
        })

        (ok true)
    )
)

;; Set counter to specific value (owner only)
(define-public (set-counter (new-value uint))
    (begin
        ;; Check if caller is owner
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)

        ;; Set counter
        (var-set counter new-value)

        ;; Print event
        (print {
            event: "set-counter",
            user: tx-sender,
            new-value: new-value,
            block: block-height
        })

        (ok new-value)
    )
)
