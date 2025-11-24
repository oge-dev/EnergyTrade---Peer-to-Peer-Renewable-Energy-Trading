# EnergyTrade - Peer-to-Peer Renewable Energy Trading

A blockchain-based platform for decentralized renewable energy trading built on Stacks using Clarity smart contracts. EnergyTrade enables direct energy transactions between producers and consumers, creates a transparent marketplace for renewable energy credits, issues verifiable green certificates, and democratizes the energy market through peer-to-peer trading.

## Overview

EnergyTrade revolutionizes the energy market by connecting renewable energy producers directly with consumers, eliminating traditional utility intermediaries. The platform enables solar panel owners, wind farm operators, and other green energy producers to sell excess energy at fair market prices while consumers can choose clean energy sources and support local renewable producers—all verified and automated through blockchain technology.

## Key Features

### For Energy Producers
- **Producer Registration**: Register renewable energy installations
- **Energy Listing**: Create sell orders for excess energy production
- **Price Control**: Set competitive prices per kilowatt-hour (kWh)
- **Multiple Energy Sources**: Solar, wind, hydro, geothermal support
- **Green Certificates**: Earn verifiable environmental credits
- **Production Tracking**: Monitor total energy produced and sold
- **Verification Status**: Build credibility through platform verification

### For Energy Consumers
- **Consumer Registration**: Join the green energy marketplace
- **Buy Orders**: Request specific amounts of renewable energy
- **Source Preferences**: Choose preferred energy types (solar, wind, etc.)
- **Price Limits**: Set maximum acceptable prices
- **Consumption Tracking**: Monitor energy usage and purchases
- **Environmental Impact**: Track carbon offset contributions

### Platform Features
- **Order Matching**: Automated buy/sell order matching system
- **Transparent Marketplace**: Real-time pricing and availability
- **Green Certificates**: Blockchain-verified environmental credits
- **Certificate Retirement**: Claim carbon offset credits
- **Grid Price Tracking**: Reference traditional grid pricing
- **Verification System**: Producer credential validation
- **Trading Statistics**: Platform-wide energy metrics

## Architecture

### Data Structures

#### Energy Producers
- Unique producer ID and wallet
- Producer name and details
- Energy source type (solar, wind, etc.)
- Production capacity (kW)
- Production rate and history
- Total energy produced and sold
- Verification status
- Registration timestamp

#### Energy Consumers
- Consumer identity and name
- Total energy consumed and purchased
- Preferred energy sources
- Registration timestamp

#### Sell Orders
- Producer reference
- Energy amount (kWh)
- Price per kWh
- Energy source type
- Fill status (partial/complete)
- Order status (active/filled/cancelled)
- Creation and expiry timestamps

#### Buy Orders
- Buyer identity
- Energy amount requested (kWh)
- Maximum price willing to pay
- Preferred energy source
- Fill status
- Order status
- Creation timestamp

#### Energy Trades
- Sell and buy order references
- Amount traded (kWh)
- Price per kWh
- Seller and buyer identities
- Transaction timestamp

#### Green Certificates
- Producer reference
- Energy amount certified
- Source type
- Issuance timestamp
- Retirement status
- Who retired the certificate

## Smart Contract Functions

### Registration

#### `register-producer`
```clarity
(register-producer (name (string-ascii 128)) 
                   (source-type (string-ascii 32)) 
                   (capacity uint))
```
Register as a renewable energy producer.

**Parameters:**
- `name`: Producer name (individual or company)
- `source-type`: Energy source ("solar", "wind", "hydro", "geothermal")
- `capacity`: Production capacity in kilowatts (kW)

**Returns:** Producer ID

**Validations:**
- Cannot register twice
- Capacity must be greater than 0

**Example:**
```clarity
;; Register 10kW rooftop solar installation
(contract-call? .energytrade register-producer 
  "Johnson Family Solar" 
  "solar" 
  u10000)
;; => (ok u1)
```

