// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title BolivarOro - ERC-20 Rewards Token
 * @author Gustavo from Caracas, Venezuela
 * @notice Rewards token for the Venezuelan DeFi ecosystem
 * @dev Implements standard ERC-20 with additional functions for reward distribution
 * 
 * SPECIAL FEATURES:
 * - Reward distribution tracking system
 * - Educational functions for unit conversion
 * - Detailed events for auditing
 * - Robust validations with descriptive messages
 * 
 * USE CASES:
 * - Rewards token in staking protocols
 * - Liquidity incentives in DeFi
 * - Points and rewards system
 * - Tokenomics learning
 */
contract BolivarOro {

    // ========== STATE DECLARATIONS ==========
    
    /// @notice Full name of the rewards token
    string public name = "Bolivar Oro";
    
    /// @notice Token symbol (inspired by Bolivar de Oro)
    string public symbol = "BSORO";
    
    /// @notice Total supply of reward tokens (1 million with 18 decimals)
    uint256 public totalSupply = 1_000_000 * 10**18;
    
    /// @notice Token decimals (ERC-20 standard)
    uint8 public decimals = 18;
    
    /// @notice Contract creator address
    address public immutable creator;
    
    /// @notice Contract creation timestamp
    uint256 public immutable creationTime;

    // ========== ERC-20 EVENTS ==========
    
    /**
     * @dev Emitted when tokens are transferred
     * @param from Sender address
     * @param to Recipient address
     * @param value Amount of tokens transferred
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    /**
     * @dev Emitted when an allowance is approved
     * @param owner Token owner
     * @param spender Address authorized to spend
     * @param value Approved amount
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    
    /**
     * @dev Emitted when rewards are distributed
     * @param recipient Address receiving the reward
     * @param amount Amount of reward tokens
     */
    event RewardDistributed(
        address indexed recipient,
        uint256 amount
    );

    // ========== STATE MAPPINGS ==========
    
    /// @notice Token balance per address
    mapping(address => uint256) public balanceOf;
    
    /// @notice Approved allowances between addresses
    mapping(address => mapping(address => uint256)) public allowance;
    
    /// @notice Total rewards received by each address
    mapping(address => uint256) public totalRewardsReceived;
    
    /// @notice Reward distribution history
    mapping(address => uint256[]) public rewardHistory;

    // ========== CONSTRUCTOR ==========
    
    /**
     * @notice BolivarOro contract constructor
     * @dev Initializes the rewards token and assigns all supply to creator
     */
    constructor() {
        creator = msg.sender;
        creationTime = block.timestamp;
        balanceOf[msg.sender] = totalSupply;
        
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    // ========== MAIN ERC-20 FUNCTIONS ==========
    
    /**
     * @notice Transfers tokens to another address
     * @dev Standard ERC-20 transfer implementation
     * @param to Recipient address
     * @param amount Amount of tokens to transfer
     * @return success True if transfer was successful
     */
    function transfer(address to, uint256 amount) external returns (bool success) {
        require(to != address(0), "BolivarOro: Cannot transfer to zero address");
        require(balanceOf[msg.sender] >= amount, "BolivarOro: Insufficient balance");
        
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    /**
     * @notice Approves another address to spend tokens on your behalf
     * @dev Sets allowance for spender to use owner's tokens
     * @param spender Address authorized to spend
     * @param amount Maximum amount they can spend
     * @return success True if approval was successful
     */
    function approve(address spender, uint256 amount) external returns (bool success) {
        require(spender != address(0), "BolivarOro: Cannot approve zero address");
        
        allowance[msg.sender][spender] = amount;
        
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    /**
     * @notice Transfers tokens from one address using allowance
     * @dev Allows transferring tokens from 'from' to 'to' using previously approved allowance
     * @param from Address to transfer tokens from
     * @param to Recipient address
     * @param amount Amount of tokens to transfer
     * @return success True if transfer was successful
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool success) {
        require(from != address(0), "BolivarOro: Cannot transfer from zero address");
        require(to != address(0), "BolivarOro: Cannot transfer to zero address");
        require(balanceOf[from] >= amount, "BolivarOro: Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "BolivarOro: Insufficient allowance");
        
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        
        emit Transfer(from, to, amount);
        return true;
    }

    // ========== VIEW FUNCTIONS ==========
    
    /**
     * @dev Returns the balance of a specific address
     * @param account Address to query
     * @return balance Token balance of the address
     * @notice Query the BSORO token balance of an address
     */
    function getBalance(address account) public view returns (uint256 balance) {
        return balanceOf[account];
    }
    
    /**
     * @dev Returns the allowance between owner and spender
     * @param owner Token owner
     * @param spender Authorized address
     * @return remaining Remaining approved amount
     * @notice Query the approved amount to spend
     */
    function getAllowance(address owner, address spender) public view returns (uint256 remaining) {
        return allowance[owner][spender];
    }
    
    /**
     * @dev Returns the total rewards received by an address
     * @param account Address to query
     * @return totalRewards Total rewards received
     * @notice Query the historical total of rewards received
     */
    function getTotalRewards(address account) public view returns (uint256 totalRewards) {
        return totalRewardsReceived[account];
    }

    // ========== EDUCATIONAL FUNCTIONS ==========
     
     /**
      * @dev Converts tokens to the smallest unit (wei)
      * @param tokenAmount Amount of tokens in complete units
      * @return Amount in wei (smallest unit)
      * @notice Educational function to understand token units
      */
     function tokensToWei(uint256 tokenAmount) external pure returns (uint256) {
         return tokenAmount * 10**18;
     }
     
     /**
      * @dev Converts wei to tokens in complete units
      * @param weiAmount Amount in wei
      * @return Amount of tokens in complete units
      * @notice Educational function to understand conversions
      */
     function weiToTokens(uint256 weiAmount) external pure returns (uint256) {
         return weiAmount / 10**18;
     }
     
     /**
      * @dev Gets complete token information
      * @return name_ Token name
      * @return symbol_ Token symbol
      * @return decimals_ Token decimals
      * @return totalSupply_ Total supply
      * @return totalRewards_ Total rewards distributed
      * @notice Educational function to query all token information
      */
     function getTokenInfo() external view returns (
         string memory name_,
         string memory symbol_,
         uint8 decimals_,
         uint256 totalSupply_,
         uint256 totalRewards_
     ) {
         return (name, symbol, decimals, totalSupply, 0); // No tracking of total distributed in this contract
     }
     
     /**
      * @dev Gets the total rewards received by an address
      * @param recipient Address to query
      * @return Total rewards received
      * @notice Query how many rewards an address has received
      */
     function getTotalRewardsReceived(address recipient) external view returns (uint256) {
         return totalRewardsReceived[recipient];
     }
    
    /**
     * @dev Calculates the time elapsed since contract creation
     * @return timeElapsed Time in seconds since creation
     * @notice Returns how much time has passed since the contract was created
     */
    function getContractAge() public view returns (uint256 timeElapsed) {
        return block.timestamp - creationTime;
    }
    
    // ========== REWARD FUNCTIONS ==========
    
    /**
     * @dev Records reward distribution
     * @param recipient Recipient of the rewards
     * @param amount Amount of rewards distributed
     * @notice Function to record reward distributions
     */
    function recordRewardDistribution(address recipient, uint256 amount) external {
        require(recipient != address(0), "BolivarOro: Recipient cannot be zero address");
        require(amount > 0, "BolivarOro: Amount must be greater than zero");
        
        totalRewardsReceived[recipient] += amount;
        
        emit RewardDistributed(recipient, amount);
    }
    
    /**
     * @dev Records reward distribution (only for authorized contracts)
     * @param recipient Address receiving the reward
     * @param amount Amount of the reward
     * @notice Internal function to record reward distribution
     */
    function _recordRewardDistribution(address recipient, uint256 amount) internal {
        totalRewardsReceived[recipient] += amount;
        emit RewardDistributed(recipient, amount);
    }
}