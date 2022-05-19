//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IERC20 {
    function mintReward(address _userAdd) external returns(bool);
}

contract NFTStaking {

    struct stake{
        address userId;
        uint tokenId;
        uint _stakingtime;
        bool staked;
    }

    IERC721 public nft;
    IERC20 public rewardToken;
    mapping (address => stake) stakes;

    constructor() {}

    //Function that Allows user to Enter their NFT Contract Address
    function setERC721Token(address _nft) public returns(bool){
        nft = IERC721(_nft);
        return true;
    }

    //Function that Allows user to Enter the ERC20 Reward Token
    function setRewardToken(address _token) public returns(bool){
        rewardToken = IERC20(_token);
        return true;
    }

    //Stake NFTs of the User
    function stakeNFT(address _user) public returns(bool){
        require (stakes[_user].staked == false, "NFT Already Staked");
        require (nft.balanceOf(_user) != 0, "You Dont Own any NFT");
        stakes[_user] = stake(_user, 1, block.timestamp, true);
        nft.transferFrom(_user, address(this), 1);
        return true;
    }

    //Unstake the NFTs of the User
    function unstakeNFT(address _user) public returns (bool){
        require (stakes[_user].staked == true, "No Staked NFT Found");
        require((stakes[_user]._stakingtime + 60) <= block.timestamp, "You cannot Unstake Before 1 Minute");
        nft.transferFrom(address(this), _user, 1);
        return true;
    }

    //Clam Reward for Staking the NFTs, Triggered Automatically
    function reward(address _user) public returns(bool) {
        require(stakes[_user].staked == true, "You Haven't Staked any Tokens");
        rewardToken.mintReward(_user);
        return true;
    }

    //Check If User is Currently Staking NFTs or Not
    function checkStakingStatus(address _user) public view returns(bool){
        require (stakes[_user].staked == true, "No Staked NFT Found");
        return (stakes[_user].staked);
    }

    //Recieves NFTs after Approval in the Smart Contracts
    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
      require(from == address(0x0), "Cannot send nfts to Vault directly");
      return IERC721Receiver.onERC721Received.selector;
    }
}
