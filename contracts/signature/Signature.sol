// InvestNFT token
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract Signature {
    using Strings for uint256;

    error InvalidSignature();
    error InvalidSignatureLength();

    function confirmSignature(
        address collection,
        uint256 tokenId,
        uint256 productId,
        uint256 amount,
        uint256 price,
        address tokenAddr,
        address buyer,
        address seller,
        uint256 nonce,
        uint256[] memory _royaltyArray,
        address[] memory _receiverArray,
        bytes memory signature_,
        address signer
    ) internal pure {
        // combine royalty array as string        

        bytes32 hashMessage = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(
                        collection,
                        tokenId,
                        productId,
                        amount,
                        price,
                        tokenAddr,
                        buyer,
                        seller,
                        nonce,
                        _royaltyArray,
                        _receiverArray
                    )
                )
            )
        );
        if (recoverSigner(hashMessage, signature_) != signer)
            revert InvalidSignature();
    }

    function recoverSigner(
        bytes32 ethSignedMessageHash_,
        bytes memory signature_
    ) private pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature_);
        return ecrecover(ethSignedMessageHash_, v, r, s);
    }

    function splitSignature(
        bytes memory sig_
    ) private pure returns (bytes32 r, bytes32 s, uint8 v) {
        if (sig_.length != 65) revert InvalidSignatureLength();

        assembly {
            r := mload(add(sig_, 32))
            s := mload(add(sig_, 64))
            v := byte(0, mload(add(sig_, 96)))
        }
    }
}
