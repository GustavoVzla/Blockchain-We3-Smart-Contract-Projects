// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title NFT Marketplace
 * @dev A secure marketplace for trading ERC721 NFTs with fee collection
 * @author Smart Contract Developer
 */
contract Marketplace is ReentrancyGuard, Pausable, Ownable {

    address payable public feeAccount;
    uint256 public feePercent;
    uint256 public itemCount;
    
    // Constants
    uint256 public constant MAX_FEE_PERCENT = 1000; // 10% maximum fee
    
    // Mappings
    mapping(address => bool) public authorizedNFTs;
    mapping(address => uint256) public sellerItemCount;

    struct Item {
        uint256 itemId;
        IERC721 nft;
        uint256 tokenId;
        uint256 price;
        address payable seller;
        bool sold;
        uint256 timestamp;
        bool active;
    }

    mapping(uint => Item) public items;

    // Events
    event ItemListed(
        uint256 indexed itemId,
        address indexed nft,
        uint256 indexed tokenId,
        uint256 price,
        address seller,
        uint256 timestamp
    );
    
    event ItemSold(
        uint256 indexed itemId,
        address indexed nft,
        uint256 indexed tokenId,
        uint256 price,
        address seller,
        address buyer,
        uint256 fee,
        uint256 timestamp
    );
    
    event ItemDelisted(
        uint256 indexed itemId,
        address indexed nft,
        uint256 indexed tokenId,
        address seller,
        uint256 timestamp
    );
    
    event FeeUpdated(uint256 oldFee, uint256 newFee, uint256 timestamp);
    event FeeAccountUpdated(address oldAccount, address newAccount, uint256 timestamp);
    event NFTAuthorized(address indexed nft, bool authorized, uint256 timestamp);
    event RefundIssued(address indexed buyer, uint256 amount, uint256 timestamp);

    /**
     * @dev Constructor sets initial fee percentage and fee account
     * @param _feePercent Initial fee percentage (in basis points, e.g., 250 = 2.5%)
     */
    constructor(uint256 _feePercent) Ownable(msg.sender) {
        require(_feePercent <= MAX_FEE_PERCENT, "Fee percentage too high");
        feeAccount = payable(msg.sender);
        feePercent = _feePercent;
        
        emit FeeUpdated(0, _feePercent, block.timestamp);
    }

    /**
     * @dev List an NFT for sale in the marketplace
     * @param _nft The NFT contract address
     * @param _tokenId The token ID to list
     * @param _price The listing price in wei
     */
    function listItem(IERC721 _nft, uint256 _tokenId, uint256 _price) 
        external 
        nonReentrant 
        whenNotPaused 
    {
        require(_price > 0, "Price must be greater than zero");
        require(_nft.ownerOf(_tokenId) == msg.sender, "Not the owner of this NFT");
        require(_nft.getApproved(_tokenId) == address(this) || 
                _nft.isApprovedForAll(msg.sender, address(this)), 
                "Marketplace not approved to transfer NFT");
        
        itemCount++;
        sellerItemCount[msg.sender]++;
        
        // Transfer NFT to marketplace
        _nft.transferFrom(msg.sender, address(this), _tokenId);
        
        items[itemCount] = Item({
            itemId: itemCount,
            nft: _nft,
            tokenId: _tokenId,
            price: _price,
            seller: payable(msg.sender),
            sold: false,
            timestamp: block.timestamp,
            active: true
        });
        
        emit ItemListed(
            itemCount,
            address(_nft),
            _tokenId,
            _price,
            msg.sender,
            block.timestamp
        );
    }

    /**
     * @dev Purchase an NFT from the marketplace
     * @param _itemId The ID of the item to purchase
     */
    function purchaseItem(uint256 _itemId) 
        external 
        payable 
        nonReentrant 
        whenNotPaused 
    {
        require(_itemId > 0 && _itemId <= itemCount, "Invalid item ID");
        
        Item storage item = items[_itemId];
        require(item.active, "Item not active");
        require(!item.sold, "Item already sold");
        require(msg.sender != item.seller, "Cannot buy your own item");
        
        uint256 totalPrice = getTotalPrice(_itemId);
        require(msg.value >= totalPrice, "Insufficient payment");
        
        uint256 fee = totalPrice - item.price;
        
        // Mark as sold before transfers to prevent reentrancy
        item.sold = true;
        item.active = false;
        sellerItemCount[item.seller]--;
        
        // Secure transfers using call
        (bool sellerSuccess, ) = item.seller.call{value: item.price}("");
        require(sellerSuccess, "Transfer to seller failed");
        
        (bool feeSuccess, ) = feeAccount.call{value: fee}("");
        require(feeSuccess, "Fee transfer failed");
        
        // Transfer NFT to buyer
        item.nft.transferFrom(address(this), msg.sender, item.tokenId);
        
        // Refund excess payment
        if (msg.value > totalPrice) {
            uint256 refund = msg.value - totalPrice;
            (bool refundSuccess, ) = payable(msg.sender).call{value: refund}("");
            require(refundSuccess, "Refund failed");
            emit RefundIssued(msg.sender, refund, block.timestamp);
        }
        
        emit ItemSold(
            _itemId,
            address(item.nft),
            item.tokenId,
            item.price,
            item.seller,
            msg.sender,
            fee,
            block.timestamp
        );
    }

    /**
     * @dev Calculate total price including marketplace fee
     * @param _itemId The item ID
     * @return Total price including fee
     */
    function getTotalPrice(uint256 _itemId) public view returns(uint256) {
         require(_itemId > 0 && _itemId <= itemCount, "Invalid item ID");
         return (items[_itemId].price * (10000 + feePercent)) / 10000;
     }

    /**
     * @dev Delist an item from the marketplace (seller or owner only)
     * @param _itemId The item ID to delist
     */
    function delistItem(uint256 _itemId) external nonReentrant {
        require(_itemId > 0 && _itemId <= itemCount, "Invalid item ID");
        
        Item storage item = items[_itemId];
        require(item.active, "Item not active");
        require(!item.sold, "Item already sold");
        require(msg.sender == item.seller || msg.sender == owner(), "Not authorized");
        
        item.active = false;
        sellerItemCount[item.seller]--;
        
        // Return NFT to seller
        item.nft.transferFrom(address(this), item.seller, item.tokenId);
        
        emit ItemDelisted(
            _itemId,
            address(item.nft),
            item.tokenId,
            item.seller,
            block.timestamp
        );
    }

    /**
     * @dev Update marketplace fee (owner only)
     * @param _newFeePercent New fee percentage in basis points
     */
    function updateFeePercent(uint256 _newFeePercent) external onlyOwner {
        require(_newFeePercent <= MAX_FEE_PERCENT, "Fee percentage too high");
        
        uint256 oldFee = feePercent;
        feePercent = _newFeePercent;
        
        emit FeeUpdated(oldFee, _newFeePercent, block.timestamp);
    }

    /**
     * @dev Update fee account (owner only)
     * @param _newFeeAccount New fee account address
     */
    function updateFeeAccount(address payable _newFeeAccount) external onlyOwner {
        require(_newFeeAccount != address(0), "Invalid fee account");
        
        address oldAccount = feeAccount;
        feeAccount = _newFeeAccount;
        
        emit FeeAccountUpdated(oldAccount, _newFeeAccount, block.timestamp);
    }

    /**
     * @dev Authorize or deauthorize NFT contracts (owner only)
     * @param _nft NFT contract address
     * @param _authorized Authorization status
     */
    function setNFTAuthorization(address _nft, bool _authorized) external onlyOwner {
        require(_nft != address(0), "Invalid NFT address");
        
        authorizedNFTs[_nft] = _authorized;
        
        emit NFTAuthorized(_nft, _authorized, block.timestamp);
    }

    /**
     * @dev Pause the marketplace (owner only)
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the marketplace (owner only)
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Get item details
     * @param _itemId The item ID
     * @return Item details
     */
    function getItem(uint256 _itemId) external view returns (
        uint256 itemId,
        address nft,
        uint256 tokenId,
        uint256 price,
        address seller,
        bool sold,
        uint256 timestamp,
        bool active
    ) {
        require(_itemId > 0 && _itemId <= itemCount, "Invalid item ID");
        
        Item storage item = items[_itemId];
        return (
            item.itemId,
            address(item.nft),
            item.tokenId,
            item.price,
            item.seller,
            item.sold,
            item.timestamp,
            item.active
        );
    }

    /**
     * @dev Get marketplace statistics
     * @return totalItems Total items ever listed
     * @return activeItems Currently active items
     * @return totalSales Total completed sales
     */
    function getMarketplaceStats() external view returns (
        uint256 totalItems,
        uint256 activeItems,
        uint256 totalSales
    ) {
        uint256 active = 0;
        uint256 sales = 0;
        
        for (uint256 i = 1; i <= itemCount; i++) {
            if (items[i].active) {
                active++;
            }
            if (items[i].sold) {
                sales++;
            }
        }
        
        return (itemCount, active, sales);
    }

    /**
     * @dev Emergency withdrawal function (owner only)
     * @dev Only for stuck funds, should not be used in normal operations
     */
    function emergencyWithdraw() external onlyOwner {
        require(paused(), "Contract must be paused");
        
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = owner().call{value: balance}("");
        require(success, "Emergency withdrawal failed");
    }

    /**
     * @dev Check if contract supports interface
     * @param interfaceId Interface identifier
     * @return True if interface is supported
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC721).interfaceId;
    }

    /**
     * @dev Fallback function to reject direct ether transfers
     */
    receive() external payable {
        revert("Direct payments not accepted");
    }

    /**
     * @dev Fallback function
     */
    fallback() external {
        revert("Function not found");
    }
}