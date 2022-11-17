// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract Custom is ERC1155Supply {
    struct Sale {
        address seller;
        uint128 price;
        uint256 startedAt;
    }

    uint256 public totalMinted;
    mapping(uint256 => string) tokenURIs;
    mapping(uint256 => uint256) fractionPrices;
    mapping(uint256 => uint256) maxSupplys;
    mapping(uint256 => address) creators;
    mapping(uint256 => Sale[]) tokenIdToSales;
    mapping(address => mapping(uint256 => uint256)) saleAmountBySeller;
    mapping(address => uint256[]) saleTokenIdsBySeller;

    event CreateNFT(
        uint256 tokenId,
        string tokenURI,
        uint256 airdropAmount,
        uint256 maxSupply,
        uint256 fractionPrice,
        address creator
    );
    event Minted(uint256 tokenId, uint256 amount, address minter);

    constructor() ERC1155("") {}

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

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
        require(exists(tokenId) == true, "The Token does not exist");
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

    function _escrow(address _owner, uint256 _tokenId) internal {
        transferFrom(_owner, address(this), _tokenId);
    }

    function _transfer(address _receiver, uint256 _tokenId) internal {
        transferFrom(address(this), _receiver, _tokenId);
    }

    function createSale(uint256 tokenId, uint256 amount, uint256 price) external {
        require(balanceOf(msg.sender, tokenId) >= amount, "Insufficient token to create sale");
        
    }
}
