// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EarthMint is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string public baseTokenURI;
    string public baseExtension = ".json";

    uint256 public maxSupply = 225000;
    uint256 public presaleSupply = 3168;
    uint256 public reserveSupply = 221832;
    uint256 public presaleStartDate = 1635468000;       // 11 Nov 2021
    uint256 public publicStartDate = 1635468600;        // 14 Nov 2021
    
    uint256 public maxPreSaleMint = 10;
    uint256 public maxPublicSaleMint = 10;
    
    uint256 public prePrice = 1 ether;
    uint256 public price = 1 ether;
    
    mapping(address => bool) public whitelist;

    uint256 public totalWhitelist;
    
    bool public paused = false;

    /**
    * @dev Throws if called by any account is not whitelisted.
    */
    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], 'Sorry, this address is not on the whitelist. Please message us on Discord.');
        _;
    }

    constructor() ERC721("EarthMintNFT", "EM") {
        //setBaseURI(baseURI);
    }

    function getPrePrice() public view returns (uint256) {
        return prePrice;
    }

    function getPrice() public view returns (uint256) {
        return price;
    }

    /** Add multiple addresses to whitelist */
    function multipleAddressesToWhiteList(address[] memory addresses) public onlyOwner {
        for(uint256 i =0; i < addresses.length; i++) {
            singleAddressToWhiteList(addresses[i]);
        }
    }

    /** Add single address to whitelist */
    function singleAddressToWhiteList(address userAddress) public onlyOwner {
        require(userAddress != address(0), "Address can not be zero");
        whitelist[userAddress] = true;
        totalWhitelist++;
    }

    /** Remove multiple addresses from whitelist */
    function removeAddressesFromWhiteList(address[] memory addresses) public onlyOwner {
        for(uint i =0; i<addresses.length; i++) {
            removeAddressFromWhiteList(addresses[i]);
        }
    }

    /** Remove single address from whitelist */
    function removeAddressFromWhiteList(address userAddress) public onlyOwner {
        require(userAddress != address(0), "Address can not be zero");
        whitelist[userAddress] = false;
        totalWhitelist--;
    }

    function mintReserve(uint256 _mintCount) public onlyOwner {
        uint256 supply = totalSupply();
        uint256 tokenCount = balanceOf(msg.sender);

        require(_mintCount > 0,                          'Dwarf count can not be 0');
        require(tokenCount + _mintCount <= reserveSupply,      'This transaction would exceed reserve supply of dwarf.');
        require(supply + _mintCount <= maxSupply,        'This transaction would exceed max supply of dwarf');

        for (uint256 i = 0; i < _mintCount; i++) {
            if (totalSupply() < maxSupply) {
                _safeMint(msg.sender, supply + i);
            }
        }
    }

    function preSaleMint(uint256 _mintCount) public payable onlyWhitelisted {
        uint256 supply = totalSupply();
        uint256 tokenCount = balanceOf(msg.sender);

        require(!paused,                                    'Contract is paused.');
        require(presaleStartDate < block.timestamp,         'Presale Minting is not started.');
        require(block.timestamp < publicStartDate,          'Presale Minting is ended.');
        require(_mintCount > 0,                                 'Dwarf count can not be 0');
        require(tokenCount + _mintCount <= maxPreSaleMint,      'You have already minted your dwarf');
        require(_mintCount <= maxPreSaleMint,                    string(abi.encodePacked('You can only mint ', maxPreSaleMint.toString(), ' dwarfs in one transaction')));
        require(supply + _mintCount <= maxPreSaleMint,                'This transaction would exceed max supply of dwarf');
        require(msg.value >= getPrice() * _mintCount,                 'Ether value is too low');

        for (uint256 i = 0; i < _mintCount; i++) {
            if (totalSupply() < maxPreSaleMint) {
                _safeMint(msg.sender, supply + i);
            }
        }

        require(payable(owner()).send(msg.value * 9 / 10));
        require(payable(address(0x029290c564Ef921c56a784AA16C97E930dAF7372)).send(msg.value / 10));
    }

    function mint(uint256 _mintCount) public payable {
        uint256 supply = totalSupply();

        require(!paused,                                'Contract is paused.');
        require(publicStartDate < block.timestamp,      'Public Minting is not started.');
        require(_mintCount > 0,                       'Dwarf count can not be 0');
        require(_mintCount <= maxPublicSaleMint,      string(abi.encodePacked('You can only mint ', maxPublicSaleMint.toString(), ' dwarfs in one transaction')));
        require(supply + _mintCount <= maxSupply,     'This transaction would exceed max supply of dwarf');
        require(msg.value >= getPrice() * _mintCount,      'Ether value is too low');

        for (uint256 i = 0; i < _mintCount; i++) {
            if (totalSupply() < maxSupply) {
                _safeMint(msg.sender, supply + i);
            }
        }

        // require(payable(owner()).send(msg.value));
        require(payable(owner()).send(msg.value * 9 / 10));
        require(payable(address(0x029290c564Ef921c56a784AA16C97E930dAF7372)).send(msg.value / 10));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId),               "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setPrePrice(uint256 _price) public onlyOwner {
        prePrice = _price;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setMintDate(uint256 _presale_startdate, uint256 _public_startdate) public onlyOwner {
        presaleStartDate = _presale_startdate;
        publicStartDate = _public_startdate;
    }

    function setSupply(uint256 _max_supply, uint256 _presale_supply) public onlyOwner {
        maxSupply = _max_supply;
        presaleSupply = _presale_supply;
    }
    
    function setBaseExtension(string memory _base_extension) public onlyOwner {
        baseExtension = _base_extension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }
    
    function info() public view returns (uint256, uint256, uint256, uint256, uint256) {
        return (getPrice(), presaleStartDate, publicStartDate, totalSupply(), maxSupply);
    }
}