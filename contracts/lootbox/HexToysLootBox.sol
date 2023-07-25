// Multiple Fixed HexToysLootBox contract
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IHexToysMysteryBoxFactory {
    function serviceFee() external view returns (uint256);
}

contract HexToysLootBox is ERC1155Holder, ERC721Holder {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /**
        Card Struct
     */
    struct Card {
        uint256 cardType; // 0: ERC721, 1: ERC1155
        bytes32 key; // card key which was generated with collection and tokenId
        address collectionId; // collection address
        uint256 tokenId; // token id of collection
        uint256 amount; // added nft token balances
    }

    address public immutable factory;
    address public owner;

    address public tokenAddress;
    uint256 public price;
    uint256 public constant PERCENTS_DIVIDER = 1000;

    string public boxName;
    string public boxUri;

    bool public status = true;

    // This is a set which contains cardKey
    mapping(bytes32 => Card) public _cards;
    EnumerableSet.Bytes32Set private _cardIndices;

    // The amount of cards in this mysterybox.
    uint256 public cardAmount;

    event AddToken(
        uint256 cardType,
        bytes32 key,
        address collectionId,
        uint256 tokenId,
        uint256 amount,
        uint256 _cardAmount
    );
    event SpinResult(address player, bytes32 key, uint256 _cardAmount);
    event RemoveCard(bytes32 key, uint256 removeAmount, uint256 _cardAmount);
    event EmergencyWithdrawAllCards(bytes32[] keys, uint256 _cardAmount);

    event PriceChanged(uint256 newPrice);
    event PaymentTokenChanged(address newTokenAddress);
    event HexToysMysteryBoxStatus(bool boxStatus);
    event OwnerShipChanged(address newAccount);
    event HexToysMysteryBoxNameChanged(string newName);
    event HexToysMysteryBoxUriChanged(string newUri);

    constructor() {
        factory = msg.sender;
    }

    function initialize(
        string memory _name,
        string memory _uri,
        address _tokenAddress,
        uint256 _price,
        address _owner
    ) public onlyFactory {
        boxName = _name;
        boxUri = _uri;
        tokenAddress = _tokenAddress;
        price = _price;
        owner = _owner;
    }

    // ***************************
    // For Change Parameters ***********
    // ***************************
    function changePrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
        emit PriceChanged(newPrice);
    }

    function changePaymentToken(address _newTokenAddress) external onlyOwner {
        tokenAddress = _newTokenAddress;
        emit PaymentTokenChanged(_newTokenAddress);
    }

    function enableThisHexToysMysteryBox() public onlyOwner {
        status = true;
        emit HexToysMysteryBoxStatus(status);
    }

    function disableThisHexToysMysteryBox() public onlyOwner {
        status = false;
        emit HexToysMysteryBoxStatus(status);
    }

    function transferOwner(address account) public onlyOwner {
        require(account != address(0), "Ownable: new owner is zero address");
        owner = account;
        emit OwnerShipChanged(account);
    }

    function removeOwnership() public onlyOwner {
        owner = address(0x0);
        emit OwnerShipChanged(owner);
    }

    function changeHexToysMysteryBoxName(string memory name) public onlyOwner {
        boxName = name;
        emit HexToysMysteryBoxNameChanged(name);
    }

    function changeHexToysMysteryBoxUri(string memory _uri) public onlyOwner {
        boxUri = _uri;
        emit HexToysMysteryBoxUriChanged(_uri);
    }

    // ***************************
    // For Main function ***********
    // ***************************

    function addToken(
        uint256 cardType,
        address collection,
        uint256 tokenId,
        uint256 amount
    ) public onlyOwner {
        require((cardType == 0 || cardType == 1), "Invalid card type");

        if (cardType == 0) {
            require(
                IERC721(collection).ownerOf(tokenId) == msg.sender,
                "You are not token owner"
            );
            IERC721(collection).safeTransferFrom(
                msg.sender,
                address(this),
                tokenId
            );
        } else {
            require(
                IERC1155(collection).balanceOf(msg.sender, tokenId) >= amount,
                "You don't have enough Tokens"
            );
            IERC1155(collection).safeTransferFrom(
                msg.sender,
                address(this),
                tokenId,
                amount,
                "Add Card"
            );
        }

        bytes32 key = itemKeyFromId(collection, tokenId);
        if (_cards[key].amount == 0) {
            _cardIndices.add(key);
        }
        _cards[key].cardType = cardType;
        _cards[key].key = key;
        _cards[key].collectionId = collection;
        _cards[key].tokenId = tokenId;
        _cards[key].amount = _cards[key].amount.add(amount);

        cardAmount = cardAmount.add(amount);
        emit AddToken(cardType, key, collection, tokenId, amount, cardAmount);
    }

    function addTokenBatch(
        uint256[] memory cardTypes,
        address[] memory collections,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) public onlyOwner {
        uint256 countToAdd = tokenIds.length;
        for (uint256 i = 0; i < countToAdd; i++) {
            require(
                cardTypes[i] == 0 || cardTypes[i] == 1,
                "invalid cardType"
            );
            if (cardTypes[i] == 0) {
                IERC721(collections[i]).safeTransferFrom(
                    msg.sender,
                    address(this),
                    tokenIds[i]
                );
            } else {
                IERC1155(collections[i]).safeTransferFrom(
                    msg.sender,
                    address(this),
                    tokenIds[i],
                    amounts[i],
                    "Add Card"
                );
            }

            bytes32 key = itemKeyFromId(collections[i], tokenIds[i]);
            if (_cards[key].amount == 0) {
                _cardIndices.add(key);
            }
            _cards[key].cardType = cardTypes[i];
            _cards[key].key = key;
            _cards[key].collectionId = collections[i];
            _cards[key].tokenId = tokenIds[i];
            _cards[key].amount = _cards[key].amount.add(amounts[i]);

            cardAmount = cardAmount.add(amounts[i]);
            emit AddToken(
                cardTypes[i],
                key,
                collections[i],
                tokenIds[i],
                amounts[i],
                cardAmount
            );
        }
    }

    function spin() external payable {
        require(status, "This mysterybox is disabled.");
        require(cardAmount > 0, "There is no card in this mysterybox anymore.");

        uint256 fee = IHexToysMysteryBoxFactory(factory).serviceFee();
        uint256 feeAmount = price.mul(fee).div(PERCENTS_DIVIDER);
        uint256 ownerAmount = price.sub(feeAmount);
        if (tokenAddress == address(0x0)) {
            require(msg.value >= price, "too small amount");

            if (feeAmount > 0) {
                (bool result, ) = payable(factory).call{value: feeAmount}("");
                require(
                    result,
                    "Failed to send service fee to factory address"
                );
            }
            (bool result1, ) = payable(owner).call{value: ownerAmount}("");
            require(result1, "Failed to send coin to mysterybox owner");
        } else {
            IERC20 governanceToken = IERC20(tokenAddress);

            require(
                governanceToken.transferFrom(msg.sender, address(this), price),
                "insufficient token balance"
            );
            // transfer governance token to factory
            if (feeAmount > 0) {
                require(governanceToken.transfer(factory, feeAmount));
            }
            // transfer governance token to owner
            require(governanceToken.transfer(owner, ownerAmount));
        }

        bytes32 cardKey = getCardKeyRandmly();

        cardAmount = cardAmount.sub(1);

        require(
            _cards[cardKey].amount > 0,
            "No enough cards of this kind in the mysterybox."
        );
        if (_cards[cardKey].cardType == 0) {
            // ERC721
            IERC721(_cards[cardKey].collectionId).safeTransferFrom(
                address(this),
                msg.sender,
                _cards[cardKey].tokenId
            );
        } else {
            // ERC1155
            IERC1155(_cards[cardKey].collectionId).safeTransferFrom(
                address(this),
                msg.sender,
                _cards[cardKey].tokenId,
                1,
                "Your prize from Pixelpimp HexToysLootBox"
            );
        }
        _cards[cardKey].amount = _cards[cardKey].amount.sub(1);
        if (_cards[cardKey].amount == 0) {
            _cardIndices.remove(cardKey);
        }
        emit SpinResult(msg.sender, cardKey, cardAmount);
    }

    // ***************************
    // view card information ***********
    // ***************************

    function cardKeyCount() public view returns (uint256) {
        return _cardIndices.length();
    }

    function cardKeyWithIndex(uint256 index) public view returns (bytes32) {
        return _cardIndices.at(index);
    }

    // ***************************
    // emergency call information ***********
    // ***************************

    function emergencyWithdrawCard(
        address collectionId,
        uint256 tokenId,
        uint256 amount
    ) public onlyOwner {
        bytes32 cardKey = itemKeyFromId(collectionId, tokenId);
        Card memory card = _cards[cardKey];
        require(
            card.tokenId != 0 && card.collectionId != address(0x0),
            "Invalid Collection id and token id"
        );
        require(card.amount >= amount, "Insufficient balance");
        require(amount > 0, "Insufficient amount");
        if (card.cardType == 0) {
            // withdraw single card
            IERC721(card.collectionId).safeTransferFrom(
                address(this),
                msg.sender,
                card.tokenId
            );
        } else {
            // withdraw multiple card
            IERC1155(card.collectionId).safeTransferFrom(
                address(this),
                msg.sender,
                card.tokenId,
                amount,
                "Reset HexToysLootBox"
            );
        }
        cardAmount = cardAmount.sub(amount);
        _cards[cardKey].amount = _cards[cardKey].amount.sub(amount);
        if (_cards[cardKey].amount == 0) {
            _cardIndices.remove(cardKey);
        }
        emit RemoveCard(cardKey, amount, cardAmount);
    }

    function emergencyWithdrawAllCards() public onlyOwner {
        bytes32[] memory keys = new bytes32[](cardKeyCount());
        for (uint256 i = 0; i < cardKeyCount(); i++) {
            bytes32 key = cardKeyWithIndex(i);
            keys[i] = key;
            if (_cards[key].amount > 0) {
                Card memory card = _cards[key];
                if (card.cardType == 0) {
                    // withdraw single card
                    IERC721(card.collectionId).safeTransferFrom(
                        address(this),
                        msg.sender,
                        card.tokenId
                    );
                } else {
                    // withdraw multiple card
                    IERC1155(card.collectionId).safeTransferFrom(
                        address(this),
                        msg.sender,
                        card.tokenId,
                        card.amount,
                        "Reset HexToysLootBox"
                    );
                }
                cardAmount = cardAmount.sub(_cards[key].amount);
                _cards[key].amount = 0;
                _cardIndices.remove(key);
            }
        }
        emit EmergencyWithdrawAllCards(keys, cardAmount);
    }

    // ***************************
    // general function ***********
    // ***************************
    function getCardKeyRandmly() private view returns (bytes32) {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encode(block.timestamp, block.difficulty, block.number)
            )
        ).mod(cardAmount);
        uint256 amountSum = 0;
        bytes32 resultKey = cardKeyWithIndex(0);
        for (uint i = 0; i < cardKeyCount(); i++) {
            amountSum = amountSum.add(_cards[cardKeyWithIndex(i)].amount);
            if (amountSum > randomNumber) {
                resultKey = cardKeyWithIndex(i);
                break;
            }
        }
        return resultKey;
    }

    function itemKeyFromId(
        address _collection,
        uint256 _token_id
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(_collection, _token_id));
    }

    modifier onlyFactory() {
        require(address(msg.sender) == factory, "Only for factory.");
        _;
    }

    modifier onlyOwner() {
        require(address(msg.sender) == owner, "Only for owner.");
        _;
    }

    function withdrawCoin() public onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "insufficient balance");
        (bool result, ) = payable(msg.sender).call{value: balance}("");
        require(result, "Failed to withdraw");
    }

    /**
     * @dev To receive ETH
     */
    receive() external payable {}
}
