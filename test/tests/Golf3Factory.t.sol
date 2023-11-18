// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../../lib/forge-std/src/Test.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {Golf3Round} from "../../src/Golf3Round.sol";
import {IGolf3Round} from "../../src/interfaces/IGolf3Round.sol";
import {Golf3Factory} from "../../src/Golf3Factory.sol";

contract Golf3FactoryTest is Test {
    uint256 constant BASE = 10000;

    uint256 constant MIN_TIMEOUT = 60 minutes;
    uint256 constant MAX_TIMEOUT = 14 days;
    uint8 constant MAX_PLAYER_COUNT = 8;
    uint8 constant MAX_HOLE_COUNT = 72;

    address constant testAdmin = address(0x1000);

    Golf3Round public golf3Round;
    Golf3Factory public golf3Factory;
    MockERC20 public buyInToken;

    address[] testPlayers = [
        address(0x01),
        address(0x02),
        address(0x03),
        address(0x04),
        address(0x05),
        address(0x06),
        address(0x07),
        address(0x08)
    ];

    function setUp() public {
        golf3Round = new Golf3Round();
        golf3Factory = new Golf3Factory(address(golf3Round));
        buyInToken = new MockERC20("MockToken", "MT");

        assertEq(Golf3Factory(golf3Factory).ROUND_LOGIC(), address(golf3Round));
    }

    /*////////////////////////////////////////////////
                No Money Round / No Skins
    ////////////////////////////////////////////////*/

    function testFuzzCreateRoundNoMoneyNoSkins(
        uint8 _playerCount,
        uint8 _holeCount,
        uint256 _roundTimeoutPeriod
    ) public {
        _playerCount = _playerCount % (MAX_PLAYER_COUNT + 1);
        vm.assume(_playerCount > 0);
        vm.assume(_playerCount <= MAX_PLAYER_COUNT);
        _holeCount = _holeCount % (MAX_HOLE_COUNT + 1);
        vm.assume(_holeCount > 0);
        vm.assume(_holeCount <= MAX_HOLE_COUNT);
        _roundTimeoutPeriod = _roundTimeoutPeriod % (MAX_TIMEOUT + 1);
        vm.assume(_roundTimeoutPeriod >= MIN_TIMEOUT);
        vm.assume(_roundTimeoutPeriod <= MAX_TIMEOUT);

        address[] memory players = new address[](_playerCount);
        for (uint i; i < _playerCount; ++i) {
            players[i] = testPlayers[i];
        }

        uint8[] memory holePars = new uint8[](_holeCount);
        for (uint i; i < _holeCount; ++i) {
            holePars[i] = 3;
        }

        uint256[] memory payoutPercent;

        IGolf3Round.RoundInit memory roundInit;
        roundInit = IGolf3Round.RoundInit({
            courseName: "testCourse",
            players: players,
            holePars: holePars,
            buyInToken: address(0),
            buyInAmount: 0,
            skinsBuyInAmount: 0,
            payoutPercent: payoutPercent,
            roundTimeoutPeriod: _roundTimeoutPeriod
        });

        vm.prank(testAdmin);
        address roundAddress = Golf3Factory(golf3Factory).createRound(roundInit);

        // check round init
        string memory testString;
        address testAddress;
        uint256 testUint256;
        (testString, testAddress, testUint256,,) = Golf3Round(roundAddress).roundInit();
        assertEq(testString, "testCourse");
        assertEq(testAddress, address(0));
        assertEq(testUint256, 0);
        (,,,testUint256,) = Golf3Round(roundAddress).roundInit();
        assertEq(testUint256, 0);
        (,,,,testUint256) = Golf3Round(roundAddress).roundInit();
        assertEq(testUint256, _roundTimeoutPeriod);
        address[] memory getPlayers = Golf3Round(roundAddress).getPlayers();
        assertEq(getPlayers.length, _playerCount);
        for (uint i; i < _playerCount; ++i) {
            assertEq(getPlayers[i], testPlayers[i]);
        }
        uint8[] memory getHolePars = Golf3Round(roundAddress).getHolePars();
        assertEq(getHolePars.length, _holeCount);
        for (uint i; i < _holeCount; ++i) {
            assertEq(getHolePars[i], holePars[i]);
        }
        uint256[] memory getPayoutPercent = Golf3Round(roundAddress).getPayoutPercent();
        assertEq(getPayoutPercent.length, 0);

        // check contract storage
        assertEq(Golf3Round(roundAddress).admin(), testAdmin);
        assertEq(Golf3Round(roundAddress).startTime(), block.timestamp);
        assertEq(Golf3Round(roundAddress).moneyRoundTotal(), 0);
        assertEq(Golf3Round(roundAddress).skinsRoundTotal(), 0);
        assertTrue(!Golf3Round(roundAddress).roundClosed());
        assertTrue(!Golf3Round(roundAddress).moneyRound());
        assertTrue(!Golf3Round(roundAddress).skinsRound());
        for (uint i; i < _playerCount; ++i) {
            assertTrue(Golf3Round(roundAddress).isPlayer(testPlayers[i]));
            assertTrue(!Golf3Round(roundAddress).paidBuyIn(testPlayers[i]));
            assertTrue(!Golf3Round(roundAddress).paidSkinsBuyIn(testPlayers[i]));
            assertEq(Golf3Round(roundAddress).amountDeposited(testPlayers[i]), 0);
            assertEq(Golf3Round(roundAddress).amountClaimable(testPlayers[i]), 0);
        }
    }

    /*////////////////////////////////////////////////
                No Money Round / No Skins
                Round Initialization Reverts
    ////////////////////////////////////////////////*/

    function testRevertZeroPlayers() public {
        address[] memory players;
        uint8[] memory holePars;
        uint256[] memory payoutPercent;

        IGolf3Round.RoundInit memory roundInit;
        roundInit = IGolf3Round.RoundInit({
            courseName: "testCourse",
            players: players,
            holePars: holePars,
            buyInToken: address(0),
            buyInAmount: 0,
            skinsBuyInAmount: 0,
            payoutPercent: payoutPercent,
            roundTimeoutPeriod: 2 days
        });

        vm.prank(testAdmin);
        vm.expectRevert("player amount must be nonzero");
        Golf3Factory(golf3Factory).createRound(roundInit);
    }

    function testRevertTooManyPlayers(uint256 _playerCount) public {
        vm.assume(_playerCount > MAX_PLAYER_COUNT);
        vm.assume(_playerCount < 100);

        address[] memory players = new address[](_playerCount);
        uint8[] memory holePars;
        uint256[] memory payoutPercent;

        IGolf3Round.RoundInit memory roundInit;
        roundInit = IGolf3Round.RoundInit({
            courseName: "testCourse",
            players: players,
            holePars: holePars,
            buyInToken: address(0),
            buyInAmount: 0,
            skinsBuyInAmount: 0,
            payoutPercent: payoutPercent,
            roundTimeoutPeriod: 2 days
        });

        vm.prank(testAdmin);
        vm.expectRevert("player amount exceeds max");
        Golf3Factory(golf3Factory).createRound(roundInit);
    }

    function testRevertZeroHoles() public {
        address[] memory players = new address[](2);
        uint8[] memory holePars;
        uint256[] memory payoutPercent;

        IGolf3Round.RoundInit memory roundInit;
        roundInit = IGolf3Round.RoundInit({
            courseName: "testCourse",
            players: players,
            holePars: holePars,
            buyInToken: address(0),
            buyInAmount: 0,
            skinsBuyInAmount: 0,
            payoutPercent: payoutPercent,
            roundTimeoutPeriod: 2 days
        });

        vm.prank(testAdmin);
        vm.expectRevert("holePars length must be nonzero");
        Golf3Factory(golf3Factory).createRound(roundInit);
    }

    function testRevertTooManyHoles(uint256 _holeCount) public {
        vm.assume(_holeCount > MAX_HOLE_COUNT);
        vm.assume(_holeCount < 200);

        address[] memory players = new address[](MAX_PLAYER_COUNT);
        uint8[] memory holePars = new uint8[](_holeCount);
        uint256[] memory payoutPercent;

        IGolf3Round.RoundInit memory roundInit;
        roundInit = IGolf3Round.RoundInit({
            courseName: "testCourse",
            players: players,
            holePars: holePars,
            buyInToken: address(0),
            buyInAmount: 0,
            skinsBuyInAmount: 0,
            payoutPercent: payoutPercent,
            roundTimeoutPeriod: 2 days
        });

        vm.prank(testAdmin);
        vm.expectRevert("holePars exceeds max length");
        Golf3Factory(golf3Factory).createRound(roundInit);
    }

    function testRevertSmallTimeout(uint256 _roundTimeoutPeriod) public {
        vm.assume(_roundTimeoutPeriod < MIN_TIMEOUT);

        address[] memory players = new address[](MAX_PLAYER_COUNT);
        uint8[] memory holePars = new uint8[](MAX_HOLE_COUNT);
        uint256[] memory payoutPercent;

        IGolf3Round.RoundInit memory roundInit;
        roundInit = IGolf3Round.RoundInit({
            courseName: "testCourse",
            players: players,
            holePars: holePars,
            buyInToken: address(0),
            buyInAmount: 0,
            skinsBuyInAmount: 0,
            payoutPercent: payoutPercent,
            roundTimeoutPeriod: _roundTimeoutPeriod
        });

        vm.prank(testAdmin);
        vm.expectRevert("timeout period less than min");
        Golf3Factory(golf3Factory).createRound(roundInit);
    }

    function testRevertBigTimeout(uint256 _roundTimeoutPeriod) public {
        vm.assume(_roundTimeoutPeriod > MAX_TIMEOUT);

        address[] memory players = new address[](MAX_PLAYER_COUNT);
        uint8[] memory holePars = new uint8[](MAX_HOLE_COUNT);
        uint256[] memory payoutPercent;

        IGolf3Round.RoundInit memory roundInit;
        roundInit = IGolf3Round.RoundInit({
            courseName: "testCourse",
            players: players,
            holePars: holePars,
            buyInToken: address(0),
            buyInAmount: 0,
            skinsBuyInAmount: 0,
            payoutPercent: payoutPercent,
            roundTimeoutPeriod: _roundTimeoutPeriod
        });

        vm.prank(testAdmin);
        vm.expectRevert("timeout period exceeds max");
        Golf3Factory(golf3Factory).createRound(roundInit);
    }

    function testRevertPlayerIncludedTwice(
        uint8 _playerCount,
        uint8 _holeCount,
        uint256 _roundTimeoutPeriod,
        uint8 _playerIndex
    ) public {
        _playerCount = _playerCount % (MAX_PLAYER_COUNT + 1);
        vm.assume(_playerCount > 1);
        vm.assume(_playerCount <= MAX_PLAYER_COUNT);
        _holeCount = _holeCount % (MAX_HOLE_COUNT + 1);
        vm.assume(_holeCount > 0);
        vm.assume(_holeCount <= MAX_HOLE_COUNT);
        _roundTimeoutPeriod = _roundTimeoutPeriod % (MAX_TIMEOUT + 1);
        vm.assume(_roundTimeoutPeriod >= MIN_TIMEOUT);
        vm.assume(_roundTimeoutPeriod <= MAX_TIMEOUT);
        _playerIndex = _playerIndex % MAX_PLAYER_COUNT;

        address[] memory players = new address[](_playerCount);
        for (uint i; i < _playerCount; ++i) {
            players[i] = testPlayers[0];
        }

        uint8[] memory holePars = new uint8[](_holeCount);
        for (uint i; i < _holeCount; ++i) {
            holePars[i] = 3;
        }

        uint256[] memory payoutPercent;

        IGolf3Round.RoundInit memory roundInit;
        roundInit = IGolf3Round.RoundInit({
            courseName: "testCourse",
            players: players,
            holePars: holePars,
            buyInToken: address(0),
            buyInAmount: 0,
            skinsBuyInAmount: 0,
            payoutPercent: payoutPercent,
            roundTimeoutPeriod: _roundTimeoutPeriod
        });

        vm.prank(testAdmin);
        vm.expectRevert("player included twice");
        Golf3Factory(golf3Factory).createRound(roundInit);
    }

    /*////////////////////////////////////////////////
                        Money Round
    ////////////////////////////////////////////////*/

    function testFuzzCreateMoneyRound(
        uint8 _playerCount,
        uint8 _holeCount,
        uint256 _buyInAmount,
        uint256 _payoutArraySize
    ) public {
        _playerCount = _playerCount % (MAX_PLAYER_COUNT + 1);
        vm.assume(_playerCount > 1);
        vm.assume(_playerCount <= MAX_PLAYER_COUNT);
        _holeCount = _holeCount % (MAX_HOLE_COUNT + 1);
        vm.assume(_holeCount > 0);
        vm.assume(_holeCount <= MAX_HOLE_COUNT);
        vm.assume(_buyInAmount > 0);
        vm.assume(_payoutArraySize > 0);
        vm.assume(_payoutArraySize <= _playerCount);

        address[] memory players = new address[](_playerCount);
        for (uint i; i < _playerCount; ++i) {
            players[i] = testPlayers[i];
        }

        uint8[] memory holePars = new uint8[](_holeCount);
        for (uint i; i < _holeCount; ++i) {
            holePars[i] = 3;
        }

        uint256[] memory payoutPercent = new uint256[](_payoutArraySize);
        for (uint i; i < _payoutArraySize; ++i) {
            payoutPercent[i] = BASE / _payoutArraySize;
            if (i + 1 == _payoutArraySize) {
                payoutPercent[i] += BASE % _payoutArraySize;
            }
        }

        IGolf3Round.RoundInit memory roundInit;
        roundInit = IGolf3Round.RoundInit({
            courseName: "testCourse",
            players: players,
            holePars: holePars,
            buyInToken: address(buyInToken),
            buyInAmount: _buyInAmount,
            skinsBuyInAmount: 0,
            payoutPercent: payoutPercent,
            roundTimeoutPeriod: MIN_TIMEOUT
        });

        vm.prank(testAdmin);
        address roundAddress = Golf3Factory(golf3Factory).createRound(roundInit);

        // check round init
        string memory testString;
        address testAddress;
        uint256 testUint256;
        (testString, testAddress, testUint256,,) = Golf3Round(roundAddress).roundInit();
        assertEq(testString, "testCourse");
        assertEq(testAddress, address(buyInToken));
        assertEq(testUint256, _buyInAmount);
        (,,,testUint256,) = Golf3Round(roundAddress).roundInit();
        assertEq(testUint256, 0);
        (,,,,testUint256) = Golf3Round(roundAddress).roundInit();
        assertEq(testUint256, MIN_TIMEOUT);
        address[] memory getPlayers = Golf3Round(roundAddress).getPlayers();
        assertEq(getPlayers.length, _playerCount);
        for (uint i; i < _playerCount; ++i) {
            assertEq(getPlayers[i], testPlayers[i]);
        }
        uint8[] memory getHolePars = Golf3Round(roundAddress).getHolePars();
        assertEq(getHolePars.length, _holeCount);
        for (uint i; i < _holeCount; ++i) {
            assertEq(getHolePars[i], holePars[i]);
        }
        uint256[] memory getPayoutPercent = Golf3Round(roundAddress).getPayoutPercent();
        assertEq(getPayoutPercent.length, _payoutArraySize);

        // check contract storage
        assertEq(Golf3Round(roundAddress).admin(), testAdmin);
        assertEq(Golf3Round(roundAddress).startTime(), block.timestamp);
        assertEq(Golf3Round(roundAddress).moneyRoundTotal(), 0);
        assertEq(Golf3Round(roundAddress).skinsRoundTotal(), 0);
        assertTrue(!Golf3Round(roundAddress).roundClosed());
        assertTrue(Golf3Round(roundAddress).moneyRound());
        assertTrue(!Golf3Round(roundAddress).skinsRound());
        for (uint i; i < _playerCount; ++i) {
            assertTrue(Golf3Round(roundAddress).isPlayer(testPlayers[i]));
            assertTrue(!Golf3Round(roundAddress).paidBuyIn(testPlayers[i]));
            assertTrue(!Golf3Round(roundAddress).paidSkinsBuyIn(testPlayers[i]));
            assertEq(Golf3Round(roundAddress).amountDeposited(testPlayers[i]), 0);
            assertEq(Golf3Round(roundAddress).amountClaimable(testPlayers[i]), 0);
        }
    }

    /*////////////////////////////////////////////////
                        Money Round
                Round Initialization Reverts
    ////////////////////////////////////////////////*/

    function testRevertMoneyRoundNoToken(uint256 _buyInTokenAmount) public {
        vm.assume(_buyInTokenAmount > 0);

        address[] memory players = new address[](MAX_PLAYER_COUNT);
        for (uint i; i < players.length; ++i) {
            players[i] = testPlayers[0];
        }

        uint8[] memory holePars = new uint8[](MAX_HOLE_COUNT);
        for (uint i; i < holePars.length; ++i) {
            holePars[i] = 3;
        }

        uint256[] memory payoutPercent;

        IGolf3Round.RoundInit memory roundInit;
        roundInit = IGolf3Round.RoundInit({
            courseName: "testCourse",
            players: players,
            holePars: holePars,
            buyInToken: address(0),
            buyInAmount: _buyInTokenAmount,
            skinsBuyInAmount: 0,
            payoutPercent: payoutPercent,
            roundTimeoutPeriod: 2 days
        });

        vm.prank(testAdmin);
        vm.expectRevert("no buy in token");
        Golf3Factory(golf3Factory).createRound(roundInit);
    }

    function testRevertMoneyRoundNotEnoughPlayers() public {
        address[] memory players = new address[](1);
        for (uint i; i < players.length; ++i) {
            players[i] = testPlayers[0];
        }

        uint8[] memory holePars = new uint8[](MAX_HOLE_COUNT);
        for (uint i; i < holePars.length; ++i) {
            holePars[i] = 3;
        }

        uint256[] memory payoutPercent;

        IGolf3Round.RoundInit memory roundInit;
        roundInit = IGolf3Round.RoundInit({
            courseName: "testCourse",
            players: players,
            holePars: holePars,
            buyInToken: address(buyInToken),
            buyInAmount: 1e18,
            skinsBuyInAmount: 0,
            payoutPercent: payoutPercent,
            roundTimeoutPeriod: 2 days
        });

        vm.prank(testAdmin);
        vm.expectRevert("not enough players");
        Golf3Factory(golf3Factory).createRound(roundInit);
    }

    function testRevertMoneyRoundNoPayout(uint256 _buyInTokenAmount) public {
        vm.assume(_buyInTokenAmount > 0);

        address[] memory players = new address[](MAX_PLAYER_COUNT);
        for (uint i; i < players.length; ++i) {
            players[i] = testPlayers[i];
        }

        uint8[] memory holePars = new uint8[](MAX_HOLE_COUNT);
        for (uint i; i < holePars.length; ++i) {
            holePars[i] = 3;
        }

        uint256[] memory payoutPercent;

        IGolf3Round.RoundInit memory roundInit;
        roundInit = IGolf3Round.RoundInit({
            courseName: "testCourse",
            players: players,
            holePars: holePars,
            buyInToken: address(buyInToken),
            buyInAmount: _buyInTokenAmount,
            skinsBuyInAmount: 0,
            payoutPercent: payoutPercent,
            roundTimeoutPeriod: 2 days
        });

        vm.prank(testAdmin);
        vm.expectRevert("no payoutPercent");
        Golf3Factory(golf3Factory).createRound(roundInit);
    }

    function testRevertMoneyRoundInvalidPayoutLength(uint256 _buyInTokenAmount, uint256 _payoutArraySize) public {
        vm.assume(_buyInTokenAmount > 0);
        vm.assume(_payoutArraySize > MAX_PLAYER_COUNT);
        vm.assume(_payoutArraySize < 200);

        address[] memory players = new address[](MAX_PLAYER_COUNT);
        for (uint i; i < players.length; ++i) {
            players[i] = testPlayers[i];
        }

        uint8[] memory holePars = new uint8[](MAX_HOLE_COUNT);
        for (uint i; i < holePars.length; ++i) {
            holePars[i] = 3;
        }

        uint256[] memory payoutPercent = new uint256[](_payoutArraySize);

        IGolf3Round.RoundInit memory roundInit;
        roundInit = IGolf3Round.RoundInit({
            courseName: "testCourse",
            players: players,
            holePars: holePars,
            buyInToken: address(buyInToken),
            buyInAmount: _buyInTokenAmount,
            skinsBuyInAmount: 0,
            payoutPercent: payoutPercent,
            roundTimeoutPeriod: 2 days
        });

        vm.prank(testAdmin);
        vm.expectRevert("invalid payoutPercent length");
        Golf3Factory(golf3Factory).createRound(roundInit);
    }

    function testRevertMoneyRoundInvalidPayoutTotal(uint256 _buyInTokenAmount, uint256 _payoutArraySize) public {
        vm.assume(_buyInTokenAmount > 0);
        vm.assume(_payoutArraySize > 0);
        vm.assume(_payoutArraySize <= MAX_PLAYER_COUNT);

        address[] memory players = new address[](MAX_PLAYER_COUNT);
        for (uint256 i; i < players.length; ++i) {
            players[i] = testPlayers[i];
        }

        uint8[] memory holePars = new uint8[](MAX_HOLE_COUNT);
        for (uint256 i; i < holePars.length; ++i) {
            holePars[i] = 3;
        }

        // payout adds up below BASE
        uint256[] memory payoutPercent = new uint256[](_payoutArraySize);
        for (uint256 i; i < _payoutArraySize; ++i) {
            payoutPercent[i] = 10;
        }

        IGolf3Round.RoundInit memory roundInit;
        roundInit = IGolf3Round.RoundInit({
            courseName: "testCourse",
            players: players,
            holePars: holePars,
            buyInToken: address(buyInToken),
            buyInAmount: _buyInTokenAmount,
            skinsBuyInAmount: _buyInTokenAmount,
            payoutPercent: payoutPercent,
            roundTimeoutPeriod: 2 days
        });

        vm.prank(testAdmin);
        vm.expectRevert("invalid payoutPercent total");
        Golf3Factory(golf3Factory).createRound(roundInit);

        // payout adds up above BASE
        for (uint256 i; i < _payoutArraySize; ++i) {
            payoutPercent[i] = BASE + 1;
        }

        roundInit = IGolf3Round.RoundInit({
            courseName: "testCourse",
            players: players,
            holePars: holePars,
            buyInToken: address(buyInToken),
            buyInAmount: _buyInTokenAmount,
            skinsBuyInAmount: 0,
            payoutPercent: payoutPercent,
            roundTimeoutPeriod: 2 days
        });

        vm.prank(testAdmin);
        vm.expectRevert("invalid payoutPercent total");
        Golf3Factory(golf3Factory).createRound(roundInit);
    }

    /*////////////////////////////////////////////////
                        Skins Round
    ////////////////////////////////////////////////*/

    function testFuzzCreateRoundSkins(
        uint8 _playerCount,
        uint8 _holeCount,
        uint256 _roundTimeoutPeriod,
        uint256 _skinsBuyInTokenAmount
    ) public {
        _playerCount = _playerCount % (MAX_PLAYER_COUNT + 1);
        vm.assume(_playerCount > 1);
        vm.assume(_playerCount <= MAX_PLAYER_COUNT);
        _holeCount = _holeCount % (MAX_HOLE_COUNT + 1);
        vm.assume(_holeCount > 0);
        vm.assume(_holeCount <= MAX_HOLE_COUNT);
        _roundTimeoutPeriod = _roundTimeoutPeriod % (MAX_TIMEOUT + 1);
        vm.assume(_roundTimeoutPeriod >= MIN_TIMEOUT);
        vm.assume(_roundTimeoutPeriod <= MAX_TIMEOUT);
        vm.assume(_skinsBuyInTokenAmount > 0);

        address[] memory players = new address[](_playerCount);
        for (uint i; i < _playerCount; ++i) {
            players[i] = testPlayers[i];
        }

        uint8[] memory holePars = new uint8[](_holeCount);
        for (uint i; i < _holeCount; ++i) {
            holePars[i] = 3;
        }

        uint256[] memory payoutPercent;

        IGolf3Round.RoundInit memory roundInit;
        roundInit = IGolf3Round.RoundInit({
            courseName: "testCourse",
            players: players,
            holePars: holePars,
            buyInToken: address(buyInToken),
            buyInAmount: 0,
            skinsBuyInAmount: _skinsBuyInTokenAmount,
            payoutPercent: payoutPercent,
            roundTimeoutPeriod: _roundTimeoutPeriod
        });

        vm.prank(testAdmin);
        address roundAddress = Golf3Factory(golf3Factory).createRound(roundInit);

        // check round init
        string memory testString;
        address testAddress;
        uint256 testUint256;
        (testString, testAddress, testUint256,,) = Golf3Round(roundAddress).roundInit();
        assertEq(testString, "testCourse");
        assertEq(testAddress, address(buyInToken));
        assertEq(testUint256, 0);
        (,,,testUint256,) = Golf3Round(roundAddress).roundInit();
        assertEq(testUint256, _skinsBuyInTokenAmount);
        (,,,,testUint256) = Golf3Round(roundAddress).roundInit();
        assertEq(testUint256, _roundTimeoutPeriod);
        address[] memory getPlayers = Golf3Round(roundAddress).getPlayers();
        assertEq(getPlayers.length, _playerCount);
        for (uint i; i < _playerCount; ++i) {
            assertEq(getPlayers[i], testPlayers[i]);
        }
        uint8[] memory getHolePars = Golf3Round(roundAddress).getHolePars();
        assertEq(getHolePars.length, _holeCount);
        for (uint i; i < _holeCount; ++i) {
            assertEq(getHolePars[i], holePars[i]);
        }
        uint256[] memory getPayoutPercent = Golf3Round(roundAddress).getPayoutPercent();
        assertEq(getPayoutPercent.length, 0);

        // check contract storage
        assertEq(Golf3Round(roundAddress).admin(), testAdmin);
        assertEq(Golf3Round(roundAddress).startTime(), block.timestamp);
        assertEq(Golf3Round(roundAddress).moneyRoundTotal(), 0);
        assertEq(Golf3Round(roundAddress).skinsRoundTotal(), 0);
        assertTrue(!Golf3Round(roundAddress).roundClosed());
        assertTrue(!Golf3Round(roundAddress).moneyRound());
        assertTrue(Golf3Round(roundAddress).skinsRound());
        for (uint i; i < _playerCount; ++i) {
            assertTrue(Golf3Round(roundAddress).isPlayer(testPlayers[i]));
            assertTrue(!Golf3Round(roundAddress).paidBuyIn(testPlayers[i]));
            assertTrue(!Golf3Round(roundAddress).paidSkinsBuyIn(testPlayers[i]));
            assertEq(Golf3Round(roundAddress).amountDeposited(testPlayers[i]), 0);
            assertEq(Golf3Round(roundAddress).amountClaimable(testPlayers[i]), 0);
        }
    }

    /*////////////////////////////////////////////////
                        Skins Round
                Round Initialization Reverts
    ////////////////////////////////////////////////*/

    function testRevertSkinsRoundNoToken(uint256 _skinsBuyInTokenAmount) public {
        vm.assume(_skinsBuyInTokenAmount > 0);

        address[] memory players = new address[](MAX_PLAYER_COUNT);
        for (uint i; i < players.length; ++i) {
            players[i] = testPlayers[0];
        }

        uint8[] memory holePars = new uint8[](MAX_HOLE_COUNT);
        for (uint i; i < holePars.length; ++i) {
            holePars[i] = 3;
        }

        uint256[] memory payoutPercent;

        IGolf3Round.RoundInit memory roundInit;
        roundInit = IGolf3Round.RoundInit({
            courseName: "testCourse",
            players: players,
            holePars: holePars,
            buyInToken: address(0),
            buyInAmount: _skinsBuyInTokenAmount,
            skinsBuyInAmount: 0,
            payoutPercent: payoutPercent,
            roundTimeoutPeriod: 2 days
        });

        vm.prank(testAdmin);
        vm.expectRevert("no buy in token");
        Golf3Factory(golf3Factory).createRound(roundInit);
    }

    function testRevertSkinsRoundNotEnoughPlayers() public {
        address[] memory players = new address[](1);
        for (uint i; i < players.length; ++i) {
            players[i] = testPlayers[0];
        }

        uint8[] memory holePars = new uint8[](MAX_HOLE_COUNT);
        for (uint i; i < holePars.length; ++i) {
            holePars[i] = 3;
        }

        uint256[] memory payoutPercent;

        IGolf3Round.RoundInit memory roundInit;
        roundInit = IGolf3Round.RoundInit({
            courseName: "testCourse",
            players: players,
            holePars: holePars,
            buyInToken: address(buyInToken),
            buyInAmount: 0,
            skinsBuyInAmount: 1e18,
            payoutPercent: payoutPercent,
            roundTimeoutPeriod: 2 days
        });

        vm.prank(testAdmin);
        vm.expectRevert("not enough players");
        Golf3Factory(golf3Factory).createRound(roundInit);
    }

    /*////////////////////////////////////////////////
                    Skins & Money Round
    ////////////////////////////////////////////////*/

    function testFuzzCreateMoneyAndSkinsRound(
        uint8 _playerCount,
        uint8 _holeCount,
        uint256 _buyInAmount,
        uint256 _skinsBuyInTokenAmount,
        uint256 _payoutArraySize
    ) public {
        _playerCount = _playerCount % (MAX_PLAYER_COUNT + 1);
        vm.assume(_playerCount > 1);
        vm.assume(_playerCount <= MAX_PLAYER_COUNT);
        _holeCount = _holeCount % (MAX_HOLE_COUNT + 1);
        vm.assume(_holeCount > 0);
        vm.assume(_holeCount <= MAX_HOLE_COUNT);
        vm.assume(_buyInAmount > 0);
        vm.assume(_skinsBuyInTokenAmount > 0);
        vm.assume(_payoutArraySize > 0);
        vm.assume(_payoutArraySize <= _playerCount);

        address[] memory players = new address[](_playerCount);
        for (uint i; i < _playerCount; ++i) {
            players[i] = testPlayers[i];
        }

        uint8[] memory holePars = new uint8[](_holeCount);
        for (uint i; i < _holeCount; ++i) {
            holePars[i] = 3;
        }

        uint256[] memory payoutPercent = new uint256[](_payoutArraySize);
        for (uint i; i < _payoutArraySize; ++i) {
            payoutPercent[i] = BASE / _payoutArraySize;
            if (i + 1 == _payoutArraySize) {
                payoutPercent[i] += BASE % _payoutArraySize;
            }
        }

        IGolf3Round.RoundInit memory roundInit;
        roundInit = IGolf3Round.RoundInit({
            courseName: "testCourse",
            players: players,
            holePars: holePars,
            buyInToken: address(buyInToken),
            buyInAmount: _buyInAmount,
            skinsBuyInAmount: _skinsBuyInTokenAmount,
            payoutPercent: payoutPercent,
            roundTimeoutPeriod: MIN_TIMEOUT
        });

        vm.prank(testAdmin);
        address roundAddress = Golf3Factory(golf3Factory).createRound(roundInit);

        // check round init
        if (true) {
            string memory testString;
            address testAddress;
            uint256 testUint256;
            (testString, testAddress, testUint256,,) = Golf3Round(roundAddress).roundInit();
            assertEq(testString, "testCourse");
            assertEq(testAddress, address(buyInToken));
            assertEq(testUint256, _buyInAmount);
            (,,,testUint256,) = Golf3Round(roundAddress).roundInit();
            assertEq(testUint256, _skinsBuyInTokenAmount);
            (,,,,testUint256) = Golf3Round(roundAddress).roundInit();
            assertEq(testUint256, MIN_TIMEOUT);
            address[] memory getPlayers = Golf3Round(roundAddress).getPlayers();
            assertEq(getPlayers.length, _playerCount);
            for (uint i; i < _playerCount; ++i) {
                assertEq(getPlayers[i], testPlayers[i]);
            }
            uint8[] memory getHolePars = Golf3Round(roundAddress).getHolePars();
            assertEq(getHolePars.length, _holeCount);
            for (uint i; i < _holeCount; ++i) {
                assertEq(getHolePars[i], holePars[i]);
            }
            uint256[] memory getPayoutPercent = Golf3Round(roundAddress).getPayoutPercent();
            assertEq(getPayoutPercent.length, _payoutArraySize);
        }

        // check contract storage
        assertEq(Golf3Round(roundAddress).admin(), testAdmin);
        assertEq(Golf3Round(roundAddress).startTime(), block.timestamp);
        assertEq(Golf3Round(roundAddress).moneyRoundTotal(), 0);
        assertEq(Golf3Round(roundAddress).skinsRoundTotal(), 0);
        assertTrue(!Golf3Round(roundAddress).roundClosed());
        assertTrue(Golf3Round(roundAddress).moneyRound());
        assertTrue(Golf3Round(roundAddress).skinsRound());
        for (uint i; i < _playerCount; ++i) {
            assertTrue(Golf3Round(roundAddress).isPlayer(testPlayers[i]));
            assertTrue(!Golf3Round(roundAddress).paidBuyIn(testPlayers[i]));
            assertTrue(!Golf3Round(roundAddress).paidSkinsBuyIn(testPlayers[i]));
            assertEq(Golf3Round(roundAddress).amountDeposited(testPlayers[i]), 0);
            assertEq(Golf3Round(roundAddress).amountClaimable(testPlayers[i]), 0);
        }
    }

}
