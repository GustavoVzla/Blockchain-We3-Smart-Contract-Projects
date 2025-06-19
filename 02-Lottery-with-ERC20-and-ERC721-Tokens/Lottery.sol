// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title Lottery
 * @dev A lottery system using ERC-20 tokens for ticket purchases and ERC-721 NFTs for ticket representation
 * @author Gustavo
 */
contract Lottery is ERC20, Ownable, ReentrancyGuard, Pausable {
    // ============================================
    // EVENTS
    // ============================================

    event TokensPurchased(address indexed buyer, uint256 amount, uint256 cost);
    event TokensReturned(address indexed user, uint256 amount, uint256 refund);
    event TicketsPurchased(
        address indexed buyer,
        uint256 numTickets,
        uint256[] ticketNumbers
    );
    event WinnerGenerated(
        address indexed winner,
        uint256 prize,
        uint256 ticketNumber
    );
    event UserRegistered(address indexed user, address personalContract);

    // ============================================
    // TOKEN MANAGEMENT
    // ============================================

    /// @dev Address of the NFT contract for the project
    address public nft;

    /// @dev Constructor that initializes the lottery with tokens and NFT contract
    constructor() ERC20("Lottery", "LOTT") {
        _mint(address(this), 1000);
        nft = address(new MainERC721());
        _transferOwnership(msg.sender);
    }

    /// @dev Winner of the lottery prize
    address public winner;

    /// @dev User registration mapping
    mapping(address => address) public userContract;

    /**
     * @dev Calculate the price of ERC-20 tokens
     * @param _numTokens Number of tokens to price
     * @return Price in wei
     */
    function tokenPrice(uint256 _numTokens) internal pure returns (uint256) {
        return _numTokens * (1 ether);
    }

    /**
     * @dev View the ERC-20 token balance of a user
     * @param _account User address
     * @return Token balance
     */
    function getTokenBalance(address _account) public view returns (uint256) {
        return balanceOf(_account);
    }

    /**
     * @dev View the ERC-20 token balance of the Smart Contract
     * @return Contract token balance
     */
    function getContractTokenBalance() public view returns (uint256) {
        return balanceOf(address(this));
    }

    /**
     * @dev View the ether balance of the Smart Contract
     * @return Contract ether balance in ether units
     */
    function getContractEtherBalance() public view returns (uint256) {
        return address(this).balance / 10 ** 18;
    }

    /**
     * @dev Generate new ERC-20 tokens (only owner)
     * @param _amount Amount of tokens to mint
     */
    function mint(uint256 _amount) public onlyOwner {
        _mint(address(this), _amount);
    }

    /**
     * @dev Register users by creating their personal NFT contract
     */
    function registerUser() internal {
        address personalContractAddr = address(
            new TicketNFTs(msg.sender, address(this), nft)
        );
        userContract[msg.sender] = personalContractAddr;
        emit UserRegistered(msg.sender, personalContractAddr);
    }

    /**
     * @dev Get user information
     * @param _account User address
     * @return User's personal contract address
     */
    function getUserInfo(address _account) public view returns (address) {
        return userContract[_account];
    }

    /**
     * @dev Purchase ERC-20 tokens
     * @param _numTokens Number of tokens to purchase
     */
    function buyTokens(
        uint256 _numTokens
    ) public payable nonReentrant whenNotPaused {
        require(_numTokens > 0, "Number of tokens must be greater than 0");

        // Register user if not already registered
        if (userContract[msg.sender] == address(0)) {
            registerUser();
        }

        // Calculate the cost of tokens to purchase
        uint256 cost = tokenPrice(_numTokens);
        // Verify the user has sent enough ether
        require(msg.value >= cost, "Buy fewer tokens or pay with more ethers");
        // Get the number of available ERC-20 tokens
        uint256 balance = getContractTokenBalance();
        require(_numTokens <= balance, "Buy fewer tokens");

        // Send tokens to the client/user
        _transfer(address(this), msg.sender, _numTokens);

        // Return excess ether
        uint256 returnValue = msg.value - cost;
        if (returnValue > 0) {
            // Smart Contract returns the remaining amount
            (bool success, ) = payable(msg.sender).call{value: returnValue}("");
            require(success, "Failed to return excess ether");
        }

        emit TokensPurchased(msg.sender, _numTokens, cost);
    }

    /**
     * @dev Return tokens to the Smart Contract
     * @param _numTokens Number of tokens to return
     */
    function returnTokens(uint _numTokens) public nonReentrant whenNotPaused {
        // Number of tokens must be greater than 0
        require(_numTokens > 0, "You need to return more than 0 tokens");
        // User must have the tokens they want to return
        require(
            _numTokens <= getTokenBalance(msg.sender),
            "You don't have the tokens you want to return"
        );

        uint256 etherAmount = tokenPrice(_numTokens);
        require(
            address(this).balance >= etherAmount,
            "Insufficient contract balance"
        );

        // User transfers tokens to the Smart Contract
        _transfer(msg.sender, address(this), _numTokens);

        // Smart Contract sends ethers to the user
        (bool success, ) = payable(msg.sender).call{value: etherAmount}("");
        require(success, "Failed to transfer ether");

        emit TokensReturned(msg.sender, _numTokens, etherAmount);
    }

    // ============================================
    // LOTTERY MANAGEMENT
    // ============================================

    /// @dev Lottery ticket price (in ERC-20 tokens)
    uint public ticketPrice = 5;
    /// @dev Mapping: person who buys tickets -> ticket numbers
    mapping(address => uint[]) userTickets;
    /// @dev Mapping: ticket -> winner
    mapping(uint => address) ticketDNA;
    /// @dev Random number nonce
    uint randNonce = 0;
    /// @dev Generated lottery tickets
    uint[] purchasedTickets;

    /**
     * @dev Purchase lottery tickets
     * @param _numTickets Number of tickets to purchase
     */
    function buyTickets(uint _numTickets) public nonReentrant whenNotPaused {
        require(_numTickets > 0, "Number of tickets must be greater than 0");
        require(_numTickets <= 100, "Cannot buy more than 100 tickets at once");

        // Total price of tickets to purchase
        uint totalPrice = _numTickets * ticketPrice;
        // Verify user has enough tokens
        require(
            totalPrice <= getTokenBalance(msg.sender),
            "You don't have enough tokens"
        );

        // Ensure user is registered
        require(
            userContract[msg.sender] != address(0),
            "User must be registered first"
        );

        // Transfer tokens from user to Smart Contract
        _transfer(msg.sender, address(this), totalPrice);

        /* Collects timestamp (block.timestamp), msg.sender and a Nonce
        (a number used only once, so we don't execute the same 
        hash function twice with the same input parameters) incrementally.
        Uses 'keccak256' to convert these inputs to a random hash, 
        convert that hash to a uint and then use % 10000 to take the last 4 digits,
        giving a random value between 0 - 9999. */
        uint256[] memory ticketNumbers = new uint256[](_numTickets);

        for (uint i = 0; i < _numTickets; i++) {
            uint random = uint(
                keccak256(
                    abi.encodePacked(block.timestamp, msg.sender, randNonce, i)
                )
            ) % 10000;
            randNonce++;

            // Ensure ticket number is unique
            while (ticketDNA[random] != address(0)) {
                random =
                    uint(
                        keccak256(
                            abi.encodePacked(
                                block.timestamp,
                                msg.sender,
                                randNonce,
                                i
                            )
                        )
                    ) %
                    10000;
                randNonce++;
            }

            // Store ticket data linked to the user
            userTickets[msg.sender].push(random);
            // Store ticket data
            purchasedTickets.push(random);
            // Assign ticket DNA for winner generation
            ticketDNA[random] = msg.sender;
            // Create a new NFT for the ticket number
            TicketNFTs(userContract[msg.sender]).mintTicket(msg.sender, random);

            ticketNumbers[i] = random;
        }

        emit TicketsPurchased(msg.sender, _numTickets, ticketNumbers);
    }

    /**
     * @dev View user's tickets
     * @param _owner Ticket owner address
     * @return Array of ticket numbers owned by the user
     */
    function getUserTickets(
        address _owner
    ) public view returns (uint[] memory) {
        return userTickets[_owner];
    }

    /**
     * @dev Generate lottery winner (only owner)
     */
    function generateWinner() public onlyOwner nonReentrant {
        // Get array length
        uint length = purchasedTickets.length;
        // Verify at least 1 ticket was purchased
        require(length > 0, "No tickets purchased");
        // Ensure there's a balance to distribute
        require(address(this).balance > 0, "No prize pool available");

        // Random selection of a number between: [0-Length]
        uint random = uint(
            uint(
                keccak256(
                    abi.encodePacked(block.timestamp, block.difficulty, length)
                )
            ) % length
        );
        // Select the random number
        uint selection = purchasedTickets[random];
        // Address of the lottery winner
        winner = ticketDNA[selection];

        uint256 totalBalance = address(this).balance;
        uint256 winnerPrize = (totalBalance * 95) / 100;
        uint256 ownerFee = totalBalance - winnerPrize;

        // Send 95% of lottery prize to winner
        (bool winnerSuccess, ) = payable(winner).call{value: winnerPrize}("");
        require(winnerSuccess, "Failed to transfer prize to winner");

        // Send 5% of lottery prize to owner
        (bool ownerSuccess, ) = payable(owner()).call{value: ownerFee}("");
        require(ownerSuccess, "Failed to transfer fee to owner");

        emit WinnerGenerated(winner, winnerPrize, selection);
    }

    /**
     * @dev Pause the contract (only owner)
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract (only owner)
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Emergency withdrawal function (only owner)
     */
    function emergencyWithdraw() public onlyOwner {
        require(paused(), "Contract must be paused for emergency withdrawal");
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Emergency withdrawal failed");
    }
}

