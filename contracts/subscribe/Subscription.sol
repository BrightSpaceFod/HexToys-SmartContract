//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./UniversalERC20Upgradeable.sol";

/**
 * @title Subscription based smart contract
 * @notice Pay a monthly subscription in coins or erc20 tokens
 * @author HexToys Inc.
 */

contract Subscription is Ownable {

    using UniversalERC20Upgradeable for IERC20Upgradeable;

    /// @dev Variables to manage the fee for each type of payment
    uint256 public coinFee; // Fee for Coin payments
    uint256 public tokenFee; // Fee for Token payments

    /// @dev Variables for analytics
    uint256 public totalCoins;
    uint256 public totalTokens;

    /// @dev Where the fees will be sent
    address public feeCollector;

    mapping (address => uint256) public userTotalCoins;
    mapping (address => uint256) public userTotalTokens;

    /// @dev Struct for payments
    /// @param user Who made the payment
    /// @param last_date When the last payment was made
    /// @param expire_date When the user needs to pay again
    /// @param token_addr Token Address that you made the payment
    struct Subscribe {
        address user;
        uint256 last_date;
        uint256 expire_date;
        address token_addr;
    }

    /// @dev Array of subscribes
    Subscribe[] public subscribes;

    /// @dev User Subscribe
    mapping(address => Subscribe) public userSubscribe;

   /// @dev Events
    event UserSubscribed(address indexed subscriber, uint256 fee, address token_addr, uint256 period);

    /// @dev Errors
    error SubscriptionNotPaid();


    /// @dev We transfer the ownership to a given owner
    constructor() {
        _transferOwnership(_msgSender());
        feeCollector = _msgSender();
    }

    /// @dev Modifier to check if user's subscription is still active
    modifier isUserSubscribed() {
        if(block.timestamp >= userSubscribe[msg.sender].expire_date) 
        revert SubscriptionNotPaid();
        _;
    }

    /// @dev Function to pay the subscription
    /// @notice User can chose to pay either in Eth, either in Erc20 Tokens
    /// @param _period For how many months the user wants to pay the subscription
    /// @param _tokenAddr - Token address that you pay to subscribe
    function paySubscription(uint256 _period, address _tokenAddr) external payable virtual returns(bool) {
        
        IERC20Upgradeable _subscribeToken = IERC20Upgradeable(_tokenAddr);
        uint256 amount = _tokenAddr == address(0) ? coinFee * _period : tokenFee * _period;
        _subscribeToken.universalTransfer(address(this), amount);
        if(_tokenAddr == address(0)) {
            totalCoins = totalCoins + msg.value; // Compute total payments in PLS
            userTotalCoins[msg.sender] = userTotalCoins[msg.sender] + msg.value; // Compute user's total payments in PLS
        } else {
            totalTokens = totalTokens + msg.value; // Compute total payments in Eth
            userTotalTokens[msg.sender] = userTotalTokens[msg.sender] + msg.value; // Compute user's total payments in Eth
        }
        Subscribe memory newSub = Subscribe(msg.sender, block.timestamp, block.timestamp + _period * 30 days, _tokenAddr);
        subscribes.push(newSub); // Push the payment in the payments array
        userSubscribe[msg.sender] = newSub; // User's last payment

        emit UserSubscribed(msg.sender, amount, _tokenAddr, _period);

        return true;
    }

    /// @dev Set the monthly Coin fee
    function setCoinFee(uint256 _newCoinFee) external virtual onlyOwner {
        coinFee = _newCoinFee;
    }

    /// @dev Set the monthly Erc20 fee
    function setTokenFee(uint256 _newTokenFee) external virtual onlyOwner {
        tokenFee = _newTokenFee;
    }

    /// @dev Set a new payment collector
    function setNewPaymentCollector(address _feeCollector) external virtual onlyOwner {
        feeCollector = _feeCollector;
    }

    /// @dev Withdraw the Eth balance of the smart contract
    function withdraw() external virtual onlyOwner {
    }

    /// @notice To recieve ETH
    receive() external payable {}
}