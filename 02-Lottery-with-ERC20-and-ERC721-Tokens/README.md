# 🎰 Lottery System with ERC-20 and ERC-721 Tokens

> An educational lottery system using blockchain technology, developed by Gustavo

## 📋 Project Description

This project implements a complete lottery system that combines ERC-20 tokens for ticket purchases and ERC-721 NFTs for ticket representation. The system provides a transparent and decentralized lottery experience with automatic prize distribution.

### 🏗️ System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Lottery     │    │   MainERC721    │    │   TicketNFTs    │
│  (Main Contract)│    │  (NFT Contract) │    │ (User Contract) │
│                 │    │                 │    │                 │
│ • Token Sales   │    │ • Ticket NFTs   │    │ • Personal NFTs │
│ • Ticket Sales  │    │ • ERC-721       │    │ • Minting       │
│ • Prize Pool    │    │ • Verification  │    │ • Management    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       ▲                       │
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                          NFT Creation Flow
```

## 🚀 Main Features

### 🎰 **Lottery Contract** - Main System

- **Standard**: ERC-20 with lottery functionality
- **Supply**: 1,000 LOTT tokens (18 decimals)
- **Function**: Token sales and lottery management
- **Features**:
  - Token purchase with ETH
  - Token return functionality
  - Lottery ticket sales
  - Automatic winner selection
  - Prize distribution (95% winner, 5% owner)

### 🎫 **MainERC721** - NFT Tickets

- **Standard**: ERC-721 NFT
- **Symbol**: LOTT
- **Function**: Represents lottery tickets as NFTs
- **Features**:
  - Unique ticket representation
  - Secure minting process
  - Ownership verification
  - Integration with lottery system

### 👤 **TicketNFTs** - Personal Contracts

- **Function**: Individual user contract for NFT management
- **Features**:
  - Personal NFT minting
  - Ticket number conversion
  - User-specific contract deployment
  - Secure access control

## 🔧 Technical Functionalities

### 🔒 Security

- ✅ **Reentrancy Protection**: ReentrancyGuard on all critical functions
- ✅ **Pausable Functionality**: Emergency pause/unpause capabilities
- ✅ **Secure Ether Transfers**: Using call() instead of transfer()
- ✅ **Access Control**: Enhanced onlyOwner modifiers
- ✅ **Input Validation**: Comprehensive parameter checking
- ✅ **Unique Ticket Generation**: Collision-resistant ticket numbers
- ✅ **Emergency Controls**: Emergency withdrawal functionality
- ✅ **Event Logging**: Complete transparency through events

### 📊 State Management

- ✅ User registration tracking
- ✅ Ticket purchase history
- ✅ Winner selection records
- ✅ Token balance management
- ✅ NFT ownership tracking

### 🎓 Educational Functions

- ✅ **Modern Solidity Practices**: Latest version with built-in overflow protection
- ✅ **Security Patterns**: Reentrancy guards and pausable contracts
- ✅ **Gas Optimization**: Efficient storage and memory usage
- ✅ **Event-Driven Architecture**: Comprehensive logging system
- ✅ **Error Handling**: Robust error messages and validations
- ✅ **Administrative Controls**: Professional-grade management functions

## 📖 Usage Guide

### 1. 🚀 Contract Deployment

```solidity
// 1. Deploy Lottery Contract (automatically deploys MainERC721)
Lottery lottery = new Lottery();

// 2. Contract automatically mints 1000 tokens to itself
// 3. NFT contract is automatically created and linked
```

### 2. 💰 Token Purchase Process

```solidity
// 1. User buys tokens with ETH (with reentrancy protection)
lottery.buyTokens{value: msg.value}(numberOfTokens);

// 2. User can return tokens for ETH (secure transfers)
lottery.returnTokens(numberOfTokens);

// 3. Check user token balance
uint256 balance = lottery.getTokenBalance(userAddress);

// 4. Administrative functions (owner only)
lottery.pause();           // Pause contract in emergency
lottery.unpause();         // Resume operations
lottery.emergencyWithdraw(); // Emergency fund recovery
```

### 3. 🎫 Lottery Participation

```solidity
// 1. User buys lottery tickets (5 tokens per ticket, max 100 per transaction)
lottery.buyTickets(numberOfTickets);

// 2. View user's tickets
uint[] memory tickets = lottery.getUserTickets(userAddress);

// 3. Owner generates winner (with enhanced security)
lottery.generateWinner(); // Only owner can call

// 4. Check winner
address winner = lottery.winner();

// 5. Listen to events for real-time updates
// TokensPurchased, TicketsPurchased, WinnerGenerated events
```

### 4. 📊 Information Queries

```solidity
// Contract balances
uint256 tokenBalance = lottery.getContractTokenBalance();
uint256 etherBalance = lottery.getContractEtherBalance();

// User information
address userContract = lottery.getUserInfo(userAddress);
uint[] memory userTickets = lottery.getUserTickets(userAddress);

