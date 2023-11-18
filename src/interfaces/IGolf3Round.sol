// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IGolf3Round {
    struct RoundInit {
        string courseName;
        address[] players;
        uint8[] holePars;
        address buyInToken;
        uint256 buyInAmount;
        uint256 skinsBuyInAmount;
        uint256[] payoutPercent;
        uint256 roundTimeoutPeriod;
    }

    struct PlayerValuePair {
        address player;
        uint256 value;
    }

    event CreateRound(address indexed roundAddress, address indexed admin, RoundInit roundInit, uint256 timestamp);

    event PlayersRound(address indexed roundAddress, address indexed player, uint256 index, uint256 timestamp);

    event FinalizeRound(
        address indexed roundAddress,
        address[] players,
        uint8[] scores,
        uint8[] putts,
        bool[] fir,
        bool[] gir
    );

    event DepositedBuyIn(
        address indexed roundAddress,
        address indexed playerAddress,
        uint256 depositAmount,
        uint256 newMoneyRoundTotal,
        uint256 timestamp
    );
    
    event DepositSkinsBuyIn(
        address indexed roundAddress,
        address indexed playerAddress,
        uint256 depositAmount,
        uint256 newSkinsRoundTotal,
        uint256 timestamp
    );

    event Donated(
        address indexed roundAddress,
        address indexed userAddress,
        uint256 donationAmount,
        uint256 newMoneyRoundTotal,
        uint256 timestamp
    );

    event MoneyRoundWinnings(address indexed roundAddress, address indexed player, uint256 amountWon, uint256 timestamp);

    event SkinsWinnings(address indexed roundAddress, address indexed player, uint256 amountWon, uint256 timestamp);

    event Withdraw(address indexed roundAddress, address indexed userAddress, uint256 withdrawAmount, uint256 timestamp);

    event Claim(address indexed roundAddress, address indexed userAddress, uint256 claimAmount, uint256 timestamp);
    
    event UpdateScoresAll(address indexed roundAddress, uint8[] scores, uint256 timestamp);

    event UpdateScoresPlayer(address indexed roundAddress, address indexed playerAddress, uint8[] scores, uint256 timestamp);

    event UpdateScoresSingle(address indexed roundAddress, address indexed playerAddress, uint8 score, uint8 hole, uint256 timestamp);
}