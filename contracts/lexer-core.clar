;; ======================================
;; LIQUIDITY MICRO-LEXER CONTRACT
;; ======================================
;; This contract manages decentralized data exchange and permission
;; tracking for microservices and privacy-preserving data interactions.
;; 
;; Core Functionality:
;; - Granular access control mechanisms
;; - Dynamic permission management
;; - Anonymized data contribution tracking
;; - Secure, consent-driven data sharing
;; 
;; All interactions are opt-in with full user sovereignty
;; over their personal and computational resources.
;; ======================================

;; ======================================
;; Error Constants
;; ======================================
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-ENTITY-EXISTS (err u101))
(define-constant ERR-ENTITY-NOT-FOUND (err u102))
(define-constant ERR-REGISTRATION-FAILED (err u103))
(define-constant ERR-PERMISSION-DENIED (err u104))
(define-constant ERR-INVALID-RESOURCE (err u105))
(define-constant ERR-CONSENT-VIOLATION (err u106))
(define-constant ERR-CONTRIBUTION-INVALID (err u107))

;; ======================================
;; Data Maps and Variables
;; ======================================

;; Participant registration and profile management
(define-map participants 
  { participant-id: principal } 
  {
    alias: (optional (string-utf8 50)),
    metadata-url: (optional (string-utf8 256)),
    registration-timestamp: uint,
    active: bool
  }
)

;; Resource type definitions
(define-map resource-types
  { type-id: (string-utf8 30) }
  {
    name: (string-utf8 50),
    description: (string-utf8 256),
    confidentiality-level: uint
  }
)

;; Permission tracking for data access
(define-map access-permissions
  { resource-owner: principal, accessor: principal, resource-type: (string-utf8 30) }
  {
    granted-at: uint,
    expires-at: uint,
    purpose: (string-utf8 100),
    revocable: bool,
    access-count: uint
  }
)

;; Decentralized contribution tracking
(define-map contribution-records
  { record-id: (string-utf8 64) }
  {
    contributor: principal,
    resource-type: (string-utf8 30),
    contribution-timestamp: uint,
    verification-status: bool,
    reward-claimed: bool
  }
)

;; Microservice authorization tokens
(define-map service-tokens
  { service-id: (string-utf8 50) }
  {
    issuer: principal,
    issued-at: uint,
    expiration: uint,
    scope: (list 10 (string-utf8 30))
  }
)

;; Administrative variables
(define-data-var protocol-admin principal tx-sender)
(define-data-var next-contribution-id uint u1)

;; ======================================
;; Private Functions
;; ======================================

;; Validate participant existence
(define-private (participant-exists (participant-id principal))
  (default-to false (get active (map-get? participants { participant-id: participant-id })))
)

;; Check administrative privileges
(define-private (is-protocol-admin)
  (is-eq tx-sender (var-get protocol-admin))
)

;; Validate resource type
(define-private (is-valid-resource-type (resource-type (string-utf8 30)))
  (is-some (map-get? resource-types { type-id: resource-type }))
)

;; ======================================
;; Read-Only Functions
;; ======================================

;; Retrieve participant profile
(define-read-only (get-participant-profile (participant-id principal))
  (map-get? participants { participant-id: participant-id })
)

;; Get resource type information
(define-read-only (get-resource-type-details (type-id (string-utf8 30)))
  (map-get? resource-types { type-id: type-id })
)

;; Check access permission status
(define-read-only (check-access-permission 
                   (resource-owner principal)
                   (accessor principal)
                   (resource-type (string-utf8 30)))
  (map-get? access-permissions 
    { 
      resource-owner: resource-owner, 
      accessor: accessor, 
      resource-type: resource-type 
    }
  )
)

;; ======================================
;; Public Functions
;; ======================================

;; Update participant profile
(define-public (update-participant-profile 
                (alias (optional (string-utf8 50))) 
                (metadata-url (optional (string-utf8 256))))
  (let ((participant-id tx-sender))
    (if (participant-exists participant-id)
      (begin
        (map-set participants
          { participant-id: participant-id }
          (merge 
            (default-to 
              { 
                alias: none,
                metadata-url: none,
                registration-timestamp: u0,
                active: true
              } 
              (map-get? participants { participant-id: participant-id })
            )
            {
              alias: alias,
              metadata-url: metadata-url
            }
          )
        )
        (ok true)
      )
      ERR-ENTITY-NOT-FOUND
    )
  )
)

;; Revoke access permission
(define-public (revoke-access-permission
                (accessor principal)
                (resource-type (string-utf8 30)))
  (let ((resource-owner tx-sender))
    (match (map-get? access-permissions 
             { 
               resource-owner: resource-owner, 
               accessor: accessor, 
               resource-type: resource-type 
             }
           )
      permission 
        (if (get revocable permission)
          (begin
            (map-delete access-permissions 
              { 
                resource-owner: resource-owner, 
                accessor: accessor, 
                resource-type: resource-type 
              }
            )
            (ok true)
          )
          ERR-UNAUTHORIZED
        )
      ERR-PERMISSION-DENIED
    )
  )
)

;; Add new resource type (admin function)
(define-public (register-resource-type
                (type-id (string-utf8 30))
                (name (string-utf8 50))
                (description (string-utf8 256))
                (confidentiality-level uint))
  (if (is-protocol-admin)
    (begin
      (map-set resource-types
        { type-id: type-id }
        {
          name: name,
          description: description,
          confidentiality-level: confidentiality-level
        }
      )
      (ok true)
    )
    ERR-UNAUTHORIZED
  )
)

;; Transfer protocol administration
(define-public (transfer-protocol-admin (new-admin principal))
  (if (is-protocol-admin)
    (begin
      (var-set protocol-admin new-admin)
      (ok true)
    )
    ERR-UNAUTHORIZED
  )
)