#### `register-consumer`
```clarity
(register-consumer (name (string-ascii 128)) 
                   (preferred-sources (list 5 (string-ascii 32))))
```
Register as an energy consumer.

**Parameters:**
- `name`: Consumer name
- `preferred-sources`: List of preferred energy types (up to 5)

**Returns:** Success confirmation

**Example:**
```clarity
;; Register consumer preferring solar and wind
(contract-call? .energytrade register-consumer 
  "Smith Household" 
  (list "solar" "wind"))
;; => (ok true)
```

### Energy Trading

#### `create-sell-order`
```clarity
(create-sell-order (amount-kwh uint) 
                   (price-per-kwh uint) 
                   (duration-blocks uint))
```
Create an order to sell energy (producer only).

**Parameters:**
- `amount-kwh`: Energy amount in kilowatt-hours
- `price-per-kwh`: Price per kWh in micro-STX
- `duration-blocks`: Order expiration time

**Returns:** Order ID

**Validations:**
- Must be verified producer
- Amount must be greater than 0
- Price must be greater than 0

**Example:**
```clarity
;; Sell 100 kWh at 80 micro-STX per kWh, expires in 1000 blocks
(contract-call? .energytrade create-sell-order 
  u100 
  u80 
  u1000)
;; => (ok u1)
```

#### `create-buy-order`
```clarity
(create-buy-order (amount-kwh uint) 
                  (max-price-per-kwh uint) 
                  (preferred-source (optional (string-ascii 32))))
```
Create an order to buy energy (consumer only).

**Parameters:**
- `amount-kwh`: Energy amount needed
- `max-price-per-kwh`: Maximum price willing to pay
- `preferred-source`: Optional preferred energy type

**Returns:** Order ID

**Validations:**
- Must be registered consumer
- Amount must be greater than 0

**Example:**
```clarity
;; Buy 50 kWh at max 100 micro-STX per kWh, prefer solar
(contract-call? .energytrade create-buy-order 
  u50 
  u100 
  (some "solar"))
;; => (ok u1)
```

#### `match-orders`
```clarity
(match-orders (sell-order-id uint) 
              (buy-order-id uint) 
              (amount uint))
```
Match a sell order with a buy order (any user can match).

**Parameters:**
- `sell-order-id`: Sell order to match
- `buy-order-id`: Buy order to match
- `amount`: Amount of energy to trade (kWh)

**Returns:** Success confirmation

**Validations:**
- Both orders must be active
- Sell price must be ≤ buy max price
- Amount must not exceed available quantity on either side
- Amount must be available in both orders

**Effects:**
- Updates fill status on both orders
- Changes status to "filled" when fully matched
- Records trade transaction
- Updates platform statistics

**Example:**
```clarity
;; Match 30 kWh from sell order 1 to buy order 1
(contract-call? .energytrade match-orders u1 u1 u30)
;; => (ok true)
```

#### `cancel-sell-order`
```clarity
(cancel-sell-order (order-id uint))
```
Cancel an active sell order (seller only).

**Parameters:**
- `order-id`: Order to cancel

**Returns:** Success confirmation

**Validations:**
- Must be order creator
- Order must be active

**Example:**
```clarity
(contract-call? .energytrade cancel-sell-order u1)
;; => (ok true)
```

### Green Certificates

#### `issue-green-certificate`
```clarity
(issue-green-certificate (producer-id uint) 
                         (energy-amount uint))
```
Issue a green certificate for renewable energy production (admin only).

**Parameters:**
- `producer-id`: Producer to certify
- `energy-amount`: Amount of energy to certify (kWh)

**Returns:** Certificate ID

**Access:** Contract owner only

**Validations:**
- Producer must be verified
- Must be admin/contract owner

**Example:**
```clarity
;; Issue certificate for 1000 kWh of solar energy
(contract-call? .energytrade issue-green-certificate u1 u1000)
;; => (ok u1)
```

#### `retire-certificate`
```clarity
(retire-certificate (certificate-id uint))
```
Retire a green certificate to claim environmental benefits.

**Parameters:**
- `certificate-id`: Certificate to retire

