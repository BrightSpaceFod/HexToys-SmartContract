// HexToysMultipleNFT token
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract HexToysNFT is Initializable, ERC1155SupplyUpgradeable, AccessControlUpgradeable, OwnableUpgradeable {
    using SafeMath for uint256;
    using AddressUpgradeable for address payable;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    enum MODE {
        STANDARD,
        GOLD,
        PLATINUM
    }

    struct MODE_INFO {
        uint256 quantity;
        uint256 mintPrice;
    }

    mapping(MODE => MODE_INFO) modeInfo;
    MODE currentMode;

    address public RECEIVER_ADDRESS;

    bool public isPublic;
    uint256 public tokenId;
    mapping (uint256 => string) public tokenURI;

    event TokenUriUpdated(uint256 id, string uri);
    
    // Token name
    string public name;

    // Token symbol
    string public symbol;

    function initialize(address recvAddr) public initializer {
        __ERC1155_init("HEX TOYS");
        __Ownable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);

        modeInfo[MODE.STANDARD].quantity = 369;
        modeInfo[MODE.STANDARD].mintPrice = 3*1e6 ether; //3M PLS

        modeInfo[MODE.GOLD].quantity = 33;
        modeInfo[MODE.GOLD].mintPrice = 9*1e6 ether; //9M PLS

        modeInfo[MODE.PLATINUM].quantity = 1;
        modeInfo[MODE.PLATINUM].mintPrice = 33*1e6 ether; //33M PLS

        RECEIVER_ADDRESS = recvAddr;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Upgradeable, AccessControlUpgradeable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setNameAndSymbol(string memory _name, string memory _symbol) public onlyOwner {
        name = _name;
        symbol = _symbol;
    }

    function contractURI() public view returns (string memory) {
        return super.uri(0);
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);      
    }

    function setRecvAddr(address _recvAddr) external onlyOwner {
        RECEIVER_ADDRESS = _recvAddr;
    }

    function setPublic(bool _isPublic) external onlyOwner {
        isPublic = _isPublic;
    }

    function setCurrentTokenId(uint256 _tokenId, MODE _mode) external onlyOwner {
        tokenId = _tokenId;
        currentMode = _mode;
    }

    function getCurrentTokenId() external view returns (uint256 _tokenId, uint256 _mintPrice) {
        return (tokenId, modeInfo[currentMode].mintPrice);
    }

    function getCurrentMode() external view returns (MODE _mode) {
        return currentMode;
    }

    function getModelInfo(MODE mode) external view returns (MODE_INFO memory _modeInfo) {
        return modeInfo[mode];
    }

    function updateModeInfo(MODE _mode, uint256 _quantity, uint256 _mintPrice) external onlyOwner {
        modeInfo[_mode].quantity = _quantity;
        modeInfo[_mode].mintPrice = _mintPrice;
    }

    function setCustomURI(uint256 _tokenId, string memory _newURI) public onlyOwner {
        tokenURI[_tokenId] = _newURI;       
        emit TokenUriUpdated(_tokenId, _newURI);        
    }

    function setCustomURIs(uint256[] memory _tokenIds, string[] memory _newURIs) public onlyOwner {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            tokenURI[_tokenId] = _newURIs[i];
            emit TokenUriUpdated(_tokenId, _newURIs[i]);
        }
    }

    function uri(uint256 _tokenId) public view override returns (string memory) {
        require(exists(_tokenId), "ERC1155Tradable#uri: NONEXISTENT_TOKEN");
        // We have to convert string to bytes to check for existence
        bytes memory customUriBytes = bytes(tokenURI[_tokenId]);
        if (customUriBytes.length > 0) {
            return tokenURI[_tokenId];
        } else {
            return super.uri(_tokenId);
        }
    }

    function airdrop(uint256 _tokenId, address[] memory airdropAddress, uint256[] memory supplys) external onlyOwner {
        for (uint256 i = 0; i < airdropAddress.length; i++){
            _mint(airdropAddress[i], _tokenId, supplys[i], "Mint");
        }
    }

    function addItem( uint256 supply ) public payable returns (uint256) {
        require(isPublic, "The minting is not public yet.");
        require(supply > 0, "supply can not be 0");
        if (tokenId != 14) {
            uint256 curTotalSupply = totalSupply(tokenId);
            require(curTotalSupply + supply <= modeInfo[currentMode].quantity, "You can not mint the supply");
        }        
        
        if (RECEIVER_ADDRESS != msg.sender) {
            payable(RECEIVER_ADDRESS).sendValue(msg.value);
        }
        _mint(msg.sender, tokenId, supply, "Mint");
        return tokenId;
    }

    function burn(uint256 _tokenId, uint256 amount) public returns(bool){
		uint256 nft_token_balance = balanceOf(msg.sender, _tokenId);
		require(nft_token_balance > 0, "Only owner can burn");
        require(nft_token_balance >= amount, "invalid amount : amount have to be smaller than the balance");		
		_burn(msg.sender, _tokenId, amount);
		return true;
	}
}
