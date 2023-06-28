// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// File: contracts/UniversalERC20Upgradeable.sol

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

library UniversalERC20Upgradeable {
    using AddressUpgradeable for address payable;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable public constant ZERO_ADDRESS =
        IERC20Upgradeable(0x0000000000000000000000000000000000000000);
    IERC20Upgradeable public constant ETH_ADDRESS =
        IERC20Upgradeable(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    error WrongUsage();

    function universalTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        if (amount == 0) return 0;

        if (isETH(token)) {
            payable(address(uint160(to))).sendValue(amount);
            return amount;
        } else {
            uint256 balanceBefore = token.balanceOf(to);
            token.safeTransfer(to, amount);
            return token.balanceOf(to) - balanceBefore;
        }
    }

    function universalTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        if (amount == 0) return 0;

        if (isETH(token)) {
            if (from != msg.sender || msg.value < amount) revert WrongUsage();
            if (to != address(this))
                payable(address(uint160(to))).sendValue(amount);
            // refund redundant amount
            if (msg.value > amount)
                payable(msg.sender).sendValue(msg.value - amount);
            return amount;
        } else {
            uint256 balanceBefore = token.balanceOf(to);
            token.safeTransferFrom(from, to, amount);
            return token.balanceOf(to) - balanceBefore;
        }
    }

    function universalTransferFromSenderToThis(
        IERC20Upgradeable token,
        uint256 amount
    ) internal returns (uint256) {
        if (amount == 0) return 0;

        if (isETH(token)) {
            if (msg.value < amount) revert WrongUsage();
            // Return remainder if exist
            if (msg.value > amount)
                payable(msg.sender).sendValue(msg.value - amount);
            return amount;
        } else {
            uint256 balanceBefore = token.balanceOf(address(this));
            token.safeTransferFrom(msg.sender, address(this), amount);
            return token.balanceOf(address(this)) - balanceBefore;
        }
    }

    function universalApprove(
        IERC20Upgradeable token,
        address to,
        uint256 amount
    ) internal {
        if (!isETH(token)) {
            if (amount > 0 && token.allowance(address(this), to) > 0)
                token.safeApprove(to, 0);
            token.safeApprove(to, amount);
        }
    }

    function universalBalanceOf(
        IERC20Upgradeable token,
        address who
    ) internal view returns (uint256) {
        if (isETH(token)) return who.balance;
        return token.balanceOf(who);
    }

    function universalDecimals(
        IERC20Upgradeable token
    ) internal view returns (uint256) {
        if (isETH(token)) return 18;

        (bool success, bytes memory data) = address(token).staticcall{
            gas: 10000
        }(abi.encodeWithSignature("decimals()"));
        if (!success || data.length == 0) {
            (success, data) = address(token).staticcall{gas: 10000}(
                abi.encodeWithSignature("DECIMALS()")
            );
        }

        return (success && data.length > 0) ? abi.decode(data, (uint256)) : 18;
    }

    function isETH(IERC20Upgradeable token) internal pure returns (bool) {
        return (address(token) == address(ZERO_ADDRESS) ||
            address(token) == address(ETH_ADDRESS));
    }
}
