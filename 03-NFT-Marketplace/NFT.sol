// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title NFT Contract
 * @dev ERC721 NFT contract with URI storage, minting controls, and security features
 * @author Smart Contract Developer
 */
contract NFT is ERC721URIStorage, Pausable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    
    // State variables
    Counters.Counter private _tokenIdCounter;
    uint256 public maxSupply;
    uint256 public mintPrice;
    bool public publicMintEnabled;
    
    // Mappings
    mapping(address => bool) public authorizedMinters;
    mapping(address => uint256) public mintedByAddress;
    mapping(uint256 => string) public tokenDescriptions;
    
    // Constants
    uint256 public constant MAX_MINT_PER_ADDRESS = 10;
    
    // Events
    event TokenMinted(
        uint256 indexed tokenId,
        address indexed to,
        string tokenURI,
        uint256 timestamp
    );
    
    event TokenBurned(
        uint256 indexed tokenId,
        address indexed owner,
        uint256 timestamp
    );
    
    event MintPriceUpdated(
        uint256 oldPrice,
        uint256 newPrice,
        uint256 timestamp
    );
    
    event MaxSupplyUpdated(
        uint256 oldSupply,
        uint256 newSupply,
        uint256 timestamp
    );
    
    event PublicMintToggled(
        bool enabled,
        uint256 timestamp
    );
    
    event MinterAuthorized(
        address indexed minter,
        bool authorized,
        uint256 timestamp
    );
    
    event TokenDescriptionUpdated(
        uint256 indexed tokenId,
        string description,
        uint256 timestamp
    );
    
    /**
     * @dev Constructor sets the NFT name, symbol, and initial parameters
     * @param _name NFT collection name
     * @param _symbol NFT collection symbol
     * @param _maxSupply Maximum number of tokens that can be minted
     * @param _mintPrice Price to mint each token (in wei)
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _mintPrice
    ) ERC721(_name, _symbol) Ownable(msg.sender) {
        require(_maxSupply > 0, "Max supply must be greater than 0");
        
        maxSupply = _maxSupply;
        mintPrice = _mintPrice;
        publicMintEnabled = false;
        
        // Start token IDs at 1
        _tokenIdCounter.increment();
        
        emit MaxSupplyUpdated(0, _maxSupply, block.timestamp);
        emit MintPriceUpdated(0, _mintPrice, block.timestamp);
    }
    
    /**
     * @dev Mint a new NFT with metadata URI
     * @param _to Address to mint the NFT to
     * @param _tokenURI Metadata URI for the NFT
     * @param _description Optional description for the NFT
     * @return tokenId The ID of the newly minted token
     */
    function mint(
        address _to,
        string memory _tokenURI,
        string memory _description
    ) external payable nonReentrant whenNotPaused returns (uint256) {
        require(_to != address(0), "Cannot mint to zero address");
        require(bytes(_tokenURI).length > 0, "Token URI cannot be empty");
        require(_tokenIdCounter.current() <= maxSupply, "Max supply reached");
        
        // Check authorization and payment
        if (!authorizedMinters[msg.sender] && msg.sender != owner()) {
            require(publicMintEnabled, "Public minting is disabled");
            require(msg.value >= mintPrice, "Insufficient payment");
            require(mintedByAddress[_to] < MAX_MINT_PER_ADDRESS, "Max mint limit reached");
        }
        
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        
        if (bytes(_description).length > 0) {
            tokenDescriptions[tokenId] = _description;
        }
        
        mintedByAddress[_to]++;
        
        // Refund excess payment
        if (msg.value > mintPrice && !authorizedMinters[msg.sender] && msg.sender != owner()) {
            uint256 refund = msg.value - mintPrice;
            (bool success, ) = payable(msg.sender).call{value: refund}("");
            require(success, "Refund failed");
        }
        
        emit TokenMinted(tokenId, _to, _tokenURI, block.timestamp);
        
        return tokenId;
    }
    
    /**
     * @dev Simplified mint function for backward compatibility
     * @param _tokenURI Metadata URI for the NFT
     * @return tokenId The ID of the newly minted token
     */
    function mint(string memory _tokenURI) external payable returns (uint256) {
        return mint(msg.sender, _tokenURI, "");
    }
    
    /**
     * @dev Batch mint multiple NFTs
     * @param _to Address to mint the NFTs to
     * @param _tokenURIs Array of metadata URIs
     * @param _descriptions Array of descriptions (can be empty)
     * @return tokenIds Array of newly minted token IDs
     */
    function batchMint(
        address _to,
        string[] memory _tokenURIs,
        string[] memory _descriptions
    ) external payable nonReentrant whenNotPaused onlyOwner returns (uint256[] memory) {
        require(_to != address(0), "Cannot mint to zero address");
        require(_tokenURIs.length > 0, "Must mint at least one token");
        require(_tokenURIs.length <= 20, "Cannot mint more than 20 tokens at once");
        require(_tokenIdCounter.current() + _tokenURIs.length - 1 <= maxSupply, "Would exceed max supply");
        
        if (_descriptions.length > 0) {
            require(_descriptions.length == _tokenURIs.length, "Descriptions array length mismatch");
        }
        
        uint256[] memory tokenIds = new uint256[](_tokenURIs.length);
        
        for (uint256 i = 0; i < _tokenURIs.length; i++) {
            require(bytes(_tokenURIs[i]).length > 0, "Token URI cannot be empty");
            
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            
            _safeMint(_to, tokenId);
            _setTokenURI(tokenId, _tokenURIs[i]);
            
            if (_descriptions.length > 0 && bytes(_descriptions[i]).length > 0) {
                tokenDescriptions[tokenId] = _descriptions[i];
            }
            
            tokenIds[i] = tokenId;
            
            emit TokenMinted(tokenId, _to, _tokenURIs[i], block.timestamp);
        }
        
        mintedByAddress[_to] += _tokenURIs.length;
        
        return tokenIds;
    }
    
    /**
     * @dev Burn a token (owner or approved only)
     * @param _tokenId Token ID to burn
     */
    function burn(uint256 _tokenId) external {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not authorized to burn this token");
        
        address owner = ownerOf(_tokenId);
        
        // Clear token description
        delete tokenDescriptions[_tokenId];
        
        _burn(_tokenId);
        
        emit TokenBurned(_tokenId, owner, block.timestamp);
    }
    
    /**
     * @dev Update token description (owner only)
     * @param _tokenId Token ID
     * @param _description New description
     */
    function updateTokenDescription(uint256 _tokenId, string memory _description) external {
        require(_exists(_tokenId), "Token does not exist");
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not authorized");
        
        tokenDescriptions[_tokenId] = _description;
        
        emit TokenDescriptionUpdated(_tokenId, _description, block.timestamp);
    }
    
    /**
     * @dev Set mint price (owner only)
     * @param _newPrice New mint price in wei
     */
    function setMintPrice(uint256 _newPrice) external onlyOwner {
        uint256 oldPrice = mintPrice;
        mintPrice = _newPrice;
        
        emit MintPriceUpdated(oldPrice, _newPrice, block.timestamp);
    }
    
    /**
     * @dev Update max supply (owner only, can only decrease)
     * @param _newMaxSupply New maximum supply
     */
    function updateMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        require(_newMaxSupply >= _tokenIdCounter.current() - 1, "Cannot set max supply below current supply");
        require(_newMaxSupply < maxSupply, "Can only decrease max supply");
        
        uint256 oldSupply = maxSupply;
        maxSupply = _newMaxSupply;
        
        emit MaxSupplyUpdated(oldSupply, _newMaxSupply, block.timestamp);
    }
    
    /**
     * @dev Toggle public minting (owner only)
     * @param _enabled Whether public minting is enabled
     */
    function setPublicMintEnabled(bool _enabled) external onlyOwner {
        publicMintEnabled = _enabled;
        
        emit PublicMintToggled(_enabled, block.timestamp);
    }
    
    /**
     * @dev Authorize or deauthorize minters (owner only)
     * @param _minter Minter address
     * @param _authorized Authorization status
     */
    function setMinterAuthorization(address _minter, bool _authorized) external onlyOwner {
        require(_minter != address(0), "Invalid minter address");
        
        authorizedMinters[_minter] = _authorized;
        
        emit MinterAuthorized(_minter, _authorized, block.timestamp);
    }
    
    /**
     * @dev Pause the contract (owner only)
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause the contract (owner only)
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev Withdraw contract balance (owner only)
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }
    
    /**
     * @dev Get current token count
     * @return Current number of minted tokens
     */
    function tokenCount() external view returns (uint256) {
        return _tokenIdCounter.current() - 1;
    }
    
    /**
     * @dev Get total supply
     * @return Total number of tokens minted
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current() - 1;
    }
    
    /**
     * @dev Get token description
     * @param _tokenId Token ID
     * @return Token description
     */
    function getTokenDescription(uint256 _tokenId) external view returns (string memory) {
        require(_exists(_tokenId), "Token does not exist");
        return tokenDescriptions[_tokenId];
    }
    
    /**
     * @dev Get contract information
     * @return name_ Contract name
     * @return symbol_ Contract symbol
     * @return totalSupply_ Total supply
     * @return maxSupply_ Maximum supply
     * @return mintPrice_ Current mint price
     * @return publicMintEnabled_ Public mint status
     */
    function getContractInfo() external view returns (
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint256 maxSupply_,
        uint256 mintPrice_,
        bool publicMintEnabled_
    ) {
        return (
            name(),
            symbol(),
            _tokenIdCounter.current() - 1,
            maxSupply,
            mintPrice,
            publicMintEnabled
        );
    }
    
    /**
     * @dev Override _beforeTokenTransfer to include pause functionality
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
    
    /**
     * @dev Override supportsInterface
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}