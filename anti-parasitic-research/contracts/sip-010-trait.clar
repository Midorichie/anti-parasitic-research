;; SIP-010 Fungible Token Standard
(define-trait sip-010-trait
    (
        ;; Transfer from the caller to a new principal
        (transfer (uint principal principal (optional (buff 34))) (response bool uint))

        ;; Get token balance of owner
        (get-balance (principal) (response uint uint))

        ;; Get total supply of tokens
        (get-total-supply () (response uint uint))

        ;; Get human-readable name of token
        (get-name () (response (string-ascii 32) uint))

        ;; Get symbol for token
        (get-symbol () (response (string-ascii 32) uint))

        ;; Get number of decimals used for token amounts
        (get-decimals () (response uint uint))

        ;; Get URI containing token metadata
        (get-token-uri () (response (optional (string-utf8 256)) uint))
    )
)
