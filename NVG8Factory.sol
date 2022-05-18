//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC721Template.sol";
import "./interfaces/IERC20Template.sol";
import "./interfaces/INVG8Marketplace.sol";

contract NVG8Factory is Ownable {
    // EVENTS
    event TemplateAdded(TemplateType _type, address _template);
    event TemplateRemoved(TemplateType _type, address _template);
    event TemplateStatusChanged(TemplateType _type, address _template, bool _status);
    event DataTokenCreated(address _erc721Token, address _erc20Token, address _owner, string _name, string _symbol, uint256 _totalSupply, string _uri);

    // ENUM
    enum TemplateType {
        ERC721,
        ERC20
    }

    // STRUCTS
    struct Template {
        address templateAddress;
        bool isActive;
        TemplateType templateType;
    }
    struct DataToken {
        address erc721Token;
        address erc20Token;
        address owner;
        string name;
        string symbol;
        uint256 usagePrice;
    }

    // STATE VARIABLES
    mapping(uint256 => Template) public templates;
    address public nvg8Marketplace;
    bytes4 private constant _InterfaceId_ERC721 = 0x80ac58cd;
    bytes4 private constant _InterfaceId_ERC20 = 0x36372b07;

    // MODIFIERS

    // CONSTRUCTOR
    constructor() {}

    // TEMPLATE FUNCTIONS
    function createTemplate(
        TemplateType _type,
        address _template, //Address of ERC20 and ERC721 Token Template which have been Deployed Already//
        uint256 _index
    ) public onlyOwner {
        require(
            templates[_index].templateAddress == address(0),
            "Template already exists"
        );

        templates[_index] = Template({
            templateAddress: _template,
            isActive: true,
            templateType: _type
        });

        emit TemplateAdded(_type, _template);
    }

    function removeTemplate(uint256 _index) public onlyOwner {
        require(
            templates[_index].templateAddress != address(0),
            "Template does not exist"
        );

        emit TemplateRemoved(
            templates[_index].templateType,
            templates[_index].templateAddress
        );

        delete templates[_index];
    }

    function changeTemplateStatus(uint256 _index, bool _status)
        public
        onlyOwner
    {
        require(
            templates[_index].templateAddress != address(0),
            "Template does not exist"
        );

        templates[_index].isActive = _status;

        emit TemplateStatusChanged(
            templates[_index].templateType,
            templates[_index].templateAddress,
            _status
        );
    }

    // DATA TOKEN FUNCTIONS
    function createDataToken(
        uint256 _ERC721TemplateIndex,
        uint256 _ERC20TemplateIndex,
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _totalSuply
    ) public {
        require(
            templates[_ERC721TemplateIndex].templateAddress != address(0) &&
                templates[_ERC721TemplateIndex].isActive &&
                templates[_ERC721TemplateIndex].templateType ==
                TemplateType.ERC721,
            "ERC721 template does not exist or is not active"
        );

        require(
            templates[_ERC20TemplateIndex].templateAddress != address(0) &&
                templates[_ERC20TemplateIndex].isActive &&
                templates[_ERC20TemplateIndex].templateType ==
                TemplateType.ERC20,
            "ERC20 template does not exist or is not active"
        );

        // clone ERC721Template
        address erc721Token = Clones.clone(
            templates[_ERC721TemplateIndex].templateAddress
        );

        // clone ERC20Template
        address erc20Token = Clones.clone(
            templates[_ERC20TemplateIndex].templateAddress
        );

        // initialize erc721Token
        IERC721Template(erc721Token).initialize(
            _name,
            _symbol,
            msg.sender,
            _uri
        );

        // initialize erc20Token
        IERC20Template(erc20Token).initialize(
            _name,
            _symbol,
            msg.sender,
            _totalSuply
        );

        enlistDataTokenOnMarketplace(
            erc721Token,
            erc20Token,
            msg.sender,
            _name,
            _symbol,
            1
        );

        emit DataTokenCreated(
            erc721Token,
            erc20Token,
            msg.sender,
            _name,
            _symbol,
            _totalSuply,
            _uri
        );
    }

    // MARKETPLACE FUNCTIONS
    function setMarketplace(address _marketplace) public onlyOwner {
        nvg8Marketplace = _marketplace;
    }

    function enlistDataTokenOnMarketplace(
        address _erc721Token,
        address _erc20Token,
        address _owner,
        string memory _name,
        string memory _symbol,
        uint256 _usagePrice
    ) private {
        require(nvg8Marketplace != address(0), "Nvg8 Marketplace is not set");
        // TODO: is valid ERC721 & ERC20 token

        bool _success = INVG8Marketplace(nvg8Marketplace).enlistDataToken(
            _erc721Token,
            _erc20Token,
            _owner,
            _name,
            _symbol,
            _usagePrice
        );
        require(_success, "Failed to enlist data token on marketplace");
    }
}

// Todo: how to manage who can use the token?
// Todo: add tests
// Todo: add documentation