**Returns:** Success confirmation

**Validations:**
- Certificate must not already be retired

**Effects:**
- Marks certificate as retired
- Records who retired it
- Effectively "uses" the carbon offset credit

**Example:**
```clarity
(contract-call? .energytrade retire-certificate u1)
;; => (ok true)
```

### Administration

#### `verify-producer`
```clarity
(verify-producer (producer-id uint))
```
Verify a producer's credentials (admin only).

**Parameters:**
- `producer-id`: Producer to verify

**Returns:** Success confirmation

**Access:** Contract owner only

**Example:**
```clarity
(contract-call? .energytrade verify-producer u1)
;; => (ok true)
```

### Read-Only Functions

#### `get-producer`
```clarity
(get-producer (producer-id uint))
```
Retrieve producer details.

**Returns:** Producer data or none

#### `get-consumer`
```clarity
(get-consumer (consumer principal))
```
Retrieve consumer details.

**Returns:** Consumer data or none

#### `get-sell-order`
```clarity
(get-sell-order (order-id uint))
```
Retrieve sell order details.

**Returns:** Sell order data or none

#### `get-buy-order`
```clarity
(get-buy-order (order-id uint))
```
Retrieve buy order details.

**Returns:** Buy order data or none

#### `get-certificate`
```clarity
(get-certificate (certificate-id uint))
```
Retrieve green certificate details.

**Returns:** Certificate data or none

#### `get-platform-stats`
```clarity
(get-platform-stats)
```
Get platform-wide statistics.

**Returns:**
```clarity
{
  total-traded: uint,  // Total kWh traded
  grid-price: uint     // Reference grid price
}
```

## Constants & Configuration

### Grid Price Reference
- **Grid Price**: 100 micro-STX per kWh (adjustable baseline)
- **Purpose**: Reference for competitive pricing

### Error Codes
- `u100` (`err-owner-only`): Admin-only operation
- `u101` (`err-not-found`): Entity not found
- `u102` (`err-unauthorized`): Insufficient permissions or not verified
- `u103` (`err-insufficient-energy`): Not enough energy available
- `u104` (`err-invalid-price`): Invalid price or amount
- `u105` (`err-order-filled`): Order already filled or certificate already retired

## Usage Examples

### Complete Energy Trading Workflow

```clarity
;; PHASE 1: Registration

;; Solar panel owner registers as producer
(contract-call? .energytrade register-producer 
  "Green Valley Solar Farm" 
  "solar" 
  u500000)  ;; 500 kW capacity
;; => (ok u1)

;; Admin verifies the solar farm
(contract-call? .energytrade verify-producer u1)
;; => (ok true)

;; Household registers as consumer
(contract-call? .energytrade register-consumer 
  "Martinez Family" 
  (list "solar" "wind"))
;; => (ok true)

;; PHASE 2: Energy Production & Listing

;; Solar farm produces excess energy, creates sell order
;; Selling 1000 kWh at 75 micro-STX per kWh
;; Grid price is 100, offering 25% discount
(contract-call? .energytrade create-sell-order 
  u1000 
  u75 
  u14400)  ;; ~100 days expiry
;; => (ok u1)

;; PHASE 3: Energy Consumption & Purchase

;; Household needs energy, creates buy order
;; Wants 200 kWh, willing to pay up to 90 micro-STX per kWh
(contract-call? .energytrade create-buy-order 
  u200 
  u90 
  (some "solar"))
;; => (ok u1)

;; PHASE 4: Order Matching

;; Platform or any user matches compatible orders
(contract-call? .energytrade match-orders u1 u1 u200)
;; => (ok true)

;; Trade executed:
;; - Martinez family receives 200 kWh solar energy
;; - Pays 75 micro-STX per kWh = 15,000 micro-STX total
;; - Solar farm receives payment
;; - 800 kWh remaining on sell order

;; PHASE 5: Green Certificates

;; Admin issues green certificate for 1000 kWh production
(contract-call? .energytrade issue-green-certificate u1 u1000)
;; => (ok u1)

;; Martinez family retires certificate to claim carbon offset
(contract-call? .energytrade retire-certificate u1)
;; => (ok true)
;; Certificate now proves environmental contribution
```

