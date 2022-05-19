//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IERC721Template.sol";
import "./interfaces/IERC20Template.sol";
import "./interfaces/StakingToken.sol";
import "./interfaces/IStakingNFT.sol";

contract NVG8Marketplace is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _dataTokenIdCounter;

    // enlist when a data token created
    // sell/ buy data token
    // rent data token for use
    //
    /*
                     _______________                   
                    /\             /\
                   /  \           /  \
                  /    \         /    \
                 /      \_______/      \
                /  ___            ___   \
               [| / 0 \          / 0 \  |]
               [|                       |]
                \         _  _          /
                 \       | \/ |        /
                  \     ________      /
                   \   /--------\    /
                    \       _       /
                     \_____/ \_____/

*/
    // EVENTS

    // STRUCTS
    struct DataToken {
        address erc721Token;
        address erc20Token;
        address owner;
        string name;
        string symbol;
        uint256 usagePrice;
        bool isActive;
    }

    // STATE VARIABLES
    mapping(uint256 => DataToken) public dataTokens;
    address public nvg8Factory;
    mapping(uint256 => mapping(address => uint256))
    public dataTokenUseAllowance;
    StakingToken public stake;
    StakingNFT public stakenft;

    // MODIFIERS
    modifier onlyFactoryOrOwner() {
        require(
            msg.sender == nvg8Factory || msg.sender == owner(),
            "Only factory or owner can do this"
        );
        _;
    }

    // CONSTRUCTOR
    constructor() {}

    function enlistDataToken(
        address _erc721Token,
        address _erc20Token,
        address _owner,
        string memory _name,
        string memory _symbol,
        uint256 _usagePrice
    ) public onlyFactoryOrOwner returns (bool _success) {
        //check if the data token is already enlisted
        uint256 _dataTokenId = _dataTokenIdCounter.current();
        _dataTokenIdCounter.increment();
        // enlist data token
        DataToken memory dataToken = DataToken(
            _erc721Token,
            _erc20Token,
            _owner,
            _name,
            _symbol,
            _usagePrice,
            true
        );
        dataTokens[_dataTokenId] = dataToken;
        return true;
    }

    function unlistDataToken(uint256 _dataTokenId) public {
        // verify the owner & unlist datatoken if it is active
        require(dataTokens[_dataTokenId].isActive, "Data token is not active");
        require(
            dataTokens[_dataTokenId].owner == msg.sender ||
                msg.sender == owner(),
            "Only the datatoken owner or contract owner can unlist data token"
        );

        dataTokens[_dataTokenId].isActive = false;
    }

    function getDataToken(uint256 _dataTokenId)
        public
        view
        returns (DataToken memory)
    {
        return dataTokens[_dataTokenId];
    }

    function deleteDataToken(uint256 _dataTokenId) public onlyOwner {
        // delete data token
        delete dataTokens[_dataTokenId];
    }

    function buyDataTokenForUse(uint256 _dataTokenId, uint256 _days) public {
        // TODO: validate _days
        require(
            dataTokens[_dataTokenId].erc20Token != address(0) &&
                dataTokens[_dataTokenId].isActive,
            "Data token not enlisted"
        );
        require(
            IERC20Template(dataTokens[_dataTokenId].erc20Token).balanceOf(
                msg.sender
            ) >= dataTokens[_dataTokenId].usagePrice,
            "Not enough balance"
        );

        // require(IERC20Template(dataTokens[_dataTokenId].erc20Token).allowance(msg.sender, address(this)) >= _amount * dataTokens[_dataTokenId].usagePrice, "Not enough allowance");

        IERC20Template(dataTokens[_dataTokenId].erc20Token).transferFrom(
            msg.sender,
            dataTokens[_dataTokenId].owner,
            dataTokens[_dataTokenId].usagePrice
        );
        dataTokenUseAllowance[_dataTokenId][msg.sender] =
            block.timestamp + _days * 24 * 60 * 60;
    }

    function isAllowedToUseDataToken(uint256 _dataTokenId)
        public
        view
        returns (bool _allowed)
    {
        if (dataTokenUseAllowance[_dataTokenId][msg.sender] > block.timestamp) {
            _allowed = true;
        } else {
            _allowed = false;
        }
    }

    // FUCTIONS FOR FACTORY CONTRACT
    function setFactory(address _nvg8Factory) public onlyOwner {
        nvg8Factory = _nvg8Factory;
    }
    
    //STAKING FUNCTIONALITY OF ERC20 TOKEN
    function stakeToken(uint256 _amount, uint256 _dataTokenId) public returns(bool) {
        stake.setERC20Token(dataTokens[_dataTokenId].erc20Token);
        stake.addStake(dataTokens[_dataTokenId].owner, _amount);
        return true;
    }

    function unstakeToken(uint256 _amount, uint256 _dataTokenId) public returns(bool) {
        stake.removeStake(dataTokens[_dataTokenId].owner, _amount);
        return true;
    }

    function reward() public returns(bool) {
        stake.reward(msg.sender);
        return true;
    }

    //STAKING FUNCTIONALITY OF ERC721 TOKEN
    function stakeNFT(uint256 _dataTokenId) public returns(bool) {
        stakenft.setERC721Token(dataTokens[_dataTokenId].erc721Token);
        stakenft.stakeNFT(dataTokens[_dataTokenId].owner);
        return true;
    }

    function unstakeNFT(uint256 _dataTokenId) public returns(bool) {
        stakenft.unstakeNFT(dataTokens[_dataTokenId].owner);
        return true;
    }

    function claimReward() public returns(bool) {
        stakenft.reward(msg.sender);
        return true;
    }

}
