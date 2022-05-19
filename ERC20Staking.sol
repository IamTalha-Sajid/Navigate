//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function mintReward(address _userAdd) external returns(bool);
}

contract Staking {

    struct stake{
        address userId;
        uint amount;
        uint _stakingtime;
        bool staked;
    }

    IERC20 public token;
    IERC20 public rewardToken;
    mapping (address => stake) stakes;

    constructor() {}

    //Sets the Address of the Token User Wanna Stake
    function setERC20Token(address _token) public returns(bool){
        token = IERC20(_token);
        return true;
    }

    //Function to set the Reward ERC20 Token
    function setRewardToken(address _token) public returns(bool){
        rewardToken = IERC20(_token);
        return true;
    }

    //Function to Stake Tokens
    function addStake(address _user, uint _amount) public returns (bool){
        require (_amount <= token.allowance(_user, address(this)), "You can't Stake More than You Own");
        stakes[_user] = stake(_user, _amount, block.timestamp, true);
        token.transferFrom(_user, address(this), _amount);
        return true;
    }

    //Function to Claim Reward While Staking
    function reward(address _user) public returns(bool) {
        require(stakes[_user].staked == true, "You Haven't Staked any Tokens");
        rewardToken.mintReward(_user);
        return true;
    }

    //Function to Unstake Tokens
    function checkStakedToken (address _user) public view returns (uint){
        require(stakes[_user].staked == true, "You Haven't Staked any Tokens");
        return stakes[_user].amount;
    }

    //Function to Unstake Tokens
    function removeStake (address _user, uint _amount) public returns (bool){
        require(stakes[_user].staked == true, "You Haven't Staked any Tokens");
        require(stakes[_user].amount >= _amount, "You can't Unstake more than you have Staked");
        require((stakes[_user]._stakingtime + 60) <= block.timestamp, "You cannot Unstake Before 1 Minute");
        stakes[_user].amount = stakes[_user].amount - _amount;
        token.transfer(_user, _amount);
        if (stakes[_user].amount == _amount){
            stakes[_user].staked = false;
        }
        return true;
    }

    //Check the Token Balance Staked in the Contract
    function checkContractBalance () public view returns(uint256){
        return token.balanceOf(address(this));
    }

    //Check If User is Currently Staking or Not
    function checkStakingStatus(address _user) public view returns(bool){
        return (stakes[_user].staked);
    }
}