### Community Solar Example

```clarity
;; Community solar project
(contract-call? .energytrade register-producer 
  "Neighborhood Solar Cooperative" 
  "solar" 
  u100000)  ;; 100 kW shared installation
;; => (ok u2)

(contract-call? .energytrade verify-producer u2)
;; => (ok true)

;; Multiple households buy from same source
;; Household 1: 50 kWh
(contract-call? .energytrade create-buy-order u50 u80 (some "solar"))

;; Household 2: 75 kWh
(contract-call? .energytrade create-buy-order u75 u80 (some "solar"))

;; Household 3: 100 kWh
(contract-call? .energytrade create-buy-order u100 u80 (some "solar"))

;; Community solar creates one sell order
(contract-call? .energytrade create-sell-order u500 u70 u7200)

;; Orders matched individually or in batch
(contract-call? .energytrade match-orders u2 u2 u50)
(contract-call? .energytrade match-orders u2 u3 u75)
(contract-call? .energytrade match-orders u2 u4 u100)

;; Total: 225 kWh distributed to 3 households
;; 275 kWh remaining for additional sales
```

### Dynamic Pricing Strategy

```clarity
;; Wind farm adjusts prices based on production

;; High wind day - abundant energy, lower prices
(contract-call? .energytrade create-sell-order 
  u2000 
  u60  ;; 40% below grid price
  u1440)  ;; 10 days

;; Low wind day - limited energy, higher prices
(contract-call? .energytrade create-sell-order 
  u500 
  u95  ;; 5% below grid price
  u720)  ;; 5 days

;; Consumers benefit from market-driven pricing
```

### Green Certificate Trading

```clarity
;; Producer accumulates certificates
(contract-call? .energytrade issue-green-certificate u1 u5000)
;; => (ok u1)

(contract-call? .energytrade issue-green-certificate u1 u5000)
;; => (ok u2)

(contract-call? .energytrade issue-green-certificate u1 u5000)
;; => (ok u3)

;; Company purchases and retires for carbon neutrality goals
(contract-call? .energytrade retire-certificate u1)
(contract-call? .energytrade retire-certificate u2)
(contract-call? .energytrade retire-certificate u3)

;; Company can now claim offset of 15,000 kWh renewable energy
```

## Economic Model

### Energy Pricing

**Competitive Pricing:**
```
Grid Price: 100 micro-STX per kWh (baseline)
P2P Market: 60-95 micro-STX per kWh (5-40% discount)
Consumer Savings: 5-40% vs traditional utility
Producer Profit: Direct sales, no middleman
```

**Example Transaction:**
```
Energy Amount: 100 kWh
Grid Price: 100 × 100 = 10,000 micro-STX
P2P Price: 100 × 75 = 7,500 micro-STX
Consumer Saves: 2,500 micro-STX (25%)
Producer Earns: 7,500 micro-STX (direct)
```

### Revenue Models

**For Producers:**
```
Rooftop Solar (10 kW):
- Daily Production: 40 kWh
- Excess Available: 25 kWh (after self-consumption)
- Sell Price: 80 micro-STX per kWh
- Daily Revenue: 25 × 80 = 2,000 micro-STX
- Monthly Revenue: ~60,000 micro-STX
- Annual Revenue: ~730,000 micro-STX
```

**For Consumers:**
```
Household (200 kWh/month):
- Grid Cost: 200 × 100 = 20,000 micro-STX
- P2P Cost: 200 × 75 = 15,000 micro-STX
- Monthly Savings: 5,000 micro-STX (25%)
- Annual Savings: 60,000 micro-STX
```

### Green Certificate Value

**Carbon Offset Economics:**
```
1 kWh renewable = ~0.5 kg CO2 avoided
1,000 kWh certificate = ~500 kg CO2 offset

Market Value (hypothetical):
- Corporate ESG demand
- Regulatory compliance
- Voluntary carbon markets
- Certificate trading marketplace
```

