;; stackarena.clar
;; On-chain PvP battle game for Stacks

;; --------------------------------
;; ERRORS
;; --------------------------------
(define-constant ERR_NOT_FOUND u100)
(define-constant ERR_ALREADY_REGISTERED u101)
(define-constant ERR_NOT_ENOUGH_STX u102)
(define-constant ERR_INVALID_TARGET u103)
(define-constant ERR_SELF_BATTLE u104)
(define-constant ERR_DEAD_HERO u105)
(define-constant ERR_NOT_OWNER u106)

;; --------------------------------
;; DATA VARIABLES
;; --------------------------------
(define-data-var owner principal tx-sender)
(define-data-var match-fee uint u1000000) ;; 1 STX per battle
(define-data-var heal-cost uint u500000)  ;; 0.5 STX per heal
(define-data-var upgrade-cost uint u2000000) ;; 2 STX per upgrade

;; --------------------------------
;; MAPS
;; --------------------------------
(define-map heroes
  principal
  (tuple
    (name (string-ascii 32))
    (power uint)
    (defense uint)
    (health uint)
    (wins uint)
    (losses uint)
    (alive bool)
  )
)

(define-map battles
  uint
  (tuple
    (player1 principal)
    (player2 principal)
    (winner principal)
    (timestamp uint)
  )
)

(define-data-var next-battle-id uint u0)

;; --------------------------------
;; PRIVATE HELPERS
;; --------------------------------
(define-private (only-owner)
  (if (is-eq tx-sender (var-get owner))
      (ok true)
      (err ERR_NOT_OWNER))
)

(define-private (get-random (seed uint) (max-val uint))
  (mod (+ seed u1) max-val)
)

(define-private (max-uint (a uint) (b uint))
  (if (>= a b) a b)
);; --------------------------------
;; PUBLIC FUNCTIONS
;; --------------------------------

;; 1. Register a hero
(define-public (create-hero (name (string-ascii 32)))
  (if (is-some (map-get? heroes tx-sender))
      (err ERR_ALREADY_REGISTERED)
      (begin
        (map-set heroes tx-sender
          (tuple
            (name name)
            (power u10)
            (defense u5)
            (health u100)
            (wins u0)
            (losses u0)
            (alive true)))
        (ok "Hero created successfully"))
  )
)

;; 2. Battle another hero
(define-public (battle (opponent principal))
  (if (is-eq tx-sender opponent)
      (err ERR_SELF_BATTLE)
      (let ((hero1 (map-get? heroes tx-sender))
            (hero2 (map-get? heroes opponent)))
        (match hero1
          h1
            (match hero2
              h2
                (if (and (get alive h1) (get alive h2))
                    (let ((battle-id (+ (var-get next-battle-id) u1))
                          (seed (get-random u1 u10))
                          (attack1 (+ (get power h1) seed))
                          (attack2 (+ (get power h2) (get-random (+ seed u5) u10))))
                      (begin
                        (try! (stx-transfer? (var-get match-fee) tx-sender contract-caller))
                        (try! (stx-transfer? (var-get match-fee) opponent contract-caller))
                        (if (> attack1 attack2)
                            (begin
                              (map-set heroes tx-sender
                                (tuple
                                  (name (get name h1))
                                  (power (+ (get power h1) u1))
                                  (defense (get defense h1))
                                  (health (get health h1))
                                  (wins (+ (get wins h1) u1))
                                  (losses (get losses h1))
                                  (alive true)))
                              (map-set heroes opponent
                                (tuple
                                  (name (get name h2))
                                  (power (get power h2))
                                  (defense (get defense h2))
                                  (health (max-uint u0 (- (get health h2) u10)))
                                  (wins (get wins h2))
                                  (losses (+ (get losses h2) u1))
                                  (alive (> (max-uint u0 (- (get health h2) u10)) u0))))
                              (try! (stx-transfer? (* u2 (var-get match-fee)) contract-caller tx-sender))
                              (map-set battles battle-id
                                (tuple
                                  (player1 tx-sender)
                                  (player2 opponent)
                                  (winner tx-sender)
                                  (timestamp u0)))
                              (var-set next-battle-id battle-id)
                              (ok (tuple (battle-id battle-id) (winner tx-sender))))
                            (begin
                              (map-set heroes opponent
                                (tuple
                                  (name (get name h2))
                                  (power (+ (get power h2) u1))
                                  (defense (get defense h2))
                                  (health (get health h2))
                                  (wins (+ (get wins h2) u1))
                                  (losses (get losses h2))
                                  (alive true)))
                              (map-set heroes tx-sender
                                (tuple
                                  (name (get name h1))
                                  (power (get power h1))
                                  (defense (get defense h1))
                                  (health (max-uint u0 (- (get health h1) u10)))
                                  (wins (get wins h1))
                                  (losses (+ (get losses h1) u1))
                                  (alive (> (max-uint u0 (- (get health h1) u10)) u0))))
                              (try! (stx-transfer? (* u2 (var-get match-fee)) contract-caller opponent))
                              (map-set battles battle-id
                                (tuple
                                  (player1 tx-sender)
                                  (player2 opponent)
                                  (winner opponent)
                                  (timestamp u0)))
                              (var-set next-battle-id battle-id)
                              (ok (tuple (battle-id battle-id) (winner opponent)))))))
                    (err ERR_DEAD_HERO))
              (err ERR_NOT_FOUND))
          (err ERR_NOT_FOUND)))
  )
)

;; 3. Heal your hero
(define-public (heal)
  (let ((h (map-get? heroes tx-sender)))
    (match h
      hero
        (begin
          (try! (stx-transfer? (var-get heal-cost) tx-sender contract-caller))
          (map-set heroes tx-sender
            (tuple
              (name (get name hero))
              (power (get power hero))
              (defense (get defense hero))
              (health u100)
              (wins (get wins hero))
              (losses (get losses hero))
              (alive true)))
          (ok "Hero healed"))
      (err ERR_NOT_FOUND)))
)

;; 4. Upgrade hero's stats
(define-public (upgrade)
  (let ((h (map-get? heroes tx-sender)))
    (match h
      hero
        (begin
          (try! (stx-transfer? (var-get upgrade-cost) tx-sender contract-caller))
          (map-set heroes tx-sender
            (tuple
              (name (get name hero))
              (power (+ (get power hero) u2))
              (defense (+ (get defense hero) u2))
              (health (get health hero))
              (wins (get wins hero))
              (losses (get losses hero))
              (alive (get alive hero))))
          (ok "Hero upgraded"))
      (err ERR_NOT_FOUND)))
)

;; 5. Admin - set fees
(define-public (set-fees (match-new uint) (heal-new uint) (upgrade-new uint))
  (if (is-eq tx-sender (var-get owner))
      (begin
        (var-set match-fee match-new)
        (var-set heal-cost heal-new)
        (var-set upgrade-cost upgrade-new)
        (ok "Fees updated"))
      (err ERR_NOT_OWNER))
)

;; --------------------------------
;; READ-ONLY FUNCTIONS
;; --------------------------------
(define-read-only (get-hero (user principal))
  (map-get? heroes user)
)

(define-read-only (get-battle (id uint))
  (map-get? battles id)
)
