// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./ArepaCoin.sol";
import "./BolivarOro.sol";

/**
 * @title Caracas Hacienda - Venezuelan Staking Protocol
 * @dev Staking contract that allows depositing AREPA tokens to earn BSORO as rewards
 * @notice DeFi protocol inspired by traditional haciendas from Caracas, Venezuela
 * @author Gustavo - Caracas, Venezuela
 */
contract CaracasHacienda {
    // ========== STATE DECLARATIONS ==========

    /// @notice Descriptive name of the staking protocol
    string public name = "Caracas Hacienda - Staking Protocol";

    /// @notice Protocol owner (hacienda administrator)
    address public immutable hacendado;

    /// @notice Token deposited for staking (AREPA)
    ArepaCoin public immutable arepaCoin;

    /// @notice Reward token distributed (BSORO)
    BolivarOro public immutable bolivarOro;

    /// @notice Protocol creation timestamp
    uint256 public immutable protocolCreationTime;

    /// @notice Reward rate per distribution (BSORO tokens per staked AREPA token)
    uint256 public rewardRate = 100; // 100 BSORO per AREPA per distribution

    /// @notice Minimum staking time in seconds (1 day)
    uint256 public constant MINIMUM_STAKING_TIME = 1 days;

    /// @notice Maximum number of allowed stakers
    uint256 public constant MAX_STAKERS = 1000;

    /// @notice Protocol status (active/paused)
    bool public protocolActive = true;

    // ========== DATA STRUCTURES ==========

    /**
     * @dev Detailed information for each staker
     * @param stakedAmount Total amount of staked AREPA tokens
     * @param stakingStartTime Timestamp when staking began
     * @param lastRewardTime Last timestamp when rewards were calculated
     * @param totalRewardsEarned Historical total of earned rewards
     * @param isCurrentlyStaking Whether currently staking
     */
    struct StakerInfo {
        uint256 stakedAmount;
        uint256 stakingStartTime;
        uint256 lastRewardTime;
        uint256 totalRewardsEarned;
        bool isCurrentlyStaking;
    }

    /// @notice List of addresses that have staked
    address[] public stakers;

    /// @notice Detailed information for each staker
    mapping(address => StakerInfo) public stakerInfo;

    /// @notice Whether an address has ever staked
    mapping(address => bool) public hasEverStaked;

    /// @notice Total AREPA tokens staked in the protocol
    uint256 public totalStaked;

    /// @notice Total BSORO rewards distributed
    uint256 public totalRewardsDistributed;

    // ========== EVENTS ==========

    /**
     * @dev Emitted when a user stakes tokens
     * @param staker Address of the user staking
     * @param amount Amount of AREPA tokens staked
     * @param timestamp Moment of staking
     */
    event TokensStaked(
        address indexed staker,
        uint256 amount,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a user withdraws their staked tokens
     * @param staker Address of the user withdrawing
     * @param amount Amount of AREPA tokens withdrawn
     * @param timestamp Moment of withdrawal
     */
    event TokensUnstaked(
        address indexed staker,
        uint256 amount,
        uint256 timestamp
    );

    /**
     * @dev Emitted when rewards are distributed
     * @param recipient Address receiving the rewards
     * @param rewardAmount Amount of BSORO tokens distributed
     * @param timestamp Moment of distribution
     */
    event RewardsDistributed(
        address indexed recipient,
        uint256 rewardAmount,
        uint256 timestamp
    );

    /**
     * @dev Emitted when the hacendado changes the reward rate
     * @param oldRate Previous rate
     * @param newRate New rate
     * @param timestamp Moment of change
     */
    event RewardRateUpdated(
        uint256 oldRate,
        uint256 newRate,
        uint256 timestamp
    );

    /**
     * @dev Emitted when the protocol is paused or activated
     * @param isActive New protocol status
     * @param timestamp Moment of change
     */
    event ProtocolStatusChanged(bool isActive, uint256 timestamp);

    // ========== MODIFIERS ==========

    /**
     * @dev Only allows the hacendado (owner) to execute the function
     */
    modifier onlyHacendado() {
        require(
            msg.sender == hacendado,
            "CaracasHacienda: Only the hacendado can execute this function"
        );
        _;
    }

    /**
     * @dev Only allows execution when the protocol is active
     */
    modifier whenActive() {
        require(protocolActive, "CaracasHacienda: Protocol is paused");
        _;
    }

    /**
     * @dev Validates that the amount is greater than zero
     */
    modifier validAmount(uint256 amount) {
        require(
            amount > 0,
            "CaracasHacienda: Amount must be greater than zero"
        );
        _;
    }

    // ========== CONSTRUCTOR ==========

    /**
     * @dev Constructor that initializes the staking protocol
     * @param _bolivarOro Address of the reward token contract
     * @param _arepaCoin Address of the staking token contract
     * @notice Initializes the Caracas Hacienda with the specified tokens
     */
    constructor(BolivarOro _bolivarOro, ArepaCoin _arepaCoin) {
        require(
            address(_bolivarOro) != address(0),
            "CaracasHacienda: BolivarOro address cannot be zero"
        );
        require(
            address(_arepaCoin) != address(0),
            "CaracasHacienda: ArepaCoin address cannot be zero"
        );

        bolivarOro = _bolivarOro;
        arepaCoin = _arepaCoin;
        hacendado = msg.sender;
        protocolCreationTime = block.timestamp;
    }

    // ========== MAIN FUNCTIONS ==========

    /**
     * @dev Allows users to stake AREPA tokens
     * @param amount Amount of AREPA tokens to stake
     * @notice Deposits AREPA tokens in the hacienda to earn BSORO rewards
     */
    function depositArepas(
        uint256 amount
    ) external whenActive validAmount(amount) {
        require(
            stakers.length < MAX_STAKERS,
            "CaracasHacienda: Maximum number of stakers reached"
        );

        // Transfer AREPA tokens to the contract
        require(
            arepaCoin.transferFrom(msg.sender, address(this), amount),
            "CaracasHacienda: AREPA transfer failed"
        );

        // If first time staking, add to the list
        if (!hasEverStaked[msg.sender]) {
            stakers.push(msg.sender);
            hasEverStaked[msg.sender] = true;
        }

        // Update staker information
        StakerInfo storage staker = stakerInfo[msg.sender];
        staker.stakedAmount += amount;
        staker.isCurrentlyStaking = true;

        // If first deposit, set timestamps
        if (staker.stakingStartTime == 0) {
            staker.stakingStartTime = block.timestamp;
            staker.lastRewardTime = block.timestamp;
        }

        // Update protocol totals
        totalStaked += amount;

        emit TokensStaked(msg.sender, amount, block.timestamp);
    }

    /**
     * @dev Allows users to withdraw their staked AREPA tokens
     * @notice Withdraws all AREPA tokens deposited in the hacienda
     */
    function withdrawArepas() external {
        StakerInfo storage staker = stakerInfo[msg.sender];
        uint256 stakedAmount = staker.stakedAmount;

        require(stakedAmount > 0, "CaracasHacienda: You have no staked tokens");
        require(
            block.timestamp >= staker.stakingStartTime + MINIMUM_STAKING_TIME,
            "CaracasHacienda: Minimum staking time not met"
        );

        // Reset staker information
        staker.stakedAmount = 0;
        staker.isCurrentlyStaking = false;

        // Update protocol totals
        totalStaked -= stakedAmount;

        // Transfer AREPA tokens back to user
        require(
            arepaCoin.transfer(msg.sender, stakedAmount),
            "CaracasHacienda: AREPA transfer failed"
        );

        emit TokensUnstaked(msg.sender, stakedAmount, block.timestamp);
    }

    /**
     * @dev Distributes BSORO rewards to all active stakers
     * @notice Only the hacendado can distribute rewards to hacienda workers
     */
    function distributeRewards() external onlyHacendado {
        require(stakers.length > 0, "CaracasHacienda: No stakers to reward");

        uint256 totalRewardsThisRound = 0;

        for (uint256 i = 0; i < stakers.length; i++) {
            address stakerAddress = stakers[i];
            StakerInfo storage staker = stakerInfo[stakerAddress];

            if (staker.isCurrentlyStaking && staker.stakedAmount > 0) {
                // Calculate reward based on staked amount
                uint256 reward = (staker.stakedAmount * rewardRate) / 100;

                if (reward > 0) {
                    // Update staker information
                    staker.totalRewardsEarned += reward;
                    staker.lastRewardTime = block.timestamp;

                    // Transfer BSORO reward
                    require(
                        bolivarOro.transfer(stakerAddress, reward),
                        "CaracasHacienda: Reward transfer failed"
                    );

                    totalRewardsThisRound += reward;
                    emit RewardsDistributed(
                        stakerAddress,
                        reward,
                        block.timestamp
                    );
                }
            }
        }

        totalRewardsDistributed += totalRewardsThisRound;
    }

    // ========== ADMINISTRATION FUNCTIONS ==========

    /**
     * @dev Allows the hacendado to change the reward rate
     * @param newRate New reward rate
     * @notice Updates the protocol's reward rate
     */
    function updateRewardRate(uint256 newRate) external onlyHacendado {
        require(
            newRate > 0 && newRate <= 1000,
            "CaracasHacienda: Rate must be between 1 and 1000"
        );

        uint256 oldRate = rewardRate;
        rewardRate = newRate;

        emit RewardRateUpdated(oldRate, newRate, block.timestamp);
    }

    /**
     * @dev Allows the hacendado to pause or activate the protocol
     * @param isActive New protocol status
     * @notice Pauses or activates protocol operations
     */
    function changeProtocolStatus(bool isActive) external onlyHacendado {
        protocolActive = isActive;
        emit ProtocolStatusChanged(isActive, block.timestamp);
    }

    // ========== VIEW FUNCTIONS ==========

    /**
     * @dev Gets detailed information about a staker
     * @param stakerAddress Address of the staker
     * @return stakedAmount Total amount of staked AREPA tokens
     * @return stakingStartTime Timestamp when staking began
     * @return totalRewardsEarned Historical total of earned rewards
     * @return lastRewardTime Last timestamp when rewards were calculated
     * @return isCurrentlyStaking Whether currently staking
     * @notice Educational function to query staking data
     */
    function getStakerInfo(
        address stakerAddress
    )
        external
        view
        returns (
            uint256 stakedAmount,
            uint256 stakingStartTime,
            uint256 totalRewardsEarned,
            uint256 lastRewardTime,
            bool isCurrentlyStaking
        )
    {
        StakerInfo memory staker = stakerInfo[stakerAddress];
        return (
            staker.stakedAmount,
            staker.stakingStartTime,
            staker.totalRewardsEarned,
            staker.lastRewardTime,
            staker.isCurrentlyStaking
        );
    }

    /**
     * @dev Gets the total number of stakers
     * @return Total number of registered stakers
     * @notice Query how many workers the hacienda has
     */
    function getTotalStakers() external view returns (uint256) {
        return stakers.length;
    }

    /**
     * @dev Gets general protocol statistics
     * @return totalStakedAmount Total amount of AREPA tokens staked in the protocol
     * @return totalRewards Total rewards distributed by the protocol
     * @return activeStakers Number of currently active stakers
     * @return currentRewardRate Current reward rate per second
     * @return isActive Whether the protocol is currently active
     * @notice Educational function to monitor the protocol
     */
    function getProtocolStatistics()
        external
        view
        returns (
            uint256 totalStakedAmount,
            uint256 totalRewards,
            uint256 activeStakers,
            uint256 currentRewardRate,
            bool isActive
        )
    {
        uint256 activeCount = 0;
        for (uint256 i = 0; i < stakers.length; i++) {
            if (stakerInfo[stakers[i]].isCurrentlyStaking) {
                activeCount++;
            }
        }

        return (
            totalStaked,
            totalRewardsDistributed,
            activeCount,
            rewardRate,
            protocolActive
        );
    }

    /**
     * @dev Checks if an address is an active staker
     * @param stakerAddress Address to verify
     * @return true if it's an active staker
     * @notice Utility function to verify staking status
     */
    function isActiveStaker(
        address stakerAddress
    ) external view returns (bool) {
        return stakerInfo[stakerAddress].isCurrentlyStaking;
    }

    /**
     * @dev Calculates potential reward for a token amount
     * @param amount Amount of AREPA tokens
     * @return Potential reward in BSORO tokens
     * @notice Educational function to calculate rewards
     */
    function calculatePotentialReward(
        uint256 amount
    ) external view returns (uint256) {
        return (amount * rewardRate) / 100;
    }

    // ========== EDUCATIONAL HELPER FUNCTIONS ==========

    /**
     * @dev Converts tokens to human readable format
     * @param tokenAmount Amount in smallest units
     * @return Amount in decimal format
     * @notice Converts token amount to human readable format
     */
    function tokensToHuman(
        uint256 tokenAmount
    ) external pure returns (uint256) {
        return tokenAmount / 10 ** 18;
    }

    /**
     * @dev Converts decimal amount to token units
     * @param humanAmount Amount in decimal format
     * @return Amount in smallest units
     * @notice Converts decimal amount to token units
     */
    function humanToTokens(
        uint256 humanAmount
    ) external pure returns (uint256) {
        return humanAmount * 10 ** 18;
    }

    /**
     * @dev Checks if an address can withdraw their tokens
     * @param stakerAddress Address to verify
     * @return True if can withdraw
     * @notice Checks if a worker can withdraw their arepas
     */
    function canWithdraw(address stakerAddress) external view returns (bool) {
        StakerInfo memory staker = stakerInfo[stakerAddress];

        if (staker.stakedAmount == 0) return false;

        return
            block.timestamp >= staker.stakingStartTime + MINIMUM_STAKING_TIME;
    }
}
