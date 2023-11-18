// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./interfaces/IGolf3Round.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Golf3Round is IGolf3Round {
    using SafeERC20 for IERC20;

    IGolf3Round.RoundInit public roundInit;

    address public admin;

    uint256 constant BASE = 10000;

    uint256 constant MIN_TIMEOUT = 60 minutes;
    uint256 constant MAX_TIMEOUT = 14 days;
    uint8 constant MAX_PLAYER_COUNT = 8;
    uint8 constant MAX_HOLE_COUNT = 72;

    uint8[] public finalScores;

    bool public roundClosed;
    bool public moneyRound;
    bool public skinsRound;
    bool private calledInitialize;

    mapping(address => bool) public isPlayer;
    mapping(address => bool) public paidBuyIn;
    mapping(address => bool) public paidSkinsBuyIn;
    mapping(address => uint256) public amountDeposited;
    mapping(address => uint256) public amountClaimable;

    uint256 public moneyRoundTotal;
    uint256 public skinsRoundTotal;
    uint256 public startTime;

    function initialize(RoundInit calldata _roundInit, address _admin) external initOnce {
        require(_roundInit.players.length > 0, "player amount must be nonzero");
        require(_roundInit.players.length <= MAX_PLAYER_COUNT, "player amount exceeds max");
        require(_roundInit.holePars.length > 0, "holePars length must be nonzero");
        require(_roundInit.holePars.length <= MAX_HOLE_COUNT, "holePars exceeds max length");
        require(_roundInit.roundTimeoutPeriod >= MIN_TIMEOUT, "timeout period less than min");
        require(_roundInit.roundTimeoutPeriod <= MAX_TIMEOUT, "timeout period exceeds max");

        if (_roundInit.buyInAmount > 0) {
            require(_roundInit.buyInToken != address(0), "no buy in token");
            require(_roundInit.players.length > 1, "not enough players");
            require(_roundInit.payoutPercent.length > 0, "no payoutPercent");
            require(_roundInit.payoutPercent.length <= _roundInit.players.length, "invalid payoutPercent length");
            uint256 percentSum;
            for (uint256 i; i < _roundInit.payoutPercent.length; ++i) {
                percentSum += _roundInit.payoutPercent[i];
            }
            require(percentSum == BASE, "invalid payoutPercent total");
            moneyRound = true;
        }

        if (_roundInit.skinsBuyInAmount > 0) {
            require(_roundInit.buyInToken != address(0), "no buy in token");
            require(_roundInit.players.length > 1, "not enough players");
            skinsRound = true;
        }

        for (uint256 i; i < _roundInit.players.length; ++i) {
            require(!isPlayer[_roundInit.players[i]], "player included twice");
            isPlayer[_roundInit.players[i]] = true;
            emit PlayersRound(address(this), _roundInit.players[i], i, block.timestamp);
        }

        roundInit = _roundInit;
        admin = _admin;
        startTime = block.timestamp;
    }

    /**
     * @dev closes round, finalizing all scores, payout if moneyRound or skinsRound
     * @param _scores array of players scores
     * @param _putts array of players putt amount per hole
     * @param _fir array of players fairways in regulation by hole
     * @param _gir array of players greens in regulation by hole
     * NOTICE _scores must be of length #_of_players * #_of_holes
     * NOTICE _putts, _fir, _gir must be of length zero or #_of_players * #_of_holes
     * NOTICE _scores intended to be in form _scores[i] where player = i / #_of_holes and hole = i % #_of_holes
     */
    function finalizeRound(
        uint8[] calldata _scores,
        uint8[] calldata _putts,
        bool[] calldata _fir,
        bool[] calldata _gir
    ) public onlyAdmin roundIsOpen {
        uint256 playersLength = roundInit.players.length;
        uint256 holeParsLength = roundInit.holePars.length;
        uint256 validArraySize = playersLength * holeParsLength;
        require(_scores.length == validArraySize, "invalid score array");
        finalScores = _scores;
        if (_putts.length > 0) {
            require(_putts.length == validArraySize, "invalid putts array");
        }
        if (_fir.length > 0) {
            require(_fir.length == validArraySize, "invalid fir array");
        }
        if (_gir.length > 0) {
            require(_gir.length == validArraySize, "invalid gir array");
        }
        roundClosed = true;

        emit FinalizeRound(address(this), roundInit.players, _scores, _putts, _fir, _gir);

        if (moneyRound) {
            IGolf3Round.PlayerValuePair[] memory playerScorePair = _sortAndScores(_scores);
            _processMoneyRoundPayout(playerScorePair);
        }

        if (skinsRound) {
            _processSkinsRoundPayout(_scores);
        }
    }

    function _sortAndScores(uint8[] memory _scores) internal view roundIsClosed returns (IGolf3Round.PlayerValuePair[] memory) {
        address[] memory players = roundInit.players;
        uint256 numberOfHoles = roundInit.holePars.length;
        IGolf3Round.PlayerValuePair[] memory playerScorePair = new IGolf3Round.PlayerValuePair[](players.length);
        
        // get each player's total score
        for (uint256 i; i < players.length; ++i) {
            uint256 playerScore;
            for (uint256 j; j < numberOfHoles; ++j) {
                playerScore += _scores[i*numberOfHoles + j];
            }
            playerScorePair[i].player = players[i];
            playerScorePair[i].value = playerScore;
        }

        // sort players by score
        for (uint256 i; i < players.length - 1; ++i) {
            uint256 minIndex = i;
            uint256 minValue = playerScorePair[i].value;
            for (uint256 j = i+1; j < players.length; ++j) {
                if (playerScorePair[j].value < minValue) {
                    minIndex = j;
                    minValue = playerScorePair[j].value;
                }
            }
            if (minIndex != i) {
                IGolf3Round.PlayerValuePair memory tempPair = playerScorePair[i];
                playerScorePair[i] = playerScorePair[minIndex];
                playerScorePair[minIndex] = tempPair;
            }
        }

        return (playerScorePair);

    }

    /**
     * @dev calculate money round payout per player and move funds to claimable mapping for that player
     * @param _playerScorePair struct of player with their respective score, MUST be sorted scores low to high
     */
    function _processMoneyRoundPayout(IGolf3Round.PlayerValuePair[] memory _playerScorePair) internal roundIsClosed {
        uint256[] memory payoutPercent = roundInit.payoutPercent;
        uint256 payoutLength = payoutPercent.length;
        uint256 playerLastIndex = _playerScorePair.length - 1;

        // loop through each payout
        // start with payout 0, player 0
        // if there is a tie with the next player, increment the playerTiedCount, add the payout percent to accumulate, check the next player
        // if there is no tie with the next player, all previously tied players share the accumulated payout percentage
        // if it reaches the last player, payout accumulated
        uint256 totalPaidOut;
        uint256 playerIndex;
        for (uint256 payoutIndex; payoutIndex < payoutLength; ++payoutIndex) {
            uint256 accumPercent = payoutPercent[payoutIndex];
            uint256 playersTiedCount = 1;
            // calculate player tie count and accumulated percentage payout for the tie count
            // if we are here and the player index is the last player, they must be last and recieve the last payout percentage
            if (playerIndex < playerLastIndex) {
                while (_playerScorePair[playerIndex].value == _playerScorePair[playerIndex + 1].value) {
                    // increment the number of players to be paid out with this accumulated percent
                    ++playersTiedCount;

                    // if any payout percentage is left add it to the accumulated
                    // any further ties are possible to increase the tie count but not the accumulated payout percent
                    ++payoutIndex;
                    if (payoutIndex < payoutLength) {
                        accumPercent += payoutPercent[payoutIndex];
                    }

                    ++playerIndex;
                    if (playerIndex == playerLastIndex) {
                        break;
                    }
                }
            }

            // payout players with the current accumulated payout percent
            // playersTiedCount is always >0, the number reflects how many players to pay out at this point with the accumulated percent
            uint256 payout = moneyRoundTotal * accumPercent / BASE / playersTiedCount;
            for (uint256 i; i < playersTiedCount; ++i) {
                amountClaimable[_playerScorePair[playerIndex - i].player] += payout;
                totalPaidOut += payout;
                emit MoneyRoundWinnings(address(this), _playerScorePair[playerIndex - i].player, payout, block.timestamp);
            }

            ++playerIndex;
            if (playerIndex > playerLastIndex) {
                break;
            }
        }

        moneyRoundTotal -= totalPaidOut;
    }

    /**
     * @dev calculate payout from skins total per player and move funds to claimable mapping for that player
     * @param _scores array of players scores
     * NOTICE _scores intended to be in form _scores[i] where player = i / #_of_holes and hole = i % #_of_holes
     */
    function _processSkinsRoundPayout(uint8[] memory _scores) internal roundIsClosed {
        uint256 holeCount = roundInit.holePars.length;
        uint256 playerCount = roundInit.players.length;
        address[] memory players = roundInit.players;
        
        // get amount of skins won per player
        // player must have paid the skins buy in
        uint256 skinPushCount = 1;
        uint256[] memory skinWinCount = new uint256[](playerCount);
        uint256 skinWinner;
        for (uint256 i; i < holeCount; ++i) {
            bool pushSkin;
            uint256 lowestScore;
            for (uint256 j; j < playerCount; ++j) {
                if ((_scores[(holeCount * j) + i] < lowestScore) && (paidSkinsBuyIn[players[j]])) {
                    lowestScore = _scores[(holeCount * j) + i];
                    skinWinner = j;
                    pushSkin = false;
                } else {
                    pushSkin = true;
                }
            }
            if (pushSkin) {
                ++skinPushCount;
            } else {
                skinWinCount[skinWinner] += skinPushCount;
                skinPushCount = 1;
            }
        }

        // disperse skins payout to be claimed by players
        uint256 totalPaidOut;
        for (uint256 i; i < playerCount; ++i) {
            if (skinWinCount[i] > 0) {
                uint256 payout = skinsRoundTotal * skinWinCount[i] / holeCount;
                amountClaimable[players[i]] += payout;
                totalPaidOut += payout;
                emit SkinsWinnings(address(this), players[i], payout, block.timestamp);
            }
        }
        skinsRoundTotal -= totalPaidOut;
    }

    function _saveScorecard(uint8[] calldata _scores) internal roundIsClosed {

    }

    /**
     * @notice deposit buy in tokens
     * @dev donate buyInTokens to the payout of a moneyRound
     * @param _buyInAmount amount to deposit to buy into the money round
     * @param _skinsBuyInAmount amount to deposit to buy into the skins round
     */
    function depositBuyIn(uint256 _buyInAmount, uint256 _skinsBuyInAmount) external roundIsOpen {
        address buyInToken = roundInit.buyInToken;
        require(address(buyInToken) != address(0), "token address null");
        require(isPlayer[msg.sender], "not in round");
        require(_buyInAmount + _skinsBuyInAmount > 0, "no amount input");
        require(IERC20(buyInToken).balanceOf(msg.sender) >= _buyInAmount + _skinsBuyInAmount, "not enough balance");

        if (_buyInAmount > 0) {
            require(moneyRound, "not moneyRound");
            require(_buyInAmount >= roundInit.buyInAmount, "not enough buy in");
            require(!paidBuyIn[msg.sender], "already paid");

            paidBuyIn[msg.sender] = true;

            uint256 balanceBeforeTransfer = IERC20(buyInToken).balanceOf(address(this));
            IERC20(buyInToken).safeTransferFrom(msg.sender, address(this), _buyInAmount);
            uint256 balanceAfterTransfer = IERC20(buyInToken).balanceOf(address(this));
            uint256 depositAmount = balanceAfterTransfer - balanceBeforeTransfer;

            moneyRoundTotal += depositAmount;
            amountDeposited[msg.sender] += depositAmount;

            emit DepositedBuyIn(address(this), msg.sender, depositAmount, moneyRoundTotal, block.timestamp);
        }

        if (_skinsBuyInAmount > 0) {
            require(skinsRound, "not skinsRound");
            require(_skinsBuyInAmount >= roundInit.skinsBuyInAmount, "not enough skins buy in");
            require(!paidSkinsBuyIn[msg.sender], "already paid skins");

            paidSkinsBuyIn[msg.sender] = true;

            uint256 balanceBeforeTransfer = IERC20(buyInToken).balanceOf(address(this));
            IERC20(buyInToken).safeTransferFrom(msg.sender, address(this), _skinsBuyInAmount);
            uint256 balanceAfterTransfer = IERC20(buyInToken).balanceOf(address(this));
            uint256 depositAmount = balanceAfterTransfer - balanceBeforeTransfer;

            skinsRoundTotal += depositAmount;
            amountDeposited[msg.sender] += depositAmount;

            emit DepositSkinsBuyIn(address(this), msg.sender, depositAmount, skinsRoundTotal, block.timestamp);
        }
    }

    /**
     * @notice donate `_donateAmount` to payout
     * @dev donate buyInTokens to the payout of a moneyRound
     * @param _donateAmount amount of buyInTokens to send to the contract
     * NOTICE does not count towards paidBuyIn
     */
    function donate(uint256 _donateAmount) external roundIsOpen {
        require(moneyRound, "not moneyRound");
        require(_donateAmount > 0, "no donate amount");

        address buyInToken = roundInit.buyInToken;
        require(IERC20(buyInToken).balanceOf(msg.sender) >= _donateAmount, "not enough balance");
        
        uint256 balanceBeforeTransfer = IERC20(buyInToken).balanceOf(address(this));
        IERC20(buyInToken).safeTransferFrom(msg.sender, address(this), _donateAmount);
        uint256 balanceAfterTransfer = IERC20(buyInToken).balanceOf(address(this));
        uint256 depositAmount = balanceAfterTransfer - balanceBeforeTransfer;

        moneyRoundTotal += depositAmount;
        amountDeposited[msg.sender] += depositAmount;

        emit Donated(address(this), msg.sender, _donateAmount, moneyRoundTotal, block.timestamp);
    }

    /**
     * @dev user can withdraw their deposited funds if the round is not closed within a timeout window
     */
    function withdrawDeposit() external roundTimeout {
        address buyInToken = roundInit.buyInToken;
        uint256 depositAmount = amountDeposited[msg.sender];
        require(depositAmount > 0, "no balance");

        moneyRoundTotal -= depositAmount;
        amountDeposited[msg.sender] = 0;
        IERC20(buyInToken).safeTransfer(msg.sender, depositAmount);

        emit Withdraw(address(this), msg.sender, depositAmount, block.timestamp);
    }

    function claim() public roundIsClosed {
        require(isPlayer[msg.sender], "not in round");
        uint256 claimAmount = amountClaimable[msg.sender];
        require(claimAmount > 0, "no claim amount");
        amountClaimable[msg.sender] = 0;
        address buyInToken = roundInit.buyInToken;
        IERC20(buyInToken).safeTransfer(msg.sender, claimAmount);
        emit Claim(address(this), msg.sender, claimAmount, block.timestamp);
    }

    /**
     * @dev emits event UpdateScoresAll holding all players' scores, for use in frontend
     * @param _scores array of players scores
     * NOTICE _scores must be of length #_of_players * #_of_holes
     * NOTICE _scores intended to be in form _scores[i] where player = i / #_of_holes and hole = i % #_of_holes
     */
    function updateScoresAll(uint8[] calldata _scores) external onlyAdmin roundIsOpen {
        require(_scores.length != roundInit.players.length * roundInit.holePars.length, "invalid score array");
        emit UpdateScoresAll(address(this), _scores, block.timestamp);
    }

    /**
     * @dev emits event UpdateScoresPlayer holding all hole scores for this player, for use in frontend
     * @param _scores array of players scores
     * @param _player player address for which to update scores
     * NOTICE _scores must be of length #_of_holes
     * NOTICE _scores intended to be in form _scores[i] where i = hole
     */
    function updateScoresPlayer(uint8[] calldata _scores, address _player) external roundIsOpen {
        require(msg.sender == _player || msg.sender == admin, "not player or admin");
        require(_scores.length != roundInit.holePars.length, "invalid score array");
        emit UpdateScoresPlayer(address(this), _player, _scores, block.timestamp);
    }

    /**
     * @dev emits event UpdateScoresPlayer holding all hole scores for this player, for use in frontend
     * @param _score new score
     * @param _hole hole for which to update score
     * @param _player player address for which to update scores
     * NOTICE _hole must be less than the total amount of holes
     */
    function updateScoresSingle(uint8 _score, uint8 _hole, address _player) external roundIsOpen {
        require(msg.sender == _player || msg.sender == admin, "not player or admin");
        require(_hole < roundInit.holePars.length, "invalid hole");
        emit UpdateScoresSingle(address(this), _player, _score, _hole, block.timestamp);
    }

    function getPlayers() external view returns (address[] memory) {
        return (roundInit.players);
    }

    function getHolePars() external view returns (uint8[] memory) {
        return (roundInit.holePars);
    }

    function getPayoutPercent() external view returns (uint256[] memory) {
        return (roundInit.payoutPercent);
    }

    modifier initOnce() {
        require(!calledInitialize, "already initialized");
        calledInitialize = true;
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    modifier roundIsOpen() {
        require(!roundClosed, "round closed");
        require(block.timestamp <= startTime + roundInit.roundTimeoutPeriod, "round timed out");
        _;
    }

    modifier roundIsClosed() {
        require(roundClosed, "round still open");
        _;
    }

    modifier roundTimeout() {
        require(!roundClosed, "round closed");
        require(block.timestamp > startTime + roundInit.roundTimeoutPeriod, "no timeout");
        _;
    }
}