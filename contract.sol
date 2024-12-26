// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title HealthyHabitRewards
 * @dev A smart contract for tracking and rewarding healthy habits
 */
contract HealthyHabitRewards is ERC20, Ownable {
    // Struct to store habit tracking information
    struct HabitTracker {
        string habitName;
        uint256 startDate;
        uint256 lastCompletionDate;
        uint256 completionStreak;
        bool isActive;
    }

    // Mapping to store user's habits
    mapping(address => mapping(string => HabitTracker)) private userHabits;

    // Mapping to track allowed habit types
    mapping(string => bool) private allowedHabitTypes;

    // Reward rates and parameters
    uint256 public constant BASE_DAILY_REWARD = 10 * 10**18; // 10 tokens per day
    uint256 public constant STREAK_MULTIPLIER = 2; // Streak bonus multiplier
    uint256 public constant MAX_STREAK_BONUS = 5; // Maximum streak bonus

    // Events
    event HabitStarted(address indexed user, string habitName);
    event HabitCompleted(address indexed user, string habitName, uint256 rewardsEarned);
    event HabitTypeAdded(string habitType);
    event HabitTypeRemoved(string habitType);

    /**
     * @dev Constructor to initialize the token
     */
    constructor() ERC20("HealthyHabitToken", "HHT") Ownable(msg.sender) {
        // Add some default allowed habit types
        allowedHabitTypes["exercise"] = true;
        allowedHabitTypes["meditation"] = true;
        allowedHabitTypes["healthyEating"] = true;
    }

    /**
     * @dev Start tracking a new habit
     * @param _habitName Name of the habit to track
     */
    function startHabit(string memory _habitName) external {
        // Ensure the habit type is allowed
        require(allowedHabitTypes[_habitName], "Habit type not allowed");
        
        // Ensure user isn't already tracking this habit
        require(!userHabits[msg.sender][_habitName].isActive, "Habit already being tracked");

        // Create new habit tracker
        userHabits[msg.sender][_habitName] = HabitTracker({
            habitName: _habitName,
            startDate: block.timestamp,
            lastCompletionDate: 0,
            completionStreak: 0,
            isActive: true
        });

        emit HabitStarted(msg.sender, _habitName);
    }

    /**
     * @dev Complete a daily habit and earn rewards
     * @param _habitName Name of the habit completed
     */
    function completeHabit(string memory _habitName) external {
        HabitTracker storage habit = userHabits[msg.sender][_habitName];
        
        // Ensure habit is active and being tracked
        require(habit.isActive, "Habit not being tracked");

        // Calculate rewards
        uint256 dailyReward = BASE_DAILY_REWARD;
        
        // Apply streak bonus
        uint256 streakBonus = calculateStreakBonus(habit.completionStreak);
        dailyReward += streakBonus;

        // Mint rewards
        _mint(msg.sender, dailyReward);

        // Update habit tracker
        habit.lastCompletionDate = block.timestamp;
        habit.completionStreak++;

        emit HabitCompleted(msg.sender, _habitName, dailyReward);
    }

    /**
     * @dev Calculate streak bonus for rewards
     * @param _currentStreak Current habit completion streak
     * @return Bonus reward amount
     */
    function calculateStreakBonus(uint256 _currentStreak) internal pure returns (uint256) {
        if (_currentStreak == 0) return 0;
        
        // Bonus increases with streak, capped at MAX_STREAK_BONUS
        uint256 bonus = _currentStreak * STREAK_MULTIPLIER * 10**18;
        return bonus > (MAX_STREAK_BONUS * 10**18) ? (MAX_STREAK_BONUS * 10**18) : bonus;
    }

    /**
     * @dev Add a new allowed habit type (only owner)
     * @param _habitType New habit type to allow
     */
    function addHabitType(string memory _habitType) external onlyOwner {
        require(!allowedHabitTypes[_habitType], "Habit type already exists");
        allowedHabitTypes[_habitType] = true;
        emit HabitTypeAdded(_habitType);
    }

    /**
     * @dev Remove an existing habit type (only owner)
     * @param _habitType Habit type to remove
     */
    function removeHabitType(string memory _habitType) external onlyOwner {
        require(allowedHabitTypes[_habitType], "Habit type does not exist");
        delete allowedHabitTypes[_habitType];
        emit HabitTypeRemoved(_habitType);
    }

    /**
     * @dev Check if a habit type is allowed
     * @param _habitType Habit type to check
     * @return Boolean indicating if habit type is allowed
     */
    function isHabitTypeAllowed(string memory _habitType) external view returns (bool) {
        return allowedHabitTypes[_habitType];
    }

    /**
     * @dev Retrieve user's habit information
     * @param _user Address of the user
     * @param _habitName Name of the habit
     * @return Habit tracker information
     */
    function getUserHabit(address _user, string memory _habitName) 
        external 
        view 
        returns (HabitTracker memory) 
    {
        return userHabits[_user][_habitName];
    }
}