// Ticket price
uint256 price = lottery.ticketPrice();
```

## 🎯 Use Cases

### 📚 **Educational**

- Learning ERC-20 and ERC-721 development
- Understanding lottery mechanics
- Studying contract interactions
- Practice with Solidity and random number generation

### 🔬 **Testing and Development**

- Integration testing between contracts
- Lottery system simulation
- User interface development
- Smart contract auditing

### 🌟 **Demonstration**

- Blockchain skills showcase
- Web3 development portfolio
- Lottery system implementation
- Reference for gaming projects

## 🛠️ Technical Specifications

### 📋 Requirements

- **Solidity**: ^0.8.28
- **License**: MIT
- **Network**: Compatible with any EVM
- **Dependencies**: OpenZeppelin Contracts (latest)
- **Security**: ReentrancyGuard, Pausable functionality
- **Gas Optimization**: Enhanced for lower transaction costs

### 📊 System Parameters

- **Token Supply**: 1,000 LOTT tokens
- **Ticket Price**: 5 LOTT tokens per ticket
- **Prize Distribution**: 95% to winner, 5% to owner
- **Random Range**: 0-9999 for ticket numbers
- **Decimals**: 18 (ERC-20 standard)

### 🔍 Main Events

```solidity
// Custom Lottery Events (NEW)
event TokensPurchased(address indexed buyer, uint256 amount, uint256 cost);
event TokensReturned(address indexed user, uint256 amount, uint256 refund);
event TicketsPurchased(address indexed buyer, uint256 numTickets, uint256[] ticketNumbers);
event WinnerGenerated(address indexed winner, uint256 prize, uint256 ticketNumber);
event UserRegistered(address indexed user, address personalContract);

// ERC-20 Standard Events
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);

// ERC-721 Standard Events
event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
```

## 🔐 Administration Functions

### 👑 Owner Role

The contract owner can:

- 🎰 Generate lottery winners
- 💰 Mint additional tokens
- 📊 Monitor system statistics
- 🏆 Receive 5% of prize pool

### 🛡️ Security Modifiers

```solidity
modifier onlyOwner()         // Only the contract owner
modifier nonReentrant()      // Prevents reentrancy attacks
modifier whenNotPaused()     // Only when contract is not paused

// Enhanced Security Features:
// ✅ Reentrancy protection on all critical functions
// ✅ Pausable functionality for emergency situations
// ✅ Secure ether transfers with proper error handling
// ✅ Input validation and boundary checks
// ✅ Unique ticket number generation with collision detection
```

## 📈 Metrics and Statistics

### 📊 Trackable Information

- Total tokens in circulation
- Number of tickets sold
- Prize pool accumulation
- Winner history
- User participation
- NFT ownership records

### 🔍 Query Functions

```solidity
// Balance information
getTokenBalance(address)        // User token balance
getContractTokenBalance()       // Contract token balance
getContractEtherBalance()       // Contract ether balance

// User information
getUserInfo(address)            // User contract address
getUserTickets(address)         // User's ticket numbers

// System information
ticketPrice()                   // Current ticket price
winner()                        // Current lottery winner
```

## 🎰 Lottery System Features

### 🎲 Gaming Elements

- **Random Number Generation**: Secure pseudorandom ticket numbers
- **NFT Tickets**: Each ticket represented as unique NFT
- **Transparent Process**: All operations visible on blockchain
- **Fair Distribution**: Automated winner selection

### 🎨 System Nomenclature

- `buyTokens()` - Purchase lottery tokens with ETH
- `buyTicket()` - Purchase lottery tickets with tokens
- `generateWinner()` - Select lottery winner randomly
- `mintTicket()` - Create NFT representation of tickets

## 👨‍💻 Developer Information

**Author**: Gustavo  
**Purpose**: Educational project and blockchain skills demonstration  
**License**: MIT  
**Focus**: Lottery systems, ERC-20/ERC-721 integration, random number generation

## 🚀 Next Steps

### 🔮 Future Improvements

- [ ] **Chainlink VRF Integration**: Truly random number generation
- [ ] **Multi-signature Wallet**: Enhanced administrative security
- [ ] **Upgradeable Contracts**: Using proxy patterns for future updates
- [ ] **Time-based Lottery Rounds**: Automatic lottery cycles
- [ ] **Advanced Prize Pool Management**: Sophisticated distribution mechanisms
- [ ] **Web Interface**: Complete frontend for lottery participation
- [ ] **Analytics Dashboard**: Comprehensive statistics and history
- [ ] **Mobile App**: Native mobile application
- [ ] **Layer 2 Integration**: Polygon/Arbitrum deployment for lower fees

### 🧪 Testing

- [ ] **Complete Unit Test Suite**: Comprehensive function testing
- [ ] **Integration Tests**: Multi-contract interaction testing
- [ ] **Security Testing**: Reentrancy and attack vector testing
- [ ] **Gas Optimization Analysis**: Cost efficiency evaluation
- [ ] **Load Testing**: High-volume transaction simulation
- [ ] **Professional Security Audit**: Third-party security review
- [ ] **Formal Verification**: Mathematical proof of correctness
- [ ] **Mainnet Simulation**: Realistic environment testing

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

**Made with ❤️ for blockchain education! 🎰**
