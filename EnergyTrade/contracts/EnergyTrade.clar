;; EnergyTrade - Peer-to-Peer Renewable Energy Trading
;; Energy credits, trading marketplace, and green certificates

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-insufficient-energy (err u103))
(define-constant err-invalid-price (err u104))
(define-constant err-order-filled (err u105))

(define-data-var next-producer-id uint u1)
(define-data-var next-order-id uint u1)
(define-data-var next-certificate-id uint u1)
(define-data-var total-energy-traded uint u0)
(define-data-var grid-price uint u100)

(define-map energy-producers
  uint
  {
    wallet: principal,
    name: (string-ascii 128),
    source-type: (string-ascii 32),
    capacity: uint,
    production-rate: uint,
    total-produced: uint,
    total-sold: uint,
    verified: bool,
    registered-at: uint
  }
)

(define-map producer-lookup principal uint)

(define-map energy-consumers
  principal
  {
    name: (string-ascii 128),
    total-consumed: uint,
    total-purchased: uint,
    preferred-sources: (list 5 (string-ascii 32)),
    joined-at: uint
  }
)

(define-map sell-orders
  uint
  {
    producer-id: uint,
    seller: principal,
    amount-kwh: uint,
    price-per-kwh: uint,
    source-type: (string-ascii 32),
    filled: uint,
    status: (string-ascii 16),
    created-at: uint,
    expires-at: uint
  }
)

(define-map buy-orders
  uint
  {
    buyer: principal,
    amount-kwh: uint,
    max-price-per-kwh: uint,
    preferred-source: (optional (string-ascii 32)),
    filled: uint,
    status: (string-ascii 16),
    created-at: uint
  }
)

(define-map energy-trades
  uint
  {
    sell-order-id: uint,
    buy-order-id: uint,
    amount-kwh: uint,
    price-per-kwh: uint,
    seller: principal,
    buyer: principal,
    timestamp: uint
  }
)

(define-map green-certificates
  uint
  {
    producer-id: uint,
    energy-amount: uint,
    source-type: (string-ascii 32),
    issued-at: uint,
    retired: bool,
    retired-by: (optional principal)
  }
)

(define-public (register-producer
    (name (string-ascii 128))
    (source-type (string-ascii 32))
    (capacity uint))
  (let ((producer-id (var-get next-producer-id)))
    (asserts! (is-none (map-get? producer-lookup tx-sender)) err-unauthorized)
    (asserts! (> capacity u0) err-invalid-price)

    (map-set energy-producers producer-id {
      wallet: tx-sender,
      name: name,
      source-type: source-type,
      capacity: capacity,
      production-rate: u0,
      total-produced: u0,
      total-sold: u0,
      verified: false,
      registered-at: block-height
    })

    (map-set producer-lookup tx-sender producer-id)
    (var-set next-producer-id (+ producer-id u1))

    (print {event: "producer-registered", producer-id: producer-id})
    (ok producer-id)
  )
)

(define-public (register-consumer
    (name (string-ascii 128))
    (preferred-sources (list 5 (string-ascii 32))))
  (begin
    (map-set energy-consumers tx-sender {
      name: name,
      total-consumed: u0,
      total-purchased: u0,
      preferred-sources: preferred-sources,
      joined-at: block-height
    })

    (print {event: "consumer-registered", consumer: tx-sender})
    (ok true)
  )
)

(define-public (create-sell-order
    (amount-kwh uint)
    (price-per-kwh uint)
    (duration-blocks uint))
  (let (
    (producer-id (unwrap! (map-get? producer-lookup tx-sender) err-not-found))
    (producer (unwrap! (map-get? energy-producers producer-id) err-not-found))
    (order-id (var-get next-order-id))
  )
    (asserts! (get verified producer) err-unauthorized)
    (asserts! (> amount-kwh u0) err-invalid-price)
    (asserts! (> price-per-kwh u0) err-invalid-price)

    (map-set sell-orders order-id {
      producer-id: producer-id,
      seller: tx-sender,
      amount-kwh: amount-kwh,
      price-per-kwh: price-per-kwh,
      source-type: (get source-type producer),
      filled: u0,
      status: "active",
      created-at: block-height,
      expires-at: (+ block-height duration-blocks)
    })

    (var-set next-order-id (+ order-id u1))

    (print {event: "sell-order-created", order-id: order-id, amount: amount-kwh})
    (ok order-id)
  )
)