## Environmental Impact

### Carbon Reduction

**Individual Impact:**
```
Household using 200 kWh/month P2P solar:
- Annual renewable usage: 2,400 kWh
- CO2 avoided: ~1,200 kg (1.2 metric tons)
- Equivalent to: 
  - 2,700 miles not driven
  - 60 trees planted
  - 140 gallons of gasoline saved
```

**Platform Scale:**
```
10,000 households trading 200 kWh/month each:
- Annual renewable trading: 24 million kWh
- CO2 avoided: ~12,000 metric tons
- Equivalent to:
  - 2,600 cars off the road for a year
  - 14,000 acres of forest carbon sequestration
```

## Security Considerations

### Producer Verification
- Admin approval required before selling
- Capacity validation
- Source type verification
- Prevents fraudulent energy claims

### Order Matching Security
- Price validation (sell ≤ buy max)
- Quantity validation
- Double-fill prevention
- Status checks

### Certificate Integrity
- Unique certificate IDs
- Cannot retire twice
- Retirement tracking
- Immutable issuance records

### Access Control
- Producers can only create sell orders
- Consumers can only create buy orders
- Admin-only verification and certificate issuance
- Order cancellation restricted to creator

## Integration Examples

### Smart Meter Integration

```javascript
// Read smart meter data and create sell order
async function createSellOrderFromMeter(meterData) {
  const excessEnergy = meterData.produced - meterData.consumed;
  
  if (excessEnergy > 0) {
    const gridPrice = await getGridPrice();
    const p2pPrice = gridPrice * 0.80; // 20% discount
    
    await contractCall({
      functionName: 'create-sell-order',
      functionArgs: [excessEnergy, p2pPrice, 14400] // 100 day expiry
    });
  }
}
```

### Automated Order Matching

```javascript
// Match compatible orders automatically
async function autoMatchOrders() {
  const sellOrders = await getActiveSellOrders();
  const buyOrders = await getActiveBuyOrders();
  
  for (const sellOrder of sellOrders) {
    for (const buyOrder of buyOrders) {
      // Check price compatibility
      if (sellOrder.pricePerKwh <= buyOrder.maxPricePerKwh) {
        // Check source preference
        if (!buyOrder.preferredSource || 
            buyOrder.preferredSource === sellOrder.sourceType) {
          
          const amount = Math.min(
            sellOrder.amountKwh - sellOrder.filled,
            buyOrder.amountKwh - buyOrder.filled
          );
          
          if (amount > 0) {
            await contractCall('match-orders', 
              [sellOrder.id, buyOrder.id, amount]);
          }
        }
      }
    }
  }
}
```

### Energy Dashboard

```javascript
// Consumer energy dashboard
async function getConsumerDashboard(consumerAddress) {
  const consumer = await getConsumer(consumerAddress);
  const buyOrders = await getBuyOrdersByUser(consumerAddress);
  
  return {
    totalPurchased: consumer.totalPurchased,
    monthlyCost: calculateMonthlyCost(buyOrders),
    carbonOffset: consumer.totalPurchased * 0.5, // kg CO2
    preferredSources: consumer.preferredSources,
    savings: calculateSavings(consumer, gridPrice)
  };
}
```

### Certificate Registry

```javascript
// Track certificates for ESG reporting
async function getCertificatePortfolio(company) {
  const certificates = await getCertificatesByRetirer(company);
  
  const totalOffset = certificates.reduce((sum, cert) => 
    sum + (cert.energyAmount * 0.5), 0); // kg CO2
  
  return {
    totalCertificates: certificates.length,
    totalKwh: certificates.reduce((s, c) => s + c.energyAmount, 0),
    totalCO2Offset: totalOffset,
    sourceBreakdown: groupBySource(certificates)
  };
}
```

## Testing Recommendations

