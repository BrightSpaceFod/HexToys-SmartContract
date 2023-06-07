// Single Fixed Price Marketplace contract
// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISingleNFT {
	function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);   
}

contract SingleFixed is Ownable, ERC721Holder {
    using SafeMath for uint256;
	using EnumerableSet for EnumerableSet.AddressSet;

	uint256 constant public PERCENTS_DIVIDER = 1000;

	uint256 public swapFee = 21; // 2.1%	
	address public feeAddress; 
	
    /* Pairs to swap NFT _id => price */
	struct Pair {
		uint256 pairId;
		address collection;
		uint256 tokenId;
		address owner;
		address tokenAdr;
		uint256 price;
        bool bValid;		
	}

	// token id => Pair mapping
    mapping(uint256 => Pair) public pairs;
	uint256 public currentPairId = 1;    
	
	/** Events */
    event SingleItemListed(Pair pair);
	event SingleItemDelisted(address collection, uint256 tokenId, uint256 pairId);
    event SingleSwapped(address buyer, Pair pair);

	constructor (address _feeAddress) {	
		feeAddress = _feeAddress;
	}
	
	function setFeePercent(uint256 _swapFee) external onlyOwner {		
		require(_swapFee < 100 , "invalid percent");
        swapFee = _swapFee;
    }
	function setFeeAddress(address _feeAddress) external onlyOwner {
		require(_feeAddress != address(0x0), "invalid address");		
        feeAddress = _feeAddress;		
    }	

    function singleList(address _collection, uint256 _tokenId, address _tokenAdr, uint256 _price) OnlyItemOwner(_collection,_tokenId) public {
		require(_price > 0, "invalid price");	
		ISingleNFT nft = ISingleNFT(_collection);        
        nft.safeTransferFrom(msg.sender, address(this), _tokenId);

		currentPairId = currentPairId.add(2);
		pairs[currentPairId].pairId = currentPairId;
		pairs[currentPairId].collection = _collection;
		pairs[currentPairId].tokenId = _tokenId;		
        pairs[currentPairId].owner = msg.sender;
		pairs[currentPairId].tokenAdr = _tokenAdr;		
		pairs[currentPairId].price = _price;
		pairs[currentPairId].bValid = true;	

        emit SingleItemListed(pairs[currentPairId]);
    }

    function singleDelist(uint256 _id) external {        
        require(pairs[_id].bValid, "not exist");
        require(msg.sender == pairs[_id].owner || msg.sender == owner(), "Error, you are not the owner");        
        ISingleNFT(pairs[_id].collection).safeTransferFrom(address(this), pairs[_id].owner, pairs[_id].tokenId);        
        pairs[_id].bValid = false;
        emit SingleItemDelisted(pairs[_id].collection, pairs[_id].tokenId, _id);        
    }


    function singleBuy(uint256 _id) external payable {
		require(_id <= currentPairId && pairs[_id].pairId == _id, "Could not find item");
        require(pairs[_id].bValid, "invalid Pair id");
		require(pairs[_id].owner != msg.sender, "owner can not buy");

		Pair memory pair = pairs[_id];
		uint256 totalAmount = pair.price;
		uint256 feeAmount = totalAmount.mul(swapFee).div(PERCENTS_DIVIDER);		
		uint256 ownerAmount = totalAmount.sub(feeAmount);

		if (pairs[_id].tokenAdr == address(0x0)) {
            require(msg.value >= totalAmount, "too small amount");

			if(swapFee > 0) {
				(bool result, ) = payable(feeAddress).call{value: feeAmount}("");
        		require(result, "Failed to send fee to feeAddress");				
			}
			(bool result1, ) = payable(pair.owner).call{value: ownerAmount}("");
        	require(result1, "Failed to send coin to pair owner");			

        } else {
            IERC20 governanceToken = IERC20(pairs[_id].tokenAdr);

			require(governanceToken.transferFrom(msg.sender, address(this), totalAmount), "insufficient token balance");
		
			if(swapFee > 0) {
				// transfer governance token to feeAddress
				require(governanceToken.transfer(feeAddress, feeAmount));				
			}
			
			// transfer governance token to owner
			require(governanceToken.transfer(pair.owner, ownerAmount));			
		
        }
		
		// transfer NFT token to buyer
		ISingleNFT(pairs[_id].collection).safeTransferFrom(address(this), msg.sender, pair.tokenId);
		
		pairs[_id].bValid = false;		

        emit SingleSwapped(msg.sender, pair);		
    }

	modifier OnlyItemOwner(address tokenAddress, uint256 tokenId){
        ISingleNFT tokenContract = ISingleNFT(tokenAddress);
        require(tokenContract.ownerOf(tokenId) == msg.sender);
        _;
    }

    modifier ItemExists(uint256 id){
        require(id <= currentPairId && pairs[id].pairId == id, "Could not find item");
        _;
    }

}