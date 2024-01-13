// SPDX-License-Identifier: MIT















pragma solidity ^0.8.0;

import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/974c534210ab3347bdaa45f0f07cfe298a8a6866/contracts/utils/ReentrancyGuard.sol";


interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}


contract MagicInternetStakers is ReentrancyGuard {
    IERC20 public immutable token; 

    address private _owner; 

    mapping(address => uint256) public totalStaked; 
    uint256 public totalRewards; 

    // Time constants in seconds (Immutable)
    uint256 public constant REWARD_INTERVAL = 3600; // Interval for claiming rewards (1 hour)
    uint256 public constant LOCK_PERIOD = 172800; // Lock period before users can unstake (48 hours)
    uint256 public constant COOLDOWN_PERIOD = 600; // Cooldown period before users can restake (10 minutes)

    
    // Staker struct
    struct StakerInfo {
    uint256 balance; // Tokens staked by the user
    uint256 reward; // Accumulated rewards
    uint256 lastClaimTime; // Last time rewards were claimed
    uint256 stakeStartTime; // Timestamp when the user started staking
    uint256 lastStakeTime; // Timestamp of the last staking action
    bool autoCompound; // Flag for auto-compounding rewards
}


    // Mapping from user to staker info
    mapping(address => StakerInfo) public stakers; 

    // Events for logging activities
    event Staked(address indexed user, uint256 amount, bool autoCompound);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);
    event RewardsDeposited(uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event AutoCompoundToggled(address indexed user, bool autoCompound);

    
    
    // Modifier for owner-only functions
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function.");
        _;
    }

    
    
    // Constructor to initialize the contract
    constructor(address tokenAddress) {
        _owner = msg.sender;
        token = IERC20(tokenAddress);
    }

    
    
    // Function for owner to deposit rewards
    function depositMiningRewards(uint256 _amount) external onlyOwner {
        require(token.transferFrom(msg.sender, address(this), _amount), "Transfer failed.");
        totalRewards += _amount;
        emit RewardsDeposited(_amount);
    }

    
    
    // Function for users to stake tokens
    function stakeMiners(uint256 _amount, bool _autoCompound) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0.");
        require(token.allowance(msg.sender, address(this)) >= _amount, "Insufficient allowance.");
        require(token.transferFrom(msg.sender, address(this), _amount), "Transfer failed.");

        StakerInfo storage staker = stakers[msg.sender];
        staker.balance += _amount;
        staker.autoCompound = _autoCompound;
        staker.stakeStartTime = block.timestamp; // Update the stake start time

        totalStaked[msg.sender] += _amount;
        emit Staked(msg.sender, _amount, _autoCompound);
    }

    
    
    // Function for users to claim rewards
    function claimMinerRewards() external nonReentrant {
        StakerInfo storage staker = stakers[msg.sender];
        require(block.timestamp >= staker.lastClaimTime + REWARD_INTERVAL, "Reward interval not yet passed.");

        uint256 reward = calculateMinerReward(msg.sender);
        require(reward > 0, "No rewards available to claim.");
        staker.reward += reward;
        staker.lastClaimTime = block.timestamp;

        if (staker.autoCompound) {
            staker.balance += reward; // Auto-compound the reward
            totalStaked[msg.sender] += reward;
        }

        emit RewardClaimed(msg.sender, reward);
    }

    
    
    // Function for users to unstake tokens
    function unstakeMiners(uint256 _amount) external nonReentrant {
        StakerInfo storage staker = stakers[msg.sender];
        require(_amount > 0 && _amount <= staker.balance, "Invalid unstake amount.");
        require(block.timestamp >= staker.lastStakeTime + LOCK_PERIOD, "Lock period has not passed.");

        staker.balance -= _amount;
        totalStaked[msg.sender] -= _amount;

        require(token.transfer(msg.sender, _amount), "Transfer failed.");
        emit Unstaked(msg.sender, _amount);
    }

    
    
    // Function to calculate the reward for a user
    function calculateMinerReward(address _user) internal view returns (uint256) {
        StakerInfo storage staker = stakers[_user];
        if (totalStaked[msg.sender] == 0) return 0;
        uint256 stakerShare = staker.balance * totalRewards / totalStaked[msg.sender];
    
     // Enhanced reward calculation considering staking duration to incentivize longer staking
        uint256 stakingDuration = block.timestamp - staker.stakeStartTime;
        return stakerShare * stakingDuration / REWARD_INTERVAL;
    }

 
 
    // Function for users to withdraw their rewards
    function withdrawMiningRewards() external nonReentrant {
        StakerInfo storage staker = stakers[msg.sender];
        uint256 reward = staker.reward;
        require(reward > 0, "No rewards to withdraw.");

        staker.reward = 0;
        require(token.transfer(msg.sender, reward), "Transfer failed.");
        emit Withdrawal(msg.sender, reward);
    }
}