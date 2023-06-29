// HexToys Auction Contract
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../signature/Signature.sol";

interface IHexToysSingleNFT {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function isApprovedForAll( address owner, address operator) external view returns (bool);
}

contract HexToysSingleAuction is OwnableUpgradeable, ERC721HolderUpgradeable, Signature {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public constant PERCENTS_DIVIDER = 1000;
    uint256 public constant MIN_BID_INCREMENT_PERCENT = 10; // 1%
    uint256 public swapFee;
    address public feeAddress;
    address public signerAddress;

    // AuctionBid struct to hold bidder and amount
    struct AuctionBid {
        address from;
        uint256 bidPrice;
    }

    // Auction struct which holds all the required info
    struct Auction {
        uint256 auctionId;
        address collectionId;
        uint256 tokenId;
        uint256 startTime;
        uint256 endTime;
        address tokenAdr;
        uint256 startPrice;
        address owner;
        bool active;
    }

    // Array with all auctions
    Auction[] public auctions;

    // Mapping from auction index to user bids
    mapping(uint256 => AuctionBid[]) public auctionBids;

    // Mapping from owner to a list of owned auctions
    mapping(address => uint256[]) public ownedAuctions;

    event AuctionBidSuccess( address _from, Auction auction, uint256 price, uint256 _bidIndex );

    // AuctionCreated is fired when an auction is created
    event AuctionCreated(Auction auction);

    // AuctionCanceled is fired when an auction is canceled
    event AuctionCanceled(Auction auction);

    // AuctionFinalized is fired when an auction is finalized
    event AuctionFinalized(address buyer, uint256 price, Auction auction);

    function initialize( address _feeAddress, address _signerAddress ) public initializer {
        __Ownable_init();
        require(_feeAddress != address(0), "Invalid commonOwner");
        feeAddress = _feeAddress;
        signerAddress = _signerAddress;
        swapFee = 21; //2.1%
    }

    function setSignerAddress(address _signerAddress) external onlyOwner {
        require(_signerAddress != address(0x0), "invalid address");
        signerAddress = _signerAddress;
    }

    function setFeeAddress(address _feeAddress) external onlyOwner {
        require(_feeAddress != address(0x0), "invalid address");
        feeAddress = _feeAddress;
    }

    function setFeePercent(uint256 _swapFee) external onlyOwner {
        require(_swapFee < 100, "invalid percent");
        swapFee = _swapFee;
    }

    /*
     * @dev Creates an auction
     */
    function createAuction( address _collectionId, uint256 _tokenId, address _tokenAdr, uint256 _startPrice, uint256 _startTime, uint256 _endTime ) public onlyTokenOwner(_collectionId, _tokenId) {
        require( block.timestamp < _endTime, "end timestamp have to be bigger than current time" );
        require(
            IHexToysSingleNFT(_collectionId).isApprovedForAll( _msgSender(), address(this) ),
            "Not approve nft to singlefixed"
        );

        uint256 auctionId = auctions.length;
        Auction memory newAuction;
        newAuction.auctionId = auctionId;
        newAuction.collectionId = _collectionId;
        newAuction.tokenId = _tokenId;
        newAuction.startPrice = _startPrice;
        newAuction.tokenAdr = _tokenAdr;
        newAuction.startTime = _startTime;
        newAuction.endTime = _endTime;
        newAuction.owner = msg.sender;
        newAuction.active = true;

        auctions.push(newAuction);
        ownedAuctions[msg.sender].push(auctionId);

        emit AuctionCreated(newAuction);
    }

    /**
     * @dev Finalized an ended auction
    */
    function finalizeAuction( uint256 _auctionId, bytes calldata _signature, uint256[] memory _royaltyArray, address[] memory _receiverArray ) public {
        Auction memory myAuction = auctions[_auctionId];
        uint256 bidsLength = auctionBids[_auctionId].length;
        require( msg.sender == myAuction.owner || msg.sender == owner(), "only auction owner can finalize" );

        confirmSignature(
            address(this),
            msg.sender,
            myAuction.collectionId,
            myAuction.tokenId,
            _royaltyArray,
            _receiverArray,
            "finalizeAuction",
            _signature,
            signerAddress
        );

        // if there are no bids cancel
        if (bidsLength == 0) {
            IHexToysSingleNFT(myAuction.collectionId).safeTransferFrom( address(this), myAuction.owner, myAuction.tokenId);
            auctions[_auctionId].active = false;
            emit AuctionCanceled(auctions[_auctionId]);
        } else {
            // 2. the money goes to the auction owner
            AuctionBid memory lastBid = auctionBids[_auctionId][bidsLength - 1];

            // % commission cut
            uint256 _feeValue = lastBid.bidPrice.mul(swapFee).div( PERCENTS_DIVIDER );
            uint256 _sellerValue = lastBid.bidPrice.sub(_feeValue);            

            // transfer token from user to contract
            IERC20 governanceToken = IERC20(myAuction.tokenAdr);
            require(governanceToken.transferFrom(lastBid.from, address(this), lastBid.bidPrice), "insufficient token balance");
            
            // transfer service fee
            if (_feeValue > 0)
                require(governanceToken.transfer(feeAddress, _feeValue));

            // transfer royalties
            uint256 royaltyCount = _royaltyArray.length;
            for (uint256 i = 0; i < royaltyCount; i++) {
                uint256 royaltyAmount = lastBid.bidPrice.mul(_royaltyArray[i]).div(PERCENTS_DIVIDER);                  
                if (royaltyAmount > 0) {
                    governanceToken.transfer(_receiverArray[i], royaltyAmount);
                    _sellerValue = _sellerValue.sub(royaltyAmount);
                }
            }            

            // transfer token to auction owner
            governanceToken.transfer(myAuction.owner, _sellerValue);

            // approve and transfer from this contract to the bid winner
            IHexToysSingleNFT(myAuction.collectionId).safeTransferFrom( myAuction.owner, lastBid.from, myAuction.tokenId );
            auctions[_auctionId].active = false;

            emit AuctionFinalized(lastBid.from, lastBid.bidPrice, myAuction);
        }
    }

    /**
     * @dev Bidder sends bid on an auction
     * @dev Auction should be active and not ended
     * @dev Refund previous bidder if a new bid is valid and placed.
     * @param _auctionId uint256 ID of the created auction
     */
    function bidOnAuction(uint256 _auctionId, uint256 amount) external {
        // owner can't bid on their auctions
        require( _auctionId <= auctions.length && auctions[_auctionId].auctionId == _auctionId, "Could not find item" );
        Auction memory myAuction = auctions[_auctionId];
        require(myAuction.owner != msg.sender, "owner can not bid");
        require(myAuction.active, "not exist");

        // if auction is expired
        require(block.timestamp < myAuction.endTime, "auction is over");
        require( block.timestamp >= myAuction.startTime, "auction is not started" );

        uint256 bidsLength = auctionBids[_auctionId].length;
        uint256 tempAmount = myAuction.startPrice;
        AuctionBid memory lastBid;

        // there are previous bids
        if (bidsLength > 0) {
            lastBid = auctionBids[_auctionId][bidsLength - 1];
            tempAmount = lastBid.bidPrice.mul(PERCENTS_DIVIDER + MIN_BID_INCREMENT_PERCENT).div(PERCENTS_DIVIDER);
        }

        // check if amount is greater than previous amount
        require(amount >= tempAmount, "too small amount");

        IERC20 governanceToken = IERC20(myAuction.tokenAdr);
        require( governanceToken.allowance(msg.sender, address(this)) < amount, "in sufficiant token allowance" );
        
        // insert bid
        AuctionBid memory newBid;
        newBid.from = msg.sender;
        newBid.bidPrice = amount;
        auctionBids[_auctionId].push(newBid);
        emit AuctionBidSuccess( msg.sender, myAuction, newBid.bidPrice, bidsLength );
    }

    modifier AuctionExists(uint256 auctionId) {
        require( auctionId <= auctions.length && auctions[auctionId].auctionId == auctionId, "Could not find item" );
        _;
    }

    /**
     * @dev Gets the length of auctions
     * @return uint256 representing the auction count
     */
    function getAuctionsLength() public view returns (uint) {
        return auctions.length;
    }

    /**
     * @dev Gets the bid counts of a given auction
     * @param _auctionId uint256 ID of the auction
     */
    function getBidsAmount(uint256 _auctionId) public view returns (uint) {
        return auctionBids[_auctionId].length;
    }

    /**
     * @dev Gets an array of owned auctions
     * @param _owner address of the auction owner
     */
    function getOwnedAuctions(
        address _owner
    ) public view returns (uint[] memory) {
        uint[] memory ownedAllAuctions = ownedAuctions[_owner];
        return ownedAllAuctions;
    }

    /**
     * @dev Gets an array of owned auctions
     * @param _auctionId uint256 of the auction owner
     * @return amount uint256, address of last bidder
     */
    function getCurrentBids(
        uint256 _auctionId
    ) public view returns (uint256, address) {
        uint256 bidsLength = auctionBids[_auctionId].length;
        // if there are bids refund the last bid
        if (bidsLength >= 0) {
            AuctionBid memory lastBid = auctionBids[_auctionId][bidsLength - 1];
            return (lastBid.bidPrice, lastBid.from);
        }
        return (0, address(0));
    }

    /**
     * @dev Gets the total number of auctions owned by an address
     * @param _owner address of the owner
     * @return uint256 total number of auctions
     */
    function getAuctionsAmount(address _owner) public view returns (uint) {
        return ownedAuctions[_owner].length;
    }

    modifier onlyAuctionOwner(uint256 _auctionId) {
        require(auctions[_auctionId].owner == msg.sender);
        _;
    }

    modifier onlyTokenOwner(address _collectionId, uint256 _tokenId) {
        address tokenOwner = IHexToysSingleNFT(_collectionId).ownerOf(_tokenId);
        require(tokenOwner == msg.sender);
        _;
    }
}