/**
 * @title MainERC721
 * @dev NFT Smart Contract for lottery tickets
 */
contract MainERC721 is ERC721 {
    /// @dev Address of the lottery contract
    address public lotteryAddress;

    /// @dev Constructor that initializes the NFT contract
    constructor() ERC721("Lottery", "LOTT") {
        lotteryAddress = msg.sender;
    }

    /**
     * @dev Create NFTs (only authorized contracts)
     * @param _owner NFT owner address
     * @param _ticket Ticket number to mint as NFT
     */
    function safeMint(address _owner, uint256 _ticket) public {
        require(
            msg.sender == Lottery(lotteryAddress).getUserInfo(_owner),
            "You don't have permission to execute this function"
        );
        _safeMint(_owner, _ticket);
    }
}

/**
 * @title TicketNFTs
 * @dev Personal contract for each user to manage their lottery ticket NFTs
 */
contract TicketNFTs {
    /// @dev Relevant owner data structure
    struct Owner {
        address ownerAddress;
        address parentContract;
        address nftContract;
        address userContract;
    }
    /// @dev Owner data structure instance
    Owner public owner;

    /**
     * @dev Constructor of the Smart Contract (child)
     * @param _owner Owner address
     * @param _parentContract Parent contract address
     * @param _nftContract NFT contract address
     */
    constructor(address _owner, address _parentContract, address _nftContract) {
        owner = Owner(_owner, _parentContract, _nftContract, address(this));
    }

    /**
     * @dev Convert lottery ticket numbers to NFTs
     * @param _owner Ticket owner address
     * @param _ticket Ticket number to mint
     */
    function mintTicket(address _owner, uint _ticket) public {
        require(
            msg.sender == owner.parentContract,
            "You don't have permission to execute this function"
        );
        MainERC721(owner.nftContract).safeMint(_owner, _ticket);
    }
}
