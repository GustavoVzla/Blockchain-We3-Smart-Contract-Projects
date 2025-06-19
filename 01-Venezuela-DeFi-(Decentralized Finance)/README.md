# 🇻🇪 Venezuelan DeFi Ecosystem

> An educational DeFi ecosystem inspired by Venezuelan culture, developed by Gustavo from Caracas

## 📋 Project Description

This project implements a complete DeFi ecosystem that combines decentralized finance functionality with Venezuelan cultural identity. The system consists of three smart contracts working together to create a functional and educational staking protocol.

### 🏗️ Ecosystem Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   ArepaCoin     │    │   BolivarOro    │    │ CaracasHacienda │
│     (AREPA)     │    │     (BSORO)     │    │   (Protocol)    │
│                 │    │                 │    │                 │
│ • Base Token    │    │ • Reward Token  │    │ • Staking       │
│ • ERC-20        │    │ • ERC-20        │    │ • Distribution  │
│ • 1M Supply     │    │ • 1M Supply     │    │ • Management    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       ▲                       │
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                        Rewards Flow
```

## 🚀 Main Features

### 🪙 **ArepaCoin (AREPA)** - Staking Token

- **Standard**: Complete ERC-20
- **Supply**: 1,000,000 AREPA (18 decimals)
- **Function**: Base token for staking
- **Features**:
  - Secure transfers with validations
  - Allowance system
  - Educational conversion functions
  - Complete NatSpec documentation

### 🏆 **BolivarOro (BSORO)** - Rewards Token

- **Standard**: ERC-20 with additional functions
- **Supply**: 1,000,000 BSORO (18 decimals)
- **Function**: Rewards token distributed to stakers
- **Features**:
  - Tracking of distributed rewards
  - Distribution history
  - Advanced query functions
  - Rewards recording system

### 🏛️ **CaracasHacienda** - Staking Protocol

- **Function**: Main protocol contract
- **Features**:
  - AREPA token deposit and withdrawal
  - Automatic BSORO rewards distribution
  - Multiple stakers management (maximum 1,000)
  - Minimum staking time (1 day)
  - Administrative functions
  - Pause/activation system

## 🔧 Technical Functionalities

### 🔒 Security

- ✅ Zero address validation
- ✅ Sufficient balance verification
- ✅ Allowance control
- ✅ Access modifiers
- ✅ Reentrancy protection
- ✅ Staker limits
- ✅ Minimum staking time

### 📊 State Management

- ✅ Active stakers tracking
- ✅ Rewards history
- ✅ Protocol statistics
- ✅ Detailed information for each staker
- ✅ Reward rate control

### 🎓 Educational Functions

- ✅ Unit conversion (wei ↔ tokens)
- ✅ Complete information queries
- ✅ Potential rewards calculation
- ✅ Eligibility verification
- ✅ Protocol statistics

## 📖 Usage Guide

### 1. 🚀 Contract Deployment

```solidity
// 1. Deploy ArepaCoin
ArepaCoin arepaCoin = new ArepaCoin();

// 2. Deploy BolivarOro
BolivarOro bolivarOro = new BolivarOro();

// 3. Deploy CaracasHacienda
CaracasHacienda hacienda = new CaracasHacienda(bolivarOro, arepaCoin);

// 4. Transfer BSORO tokens to protocol for rewards
bolivarOro.transfer(address(hacienda), amount);
```

### 2. 💰 Staking Process

```solidity
// 1. User approves AREPA tokens to protocol
arepaCoin.approve(address(hacienda), amount);

// 2. User deposits tokens in the hacienda
hacienda.depositArepas(amount);

// 3. Hacendado distributes rewards
hacienda.distributeRewards();

// 4. User withdraws after minimum time
hacienda.withdrawArepas();
```

### 3. 📊 Information Queries

```solidity
// Staker information
(uint256 staked, uint256 startTime, uint256 rewards, uint256 lastReward, bool isActive) =
    hacienda.getStakerInfo(userAddress);

// Protocol statistics
(uint256 totalStaked, uint256 totalRewards, uint256 activeStakers, uint256 rate, bool active) =
    hacienda.getProtocolStatistics();