(define-public (create-buy-order
    (amount-kwh uint)
    (max-price-per-kwh uint)
    (preferred-source (optional (string-ascii 32))))
  (let ((order-id (var-get next-order-id)))
    (asserts! (is-some (map-get? energy-consumers tx-sender)) err-not-found)
    (asserts! (> amount-kwh u0) err-invalid-price)

    (map-set buy-orders order-id {
      buyer: tx-sender,
      amount-kwh: amount-kwh,
      max-price-per-kwh: max-price-per-kwh,
      preferred-source: preferred-source,
      filled: u0,
      status: "active",
      created-at: block-height
    })

    (var-set next-order-id (+ order-id u1))

    (print {event: "buy-order-created", order-id: order-id, amount: amount-kwh})
    (ok order-id)
  )
)

(define-public (match-orders (sell-order-id uint) (buy-order-id uint) (amount uint))
  (let (
    (sell-order (unwrap! (map-get? sell-orders sell-order-id) err-not-found))
    (buy-order (unwrap! (map-get? buy-orders buy-order-id) err-not-found))
    (available-sell (- (get amount-kwh sell-order) (get filled sell-order)))
    (available-buy (- (get amount-kwh buy-order) (get filled buy-order)))
  )
    (asserts! (is-eq (get status sell-order) "active") err-order-filled)
    (asserts! (is-eq (get status buy-order) "active") err-order-filled)
    (asserts! (<= (get price-per-kwh sell-order) (get max-price-per-kwh buy-order)) err-invalid-price)
    (asserts! (<= amount available-sell) err-insufficient-energy)
    (asserts! (<= amount available-buy) err-insufficient-energy)

    (map-set sell-orders sell-order-id
      (merge sell-order {
        filled: (+ (get filled sell-order) amount),
        status: (if (is-eq (+ (get filled sell-order) amount) (get amount-kwh sell-order)) "filled" "active")
      }))

    (map-set buy-orders buy-order-id
      (merge buy-order {
        filled: (+ (get filled buy-order) amount),
        status: (if (is-eq (+ (get filled buy-order) amount) (get amount-kwh buy-order)) "filled" "active")
      }))

    (var-set total-energy-traded (+ (var-get total-energy-traded) amount))

    (print {event: "orders-matched", sell-id: sell-order-id, buy-id: buy-order-id, amount: amount})
    (ok true)
  )
)

(define-public (issue-green-certificate (producer-id uint) (energy-amount uint))
  (let (
    (producer (unwrap! (map-get? energy-producers producer-id) err-not-found))
    (certificate-id (var-get next-certificate-id))
  )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (get verified producer) err-unauthorized)

    (map-set green-certificates certificate-id {
      producer-id: producer-id,
      energy-amount: energy-amount,
      source-type: (get source-type producer),
      issued-at: block-height,
      retired: false,
      retired-by: none
    })

    (var-set next-certificate-id (+ certificate-id u1))

    (print {event: "certificate-issued", certificate-id: certificate-id, producer-id: producer-id})
    (ok certificate-id)
  )
)

(define-public (retire-certificate (certificate-id uint))
  (let ((certificate (unwrap! (map-get? green-certificates certificate-id) err-not-found)))
    (asserts! (not (get retired certificate)) err-order-filled)

    (map-set green-certificates certificate-id
      (merge certificate {
        retired: true,
        retired-by: (some tx-sender)
      }))

    (print {event: "certificate-retired", certificate-id: certificate-id, retiree: tx-sender})
    (ok true)
  )
)

(define-public (verify-producer (producer-id uint))
  (let ((producer (unwrap! (map-get? energy-producers producer-id) err-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)

    (map-set energy-producers producer-id (merge producer {verified: true}))

    (print {event: "producer-verified", producer-id: producer-id})
    (ok true)
  )
)

(define-public (cancel-sell-order (order-id uint))
  (let ((order (unwrap! (map-get? sell-orders order-id) err-not-found)))
    (asserts! (is-eq (get seller order) tx-sender) err-unauthorized)
    (asserts! (is-eq (get status order) "active") err-order-filled)

    (map-set sell-orders order-id (merge order {status: "cancelled"}))

    (print {event: "sell-order-cancelled", order-id: order-id})
    (ok true)
  )
)

(define-read-only (get-producer (producer-id uint))
  (map-get? energy-producers producer-id)
)

(define-read-only (get-consumer (consumer principal))
  (map-get? energy-consumers consumer)
)

(define-read-only (get-sell-order (order-id uint))
  (map-get? sell-orders order-id)
)

(define-read-only (get-buy-order (order-id uint))
  (map-get? buy-orders order-id)
)

(define-read-only (get-certificate (certificate-id uint))
  (map-get? green-certificates certificate-id)
)

(define-read-only (get-platform-stats)
  (ok {
    total-traded: (var-get total-energy-traded),
    grid-price: (var-get grid-price)
  })
)