### Unit Tests
- [x] Producer registration
- [x] Consumer registration
- [x] Sell order creation
- [x] Buy order creation
- [x] Order matching with valid prices
- [x] Order matching with incompatible prices (should fail)
- [x] Insufficient energy handling
- [x] Order cancellation
- [x] Green certificate issuance
- [x] Certificate retirement
- [x] Producer verification
- [x] Duplicate registration prevention

### Integration Tests
- [ ] Complete trading workflow
- [ ] Multiple order matching
- [ ] Partial order fills
- [ ] Order expiration handling
- [ ] Certificate lifecycle
- [ ] Multi-producer scenarios

### Economic Tests
- [ ] Price discovery mechanisms
- [ ] Market equilibrium scenarios
- [ ] Grid price reference validation
- [ ] Savings calculations
- [ ] Revenue distribution

### Security Tests
- [ ] Unauthorized access attempts
- [ ] Order manipulation attempts
- [ ] Certificate double-retirement
- [ ] Invalid price handling
- [ ] Unverified producer restrictions

## Known Limitations & Future Enhancements

### Current Limitations
1. **No Actual Payments**: Tracks trades but doesn't transfer STX
2. **No Grid Integration**: Simulated grid connection
3. **Manual Matching**: Requires user action to match orders
4. **Limited Certificate Market**: Can't trade certificates
5. **No Time-of-Use Pricing**: Flat pricing model
6. **No Battery Storage**: Can't store energy for later sale

### Planned Enhancements

**Phase 1: Core Improvements**
- [ ] Implement actual STX transfers
- [ ] Automated order matching engine
- [ ] Time-of-use pricing
- [ ] Real-time grid price oracle integration
- [ ] Enhanced producer metadata

**Phase 2: Advanced Trading**
- [ ] Certificate marketplace (buy/sell certificates)
- [ ] Futures contracts for energy
- [ ] Options for price hedging
- [ ] Bulk energy packages
- [ ] Long-term purchase agreements

**Phase 3: Smart Grid**
- [ ] Battery storage integration
- [ ] Demand response automation
- [ ] Peak shaving mechanisms
- [ ] Load balancing algorithms
- [ ] Weather-based pricing

**Phase 4: Ecosystem**
- [ ] IoT smart meter integration
- [ ] Electric vehicle charging integration
- [ ] Community energy pools
- [ ] Microgrids support
- [ ] Cross-chain energy trading
- [ ] Carbon credit token standards

## Regulatory Considerations

### Energy Market Regulation
- May require utility commission approval
- Must comply with grid connection rules
- Net metering policy considerations
- Power purchase agreement regulations

### Environmental Credits
- REC (Renewable Energy Certificate) compliance
- Carbon offset verification standards
- Third-party certification requirements
- Regulatory reporting obligations

### Consumer Protection
- Transparent pricing requirements
- Energy delivery guarantees
- Billing accuracy standards
- Dispute resolution mechanisms

## Deployment

### Prerequisites
- Clarinet CLI
- Stacks wallet
- Smart meter infrastructure
- Grid connection permissions
- Regulatory compliance

### Deployment Steps

```bash
# 1. Test thoroughly
clarinet test

# 2. Validate contract
clarinet check

# 3. Deploy to testnet
clarinet deploy --testnet

# 4. Pilot program
# Test with small producer/consumer group

# 5. Production deployment
clarinet deploy --mainnet
```

## License

MIT License - See LICENSE file for details

## Disclaimer

This smart contract is provided for educational purposes. It is NOT a complete energy trading solution. Users must:

- Comply with energy regulations
- Obtain proper grid connection permits
- Implement smart meter infrastructure
- Follow consumer protection laws
- Handle tax reporting
- Ensure safety standards
- Consider insurance requirements

## Support & Contributing

- GitHub: [repository-url]
- Documentation: [docs-link]
- Energy Community: [forum-link]
- Discord: [community-link]

## Acknowledgments

Built to accelerate the renewable energy transition through decentralized technology. Special thanks to the Stacks community and renewable energy pioneers making clean energy accessible to everyone. 🌞⚡🌍