// Check if can withdraw
bool canWithdraw = hacienda.canWithdraw(userAddress);
```

## 🎯 Use Cases

### 📚 **Educational**

- Learning ERC-20 token development
- Understanding staking protocols
- Studying contract interactions
- Practice with Solidity and DeFi

### 🔬 **Testing and Development**

- Integration testing between contracts
- DeFi ecosystem simulation
- User interface development
- Smart contract auditing

### 🌟 **Demonstration**

- Blockchain skills showcase
- Web3 development portfolio
- Cultural identity example in DeFi
- Reference for similar projects

## 🛠️ Technical Specifications

### 📋 Requirements

- **Solidity**: ^0.8.28
- **License**: MIT
- **Network**: Compatible with any EVM
- **Gas**: Optimized for efficiency

### 📊 Protocol Parameters

- **Reward Rate**: 100 BSORO per AREPA per distribution (configurable)
- **Minimum Time**: 1 day (86,400 seconds)
- **Maximum Stakers**: 1,000 users
- **Decimals**: 18 (ERC-20 standard)

### 🔍 Main Events

```solidity
// ArepaCoin & BolivarOro
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);

// BolivarOro additional
event RewardDistributed(address indexed recipient, uint256 amount);

// CaracasHacienda
event TokensStaked(address indexed staker, uint256 amount, uint256 timestamp);
event TokensUnstaked(address indexed staker, uint256 amount, uint256 timestamp);
event RewardsDistributed(address indexed recipient, uint256 rewardAmount, uint256 timestamp);
event RewardRateUpdated(uint256 oldRate, uint256 newRate, uint256 timestamp);
event ProtocolStatusChanged(bool isActive, uint256 timestamp);
```

## 🔐 Administration Functions

### 👑 Hacendado Role

The hacendado (protocol owner) can:

- 📈 Update reward rates (1-1000)
- ⏸️ Pause/activate the protocol
- 💰 Distribute rewards to stakers
- 📊 Monitor protocol statistics

### 🛡️ Security Modifiers

```solidity
modifier onlyHacendado()     // Only the owner
modifier whenActive()        // Only when active
modifier validAmount()       // Valid amounts > 0
```

## 📈 Metrics and Statistics

### 📊 Trackable Information

- Total AREPA tokens in staking
- Total BSORO rewards distributed
- Number of active stakers
- History of each staker
- Protocol uptime
- Current reward rate

### 🔍 Query Functions

```solidity
// General information
getTotalStakers()           // Total number of stakers
getProtocolStatistics()     // Complete statistics
isActiveStaker(address)     // Check if active

// Specific information
getStakerInfo(address)      // Complete staker data
calculatePotentialReward()  // Calculate potential reward
canWithdraw(address)        // Check eligibility

// Educational utilities
tokensToHuman(uint256)      // Convert to readable format
humanToTokens(uint256)      // Convert to token units
```

## 🌟 Venezuelan Cultural Identity

### 🇻🇪 Cultural Elements

- **Arepa**: Traditional Venezuelan food → Base token
- **Bolívar de Oro**: Historical currency → Rewards token
- **Hacienda**: Traditional agricultural system → Staking protocol
- **Hacendado**: Hacienda administrator → Protocol owner

### 🎨 Thematic Nomenclature

- `depositArepas()` - Deposit tokens for staking
- `withdrawArepas()` - Withdraw tokens from staking
- `distributeRewards()` - Distribute rewards to workers
- Variables and comments maintain cultural theme

## 👨‍💻 Developer Information

**Author**: Gustavo  
**Location**: Madrid, Spain 🇻🇪  
**Purpose**: Educational project and skills demonstration  
**License**: MIT

## 🚀 Next Steps

### 🔮 Future Improvements

- [ ] Web interface to interact with contracts
- [ ] Decentralized governance system
- [ ] Multiple staking pools
- [ ] Price oracle integration
- [ ] Venezuelan-themed NFT system
- [ ] Advanced metrics and analytics

### 🧪 Testing

- [ ] Complete unit test suite
- [ ] Integration tests between contracts
- [ ] Usage scenario simulation
- [ ] Security audit
- [ ] Gas optimization analysis

---

## 📄 License

This project is under the MIT License. See the `LICENSE` file for more details.

## 🤝 Contributions

Contributions are welcome. Please:

1. Fork the project
2. Create a branch for your feature
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

---

**Made with ❤️ from Madrid, Espain! 🇻🇪**
