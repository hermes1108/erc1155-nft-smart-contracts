// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract Custom is ERC1155Supply {
    struct Sale {
        address seller;
        uint256 amount;
        uint256 price;
        uint256 startedAt;
    }

    uint256 public totalMinted;
    mapping(uint256 => string) tokenURIs;
    mapping(uint256 => uint256) fractionPrices;
    mapping(uint256 => uint256) maxSupplys;
    mapping(uint256 => address) creators;
    mapping(uint256 => Sale[]) tokenIdToSales;
    uint256[] public saleTokenIds;
    mapping(address => uint256[]) private saleTokenIdsBySeller;
    mapping(address => mapping(uint256 => uint256)) private saleAmount;

    event CreateNFT(
        uint256 tokenId,
        string tokenURI,
        uint256 airdropAmount,
        uint256 maxSupply,
        uint256 fractionPrice,
        address creator
    );
    event Minted(uint256 tokenId, uint256 amount, address minter);

    constructor() ERC1155("NFT") {}

    function create(
        string memory tokenURI,
        uint256 airdropAmount,
        uint256 mxSpl,
        uint256 frcPrice
    ) external {
        require(mxSpl > 0, "Max Supply Must be bigger than 0");
        tokenURIs[++totalMinted] = tokenURI;
        fractionPrices[totalMinted] = frcPrice;
        maxSupplys[totalMinted] = mxSpl;
        creators[totalMinted] = msg.sender;
        if (airdropAmount > 0) {
            _mint(msg.sender, totalMinted, airdropAmount, "0x0000");
        }
        emit CreateNFT(
            totalMinted,
            tokenURI,
            airdropAmount,
            mxSpl,
            frcPrice,
            msg.sender
        );
    }

    function mint(uint256 tokenId, uint256 amount) external payable {
        require(tokenId <= totalMinted, "The Token does not exist");
        require(amount > 0, "Minting 0 is not allowed");
        require(
            totalSupply(tokenId) + amount <= maxSupplys[tokenId],
            "Exceeds Max Supply"
        );
        require(
            msg.value >= fractionPrices[tokenId] * amount,
            "Insufficient funds"
        );
        _mint(msg.sender, tokenId, amount, "0x0000");
        payable(creators[tokenId]).transfer(msg.value);
        emit Minted(tokenId, amount, msg.sender);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        require(exists(tokenId) == true, "The Token does not exist");
        return tokenURIs[tokenId];
    }

    function fractionPrice(uint256 tokenId) external view returns (uint256) {
        require(exists(tokenId) == true, "The Token does not exist");
        return fractionPrices[tokenId];
    }

    function maxSupply(uint256 tokenId) external view returns (uint256) {
        require(exists(tokenId) == true, "The Token does not exist");
        return maxSupplys[tokenId];
    }

    function creator(uint256 tokenId) external view returns (address) {
        require(exists(tokenId) == true, "The Token does not exist");
        return creators[tokenId];
    }

    function _escrow(
        address _owner,
        uint256 _tokenId,
        uint256 _amount
    ) internal {
        safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId,
            _amount,
            "0x0000"
        );
    }

    function _transfer(
        address _receiver,
        uint256 _tokenId,
        uint256 _amount
    ) internal {
        safeTransferFrom(
            address(this),
            msg.sender,
            _tokenId,
            _amount,
            "0x0000"
        );
    }

    function createSale(
        uint256 _tokenId,
        uint256 price,
        uint256 amount
    )
        external
        virtual
        exists(contractAddr)
        verified(contractAddr)
        whenNotPaused
        owningToken(contractAddr, _tokenId)
    {
        require(
            balanceOf(msg.sender, _tokenId) >= amount,
            "Insufficient NFT to create sale"
        );
        _escrow(msg.sender, _tokenId, amount);
        Sale memory sale = Sale(msg.sender, price, block.timestamp);
        tokenIdToSales[_tokenId].push(sale);
        _addSale(contractAddr, _tokenId, sale);
    }
}
