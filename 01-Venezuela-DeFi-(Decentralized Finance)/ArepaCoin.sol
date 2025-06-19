// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title ArepaCoin - Educational ERC-20 Token
 * @author Gustavo from Caracas, Venezuela
 * @notice This contract implements a basic ERC-20 token for educational purposes
 * @dev Implements the standard ERC-20 interface with additional educational functions
 * 
 * EDUCATIONAL FEATURES:
 * - Clear and commented implementation of the ERC-20 standard
 * - Utility functions for unit conversion
 * - Detailed events for transaction tracking
 * - Robust validations with descriptive error messages
 * 
 * USE CASES:
 * - Base token for staking systems
 * - Token development learning
 * - Integration testing with other contracts
 */
contract ArepaCoin {
    // ========== STATE DECLARATIONS ==========

    /// @notice Full token name
    string public name = "Arepa Coin";

    /// @notice Token symbol (inspired by Venezuelan arepa)
    string public symbol = "AREPA";

    /// @notice Total token supply (1 million with 18 decimals)
    uint256 public totalSupply = 1_000_000 * 10 ** 18;

    /// @notice Token decimals (ERC-20 standard)
    uint8 public decimals = 18;

    /// @notice Contract creator address
    address public immutable creator;

    // ========== EVENTOS ERC-20 ==========

    /**
     * @dev Emitted when tokens are transferred
     * @param from Sender address
     * @param to Recipient address
     * @param value Amount of tokens transferred
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

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

    // ========== STATE MAPPINGS ==========

    /// @notice Token balance per address
    mapping(address => uint256) public balanceOf;

    /// @notice Approved allowances (owner => spender => amount)
    mapping(address => mapping(address => uint256)) public allowance;

    // ========== CONSTRUCTOR ==========

    /**
     * @dev Constructor that assigns all supply to the creator
     * @notice Initializes ArepaCoin token with complete supply to deployer
     */
    constructor() {
        creator = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    // ========== FUNCIONES ERC-20 ==========

    /**
     * @dev Transfers tokens from caller to another address
     * @param to Recipient address
     * @param value Amount of tokens to transfer
     * @return success True if transfer was successful
     * @notice Transfers AREPA tokens to specified address
     */
    function transfer(address to, uint256 value) public returns (bool success) {
        require(
            to != address(0),
            "ArepaCoin: Cannot transfer to zero address"
        );
        require(value > 0, "ArepaCoin: Amount must be greater than zero");
        require(
            balanceOf[msg.sender] >= value,
            "ArepaCoin: Insufficient balance"
        );

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approves a spender to spend tokens on behalf of owner
     * @param spender Address authorized to spend
     * @param value Maximum approved amount
     * @return success True if approval was successful
     * @notice Authorizes another address to spend your AREPA tokens
     */
    function approve(
        address spender,
        uint256 value
    ) public returns (bool success) {
        require(
            spender != address(0),
            "ArepaCoin: Cannot approve zero address"
        );

        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfers tokens from one address to another using allowance
     * @param from Sender address
     * @param to Recipient address
     * @param value Amount of tokens to transfer
     * @return success True if transfer was successful
     * @notice Transfers AREPA tokens using previously approved allowance
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool success) {
        require(
            from != address(0),
            "ArepaCoin: Cannot transfer from zero address"
        );
        require(
            to != address(0),
            "ArepaCoin: Cannot transfer to zero address"
        );
        require(value > 0, "ArepaCoin: Amount must be greater than zero");
        require(
            balanceOf[from] >= value,
            "ArepaCoin: Insufficient sender balance"
        );
        require(
            allowance[from][msg.sender] >= value,
            "ArepaCoin: Insufficient allowance"
        );

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;

        emit Transfer(from, to, value);
        return true;
    }

    // ========== VIEW FUNCTIONS ==========

    /**
     * @dev Returns the balance of a specific address
     * @param account Address to query
     * @return balance Token balance of the address
     * @notice Queries the AREPA token balance of an address
     */
    function getBalance(address account) public view returns (uint256 balance) {
        return balanceOf[account];
    }

    /**
     * @dev Returns the allowance between owner and spender
     * @param owner Token owner
     * @param spender Authorized address
     * @return remaining Remaining approved amount
     * @notice Queries the approved amount to spend
     */
    function getAllowance(
        address owner,
        address spender
    ) public view returns (uint256 remaining) {
        return allowance[owner][spender];
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
     * @notice Educational function to query all token information
     */
    function getTokenInfo() external view returns (
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_
    ) {
        return (name, symbol, decimals, totalSupply);
    }
}