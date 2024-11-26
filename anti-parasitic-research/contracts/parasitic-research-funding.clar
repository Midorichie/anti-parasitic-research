;; Anti-Parasitic Research Funding Platform
;; A decentralized crowdfunding platform for parasitology research projects
;; Version: 1.0.0

(use-trait sip-010-trait .sip-010-trait.sip-010-trait)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PROJECT-EXISTS (err u101))
(define-constant ERR-INVALID-AMOUNT (err u102))
(define-constant ERR-PROJECT-NOT-FOUND (err u103))
(define-constant ERR-MILESTONE-NOT-FOUND (err u104))
(define-constant ERR-MILESTONE-ALREADY-APPROVED (err u105))

;; Data structures
(define-map projects
    { project-id: uint }
    {
        owner: principal,
        title: (string-ascii 100),
        description: (string-ascii 500),
        funding-goal: uint,
        current-amount: uint,
        status: (string-ascii 20),
        milestone-count: uint
    }
)

(define-map milestones
    { project-id: uint, milestone-id: uint }
    {
        description: (string-ascii 200),
        required-amount: uint,
        status: (string-ascii 20),
        validator: principal
    }
)

(define-map project-funders
    { project-id: uint, funder: principal }
    { amount: uint }
)

;; Variables
(define-data-var project-nonce uint u0)

;; Public functions
(define-public (create-project
    (title (string-ascii 100))
    (description (string-ascii 500))
    (funding-goal uint))
    (let
        ((project-id (var-get project-nonce)))
        (asserts! (> funding-goal u0) ERR-INVALID-AMOUNT)
        (map-insert projects
            { project-id: project-id }
            {
                owner: tx-sender,
                title: title,
                description: description,
                funding-goal: funding-goal,
                current-amount: u0,
                status: "ACTIVE",
                milestone-count: u0
            }
        )
        (var-set project-nonce (+ project-id u1))
        (ok project-id)
    )
)

(define-public (add-milestone 
    (project-id uint)
    (description (string-ascii 200))
    (required-amount uint)
    (validator principal))
    (let
        ((project (unwrap! (map-get? projects { project-id: project-id }) ERR-PROJECT-NOT-FOUND))
         (milestone-id (get milestone-count project)))
        
        (asserts! (is-eq tx-sender (get owner project)) ERR-NOT-AUTHORIZED)
        (asserts! (> required-amount u0) ERR-INVALID-AMOUNT)
        
        (map-insert milestones
            { project-id: project-id, milestone-id: milestone-id }
            {
                description: description,
                required-amount: required-amount,
                status: "PENDING",
                validator: validator
            }
        )
        
        (map-set projects
            { project-id: project-id }
            (merge project { milestone-count: (+ milestone-id u1) })
        )
        (ok milestone-id)
    )
)

(define-public (fund-project 
    (project-id uint)
    (amount uint)
    (token <sip-010-trait>))
    (let
        ((project (unwrap! (map-get? projects { project-id: project-id }) ERR-PROJECT-NOT-FOUND))
         (current-funding (default-to u0 (get amount (map-get? project-funders { project-id: project-id, funder: tx-sender })))))
        
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (try! (contract-call? token transfer amount tx-sender (as-contract tx-sender) none))
        
        (map-set project-funders
            { project-id: project-id, funder: tx-sender }
            { amount: (+ current-funding amount) }
        )
        
        (map-set projects
            { project-id: project-id }
            (merge project { current-amount: (+ (get current-amount project) amount) })
        )
        (ok true)
    )
)

(define-public (approve-milestone
    (project-id uint)
    (milestone-id uint))
    (let
        ((milestone (unwrap! (map-get? milestones { project-id: project-id, milestone-id: milestone-id }) ERR-MILESTONE-NOT-FOUND))
         (project (unwrap! (map-get? projects { project-id: project-id }) ERR-PROJECT-NOT-FOUND)))
        
        (asserts! (is-eq tx-sender (get validator milestone)) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get status milestone) "PENDING") ERR-MILESTONE-ALREADY-APPROVED)
        
        (map-set milestones
            { project-id: project-id, milestone-id: milestone-id }
            (merge milestone { status: "APPROVED" })
        )
        (ok true)
    )
)

;; Read-only functions
(define-read-only (get-project (project-id uint))
    (map-get? projects { project-id: project-id })
)

(define-read-only (get-milestone (project-id uint) (milestone-id uint))
    (map-get? milestones { project-id: project-id, milestone-id: milestone-id })
)

(define-read-only (get-funder-amount (project-id uint) (funder principal))
    (map-get? project-funders { project-id: project-id, funder: funder })
)