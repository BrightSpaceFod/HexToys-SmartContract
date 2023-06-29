// Multiple Fixed Price Marketplace contract
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../signature/Signature.sol";

interface IMultipleNFT {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    function isApprovedForAll(address account, address operator) external view returns (bool);
}

contract HexToysMultipleFixed is
    OwnableUpgradeable,
    ERC1155HolderUpgradeable,
    Signature
{
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public constant PERCENTS_DIVIDER = 1000;
    uint256 public swapFee;
    address public feeAddress;
    address public signerAddress;

    /* Pairs to swap NFT _id => price */
    struct Pair {
        uint256 pairId;
        address collection;
        uint256 tokenId;
        address owner;
        address tokenAdr;
        uint256 balance;
        uint256 price;
        bool bValid;
    }

    mapping(uint256 => Pair) public pairs;
    uint256 public currentPairId;

    /** Events */
    event MultiItemListed(Pair item);
    event MultiItemDelisted(
        address collection,
        uint256 tokenId,
        uint256 pairId
    );
    event MultiItemSwapped(
        address buyer,
        uint256 id,
        uint256 amount,
        Pair item
    );

    function initialize(
        address _feeAddress,
        address _signerAddress
    ) public initializer {
        __Ownable_init();
        require(_feeAddress != address(0), "Invalid commonOwner");
        feeAddress = _feeAddress;
        signerAddress = _signerAddress;
        swapFee = 21; // 21%
        currentPairId = 0;
    }

    function setSignerAddress(address _signerAddress) external onlyOwner {
        require(_signerAddress != address(0x0), "invalid address");
        signerAddress = _signerAddress;
    }

    function setFeePercent(uint256 _swapFee) external onlyOwner {
        require(_swapFee < 100, "invalid percent");
        swapFee = _swapFee;
    }

    function setFeeAddress(address _address) external onlyOwner {
        require(_address != address(0x0), "invalid address");
        feeAddress = _address;
    }

    function multipleList(
        address _collection,
        uint256 _tokenId,
        address _tokenAdr,
        uint256 _amount,
        uint256 _price
    ) public {
        require(_price > 0, "invalid price");
        require(_amount > 0, "invalid amount");

        IMultipleNFT nft = IMultipleNFT(_collection);
        require(
            nft.isApprovedForAll(
                _msgSender(),
                address(this)
            ),
            "Not approve nft to staker address"
        );

        uint256 nft_token_balance = nft.balanceOf(msg.sender, _tokenId);
        require(
            nft_token_balance >= _amount,
            "invalid amount : amount have to be smaller than NFT balance"
        );

        currentPairId = currentPairId.add(2);
        pairs[currentPairId].pairId = currentPairId;
        pairs[currentPairId].collection = _collection;
        pairs[currentPairId].tokenId = _tokenId;
        pairs[currentPairId].owner = msg.sender;
        pairs[currentPairId].tokenAdr = _tokenAdr;
        pairs[currentPairId].balance = _amount;
        pairs[currentPairId].price = _price;
        pairs[currentPairId].bValid = true;

        emit MultiItemListed(pairs[currentPairId]);
    }

    function multipleDelist(uint256 _id) external {
        require(pairs[_id].bValid, "invalid Pair id");
        require(
            pairs[_id].owner == msg.sender || msg.sender == owner(),
            "only owner can delist"
        );

        pairs[_id].balance = 0;
        pairs[_id].bValid = false;

        emit MultiItemDelisted(pairs[_id].collection, pairs[_id].tokenId, _id);
    }

    function multipleBuy(
        uint256 _id,
        uint256 _amount,
        bytes calldata _signature,
        uint256 _royalty,
        address _royaltyReceiver
    ) external payable {
        require(pairs[_id].bValid, "invalid Pair id");
        require(pairs[_id].balance >= _amount, "insufficient NFT balance");
        
        uint256 nft_token_balance = IMultipleNFT(pairs[_id].collection).balanceOf(pairs[_id].owner, pairs[_id].tokenId);
        require(
            nft_token_balance >= _amount,
            "invalid amount : amount have to be smaller than NFT balance"
        );

        confirmSignature(
            address(this),
            msg.sender,
            pairs[_id].collection,
            pairs[_id].tokenId,
            _royalty,
            _royaltyReceiver,
            "multipleBuy",
            _signature,
            signerAddress
        );

        Pair memory item = pairs[_id];
        {
            uint256 tokenAmount = item.price.mul(_amount);
            uint256 feeAmount = tokenAmount.mul(swapFee).div(PERCENTS_DIVIDER);
            uint256 royaltyAmount = tokenAmount.mul(_royalty).div(
                PERCENTS_DIVIDER
            );
            uint256 ownerAmount = tokenAmount.sub(feeAmount).sub(royaltyAmount);

            if (pairs[_id].tokenAdr == address(0x0)) {
                require(msg.value >= tokenAmount, "too small amount");

                if (swapFee > 0) {
                    (bool result, ) = payable(feeAddress).call{
                        value: feeAmount
                    }("");
                    require(result, "Failed to send fee to feeAddress");
                }
                if (royaltyAmount > 0) {
                    (bool result, ) = payable(_royaltyReceiver).call{
                        value: royaltyAmount
                    }("");
                    require(result, "Failed to send royalty");
                }
                (bool result1, ) = payable(item.owner).call{value: ownerAmount}(
                    ""
                );
                require(result1, "Failed to send coin to nft owner");
            } else {
                IERC20 governanceToken = IERC20(pairs[_id].tokenAdr);

                require(
                    governanceToken.transferFrom(
                        msg.sender,
                        address(this),
                        tokenAmount
                    ),
                    "insufficient token balance"
                );
                // transfer governance token to admin
                if (swapFee > 0) {
                    require(governanceToken.transfer(feeAddress, feeAmount));
                }
                if (royaltyAmount > 0) {
                    require(
                        governanceToken.transfer(
                            _royaltyReceiver,
                            royaltyAmount
                        )
                    );
                }

                // transfer governance token to owner
                require(governanceToken.transfer(item.owner, ownerAmount));
            }
        }

        // transfer NFT token to buyer
        IMultipleNFT(pairs[_id].collection).safeTransferFrom(
            item.owner,
            msg.sender,
            item.tokenId,
            _amount,
            "buy from Marketplace"
        );
        if (pairs[_id].balance > nft_token_balance) {
            pairs[_id].balance = nft_token_balance.sub(_amount);
        } else {
            pairs[_id].balance = pairs[_id].balance.sub(_amount);
        }

        
        if (pairs[_id].balance == 0) {
            pairs[_id].bValid = false;
        }
        emit MultiItemSwapped(msg.sender, _id, _amount, pairs[_id]);
    }
}
