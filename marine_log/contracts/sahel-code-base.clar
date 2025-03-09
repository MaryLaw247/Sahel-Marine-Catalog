;; DeepSea Biometrics Registry
;; Implementation with tracking and permissions

;; Constants and Error Codes
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-INVALID-PARAMS (err u400))
(define-constant ERR-SPECIMEN-SEALED (err u403))
(define-constant ERR-LIST-FULL (err u429))

;; Data Validation Constants
(define-constant MAX-DEPTH-MULTIPLIER u15000)  ;; 15,000 meters in millimeters
(define-constant MAX-TEMP-RANGE 5000)          ;; Temperature in centikelvin
(define-constant MAX-LIST-SIZE u100)

;; Data Structures
(define-map specimens
    { specimen-id: uint }
    {
        researcher: principal,
        details: {
            species: (string-utf8 100),
            classification: (string-utf8 500),
            biology-type: (string-utf8 50)
        },
        habitat: {
            depth-min: uint,
            depth-max: uint,
            temperature: int,
            salinity: int
        },
        documentation: {
            genome-sequence: (string-ascii 100),
            discovered-at: uint
        },
        settings: {
            is-shareable: bool,
            specimen-sealed: bool
        }
    }
)

;; Researcher specimen tracking
(define-map specimens-by-researcher
    { researcher: principal }
    { specimen-ids: (list 100 uint) }
)

;; State Variables
(define-data-var specimen-counter uint u0)

;; Private Helper Functions

;; Validates environmental parameters
(define-private (validate-environment-params (temp int) (salinity int))
    (and 
        (and (>= temp (- MAX-TEMP-RANGE)) (<= temp MAX-TEMP-RANGE))
        (and (>= salinity 0) (<= salinity 100000))
    )
)

;; Validates depth range
(define-private (validate-depth-range (min uint) (max uint))
    (and 
        (>= min u0)
        (>= max min)
        (<= max MAX-DEPTH-MULTIPLIER)
    )
)

;; Updates researcher's specimen list safely
(define-private (update-researcher-specimen-list (researcher principal) (specimen-id uint) (is-add bool))
    (let (
        (current-data (default-to { specimen-ids: (list) } 
                      (map-get? specimens-by-researcher { researcher: researcher })))
        (current-ids (get specimen-ids current-data))
    )
        (if is-add
            ;; Adding specimen
            (if (>= (len current-ids) u100)
                ERR-LIST-FULL
                (ok (map-set specimens-by-researcher
                    { researcher: researcher }
                    { specimen-ids: (unwrap! (as-max-len? 
                        (append current-ids specimen-id) u100)
                        ERR-LIST-FULL) }
                )))
            ;; Do nothing for removal in this version
            (ok true)
        )
    )
)

;; Verifies specimen ownership
(define-private (is-specimen-owner (specimen-id uint))
    (match (map-get? specimens { specimen-id: specimen-id })
        data (is-eq tx-sender (get researcher data))
        false
    )
)

;; Public Functions

;; Registers a new marine specimen
(define-public (register-specimen 
        (species (string-utf8 100))
        (classification (string-utf8 500))
        (biology-type (string-utf8 50))
        (depth-min uint)
        (depth-max uint)
        (temperature int)
        (salinity int)
        (genome-sequence (string-ascii 100))
        (is-shareable bool))
    (let (
        (specimen-id (+ (var-get specimen-counter) u1))
        (current-time (unwrap-panic (get-block-info? time u0)))
    )
        ;; Input validation
        (asserts! (validate-depth-range depth-min depth-max) ERR-INVALID-PARAMS)
        (asserts! (validate-environment-params temperature salinity) ERR-INVALID-PARAMS)
        
        ;; Create specimen
        (map-set specimens
            { specimen-id: specimen-id }
            {
                researcher: tx-sender,
                details: {
                    species: species,
                    classification: classification,
                    biology-type: biology-type
                },
                habitat: {
                    depth-min: depth-min,
                    depth-max: depth-max,
                    temperature: temperature,
                    salinity: salinity
                },
                documentation: {
                    genome-sequence: genome-sequence,
                    discovered-at: current-time
                },
                settings: {
                    is-shareable: is-shareable,
                    specimen-sealed: false
                }
            }
        )
        
        ;; Update researcher's specimen list
        (try! (update-researcher-specimen-list tx-sender specimen-id true))
        
        ;; Update counter and return
        (var-set specimen-counter specimen-id)
        (ok specimen-id)
    )
)

;; Updates specimen details
(define-public (update-specimen-details
        (specimen-id uint)
        (species (string-utf8 100))
        (classification (string-utf8 500))
        (biology-type (string-utf8 50))
        (is-shareable bool))
    (let ((specimen (unwrap! (map-get? specimens { specimen-id: specimen-id }) ERR-NOT-FOUND)))
        (asserts! (is-specimen-owner specimen-id) ERR-NOT-AUTHORIZED)
        (asserts! (not (get specimen-sealed (get settings specimen))) ERR-SPECIMEN-SEALED)
        
        (map-set specimens
            { specimen-id: specimen-id }
            (merge specimen {
                details: {
                    species: species,
                    classification: classification,
                    biology-type: biology-type
                },
                settings: (merge (get settings specimen) {
                    is-shareable: is-shareable
                })
            })
        )
        (ok true)
    )
)

;; Seals specimen data (making it immutable)
(define-public (seal-specimen-data (specimen-id uint))
    (let ((specimen (unwrap! (map-get? specimens { specimen-id: specimen-id }) ERR-NOT-FOUND)))
        (asserts! (is-specimen-owner specimen-id) ERR-NOT-AUTHORIZED)
        
        (ok (map-set specimens
            { specimen-id: specimen-id }
            (merge specimen {
                settings: (merge (get settings specimen) {
                    specimen-sealed: true
                })
            })
        ))
    )
)

;; Read-Only Functions

;; Gets specimen information
(define-read-only (get-specimen (specimen-id uint))
    (map-get? specimens { specimen-id: specimen-id })
)

;; Gets all specimens cataloged by a researcher
(define-read-only (get-specimens-by-researcher (researcher principal))
    (default-to { specimen-ids: (list) }
        (map-get? specimens-by-researcher { researcher: researcher }))
)

;; Gets total number of registered specimens
(define-read-only (get-specimen-count)
    (ok (var-get specimen-counter))
)

;; Checks if a specimen's data is publicly shareable
(define-read-only (is-specimen-shareable (specimen-id uint))
    (match (map-get? specimens { specimen-id: specimen-id })
        data (ok (get is-shareable (get settings data)))
        (err ERR-NOT-FOUND)
    )
)