// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {Golf3Round} from "../../src/Golf3Round.sol";
import {IGolf3Round} from "../../src/interfaces/IGolf3Round.sol";
import {Golf3Factory} from "../../src/Golf3Factory.sol";

contract Golf3RoundTest is Test {
    uint256 constant BASE = 10000;

    uint256 constant MIN_TIMEOUT = 60 minutes;
    uint256 constant MAX_TIMEOUT = 14 days;
    uint8 constant MAX_PLAYER_COUNT = 8;
    uint8 constant MAX_HOLE_COUNT = 72;

    address constant testAdmin = address(0x1000);

    Golf3Round public testGolf3Round;
    Golf3Factory public golf3Factory;
    MockERC20 public buyInToken;

    address roundAddressSolo;               // one player
    address roundAddressMulti;              // multiple players
    address roundAddressMoneyRound;         // money round
    address roundAddressSkinsRound;         // skins round
    address roundAddressMoneyAndSkins;      /// money and skins round

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
        testGolf3Round = new Golf3Round();
        golf3Factory = new Golf3Factory(address(testGolf3Round));
        buyInToken = new MockERC20("MockToken", "MT");

        assertEq(Golf3Factory(golf3Factory).ROUND_LOGIC(), address(testGolf3Round));

        vm.startPrank(testAdmin);

        // roundAddressSolo

        address[] memory players = new address[](1);
        players[0] = testAdmin;

        uint8[] memory holePars = new uint8[](9);
        holePars[0] = 4;
        holePars[1] = 4;
        holePars[2] = 5;
        holePars[3] = 3;
        holePars[4] = 4;
        holePars[5] = 4;
        holePars[6] = 3;
        holePars[7] = 4;
        holePars[8] = 5;

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
            roundTimeoutPeriod: 1 days
        });

        roundAddressSolo = Golf3Factory(golf3Factory).createRound(roundInit);

        // roundAddressMulti

        players = new address[](MAX_PLAYER_COUNT);
        players = testPlayers;

        holePars = new uint8[](3);
        holePars[0] = 3;
        holePars[1] = 3;
        holePars[2] = 3;

        roundInit = IGolf3Round.RoundInit({
            courseName: "testCourse",
            players: players,
            holePars: holePars,
            buyInToken: address(0),
            buyInAmount: 0,
            skinsBuyInAmount: 0,
            payoutPercent: payoutPercent,
            roundTimeoutPeriod: 1 days
        });

        roundAddressMulti = Golf3Factory(golf3Factory).createRound(roundInit);

        // roundAddressMoneyRound

        players = new address[](MAX_PLAYER_COUNT);
        players = testPlayers;

        holePars = new uint8[](6);
        holePars[0] = 3;
        holePars[1] = 4;
        holePars[2] = 4;
        holePars[3] = 5;
        holePars[4] = 4;
        holePars[5] = 4;

        payoutPercent = new uint256[](3);
        payoutPercent[0] = 5000;
        payoutPercent[1] = 3000;
        payoutPercent[2] = 2000;

        roundInit = IGolf3Round.RoundInit({
            courseName: "testCourse",
            players: players,
            holePars: holePars,
            buyInToken: address(buyInToken),
            buyInAmount: 5e18,
            skinsBuyInAmount: 0,
            payoutPercent: payoutPercent,
            roundTimeoutPeriod: 1 days
        });

        roundAddressMoneyRound = Golf3Factory(golf3Factory).createRound(roundInit);

        // roundAddressSkinsRound

        players = new address[](MAX_PLAYER_COUNT);
        players = testPlayers;

        holePars = new uint8[](6);
        holePars[0] = 3;
        holePars[1] = 4;
        holePars[2] = 4;
        holePars[3] = 5;
        holePars[4] = 4;
        holePars[5] = 4;

        payoutPercent = new uint256[](0);

        roundInit = IGolf3Round.RoundInit({
            courseName: "testCourse",
            players: players,
            holePars: holePars,
            buyInToken: address(buyInToken),
            buyInAmount: 0,
            skinsBuyInAmount: 60e18,
            payoutPercent: payoutPercent,
            roundTimeoutPeriod: 1 days
        });

        roundAddressSkinsRound = Golf3Factory(golf3Factory).createRound(roundInit);

        // roundAddressMoneyAndSkins

        players = new address[](MAX_PLAYER_COUNT);
        players = testPlayers;

        holePars = new uint8[](6);
        holePars[0] = 3;
        holePars[1] = 4;
        holePars[2] = 4;
        holePars[3] = 5;
        holePars[4] = 4;
        holePars[5] = 4;

        payoutPercent = new uint256[](3);
        payoutPercent[0] = 8000;
        payoutPercent[1] = 1500;
        payoutPercent[2] = 500;

        roundInit = IGolf3Round.RoundInit({
            courseName: "testCourse",
            players: players,
            holePars: holePars,
            buyInToken: address(buyInToken),
            buyInAmount: 5e18,
            skinsBuyInAmount: 1e18,
            payoutPercent: payoutPercent,
            roundTimeoutPeriod: 1 days
        });

        roundAddressMoneyAndSkins = Golf3Factory(golf3Factory).createRound(roundInit);

        vm.stopPrank();
    }

    /*////////////////////////////////////////////////
                        Initialize
    ////////////////////////////////////////////////*/

    function testInitializeSolo(address _testAddress) public {
        vm.assume(_testAddress != testAdmin);

        assertTrue(!Golf3Round(roundAddressSolo).roundClosed());
        assertTrue(!Golf3Round(roundAddressSolo).moneyRound());
        assertTrue(!Golf3Round(roundAddressSolo).skinsRound());
        assertTrue(!Golf3Round(roundAddressSolo).isPlayer(_testAddress));
        assertTrue(!Golf3Round(roundAddressSolo).paidBuyIn(_testAddress));
        assertTrue(!Golf3Round(roundAddressSolo).paidSkinsBuyIn(_testAddress));
        assertTrue(Golf3Round(roundAddressSolo).isPlayer(testAdmin));
        assertTrue(!Golf3Round(roundAddressSolo).paidBuyIn(testAdmin));
        assertTrue(!Golf3Round(roundAddressSolo).paidSkinsBuyIn(testAdmin));
        assertEq(Golf3Round(roundAddressSolo).amountDeposited(_testAddress), 0);
        assertEq(Golf3Round(roundAddressSolo).amountClaimable(_testAddress), 0);
        assertEq(Golf3Round(roundAddressSolo).amountDeposited(testAdmin), 0);
        assertEq(Golf3Round(roundAddressSolo).amountClaimable(testAdmin), 0);
        assertEq(Golf3Round(roundAddressSolo).moneyRoundTotal(), 0);
        assertEq(Golf3Round(roundAddressSolo).skinsRoundTotal(), 0);
        assertEq(Golf3Round(roundAddressSolo).startTime(), block.timestamp);

        address[] memory players = Golf3Round(roundAddressSolo).getPlayers();
        assertEq(players.length, 1);
        assertEq(players[0], testAdmin);

        uint8[] memory holePars = Golf3Round(roundAddressSolo).getHolePars();
        assertEq(holePars.length, 9);
        assertEq(holePars[0], 4);
        assertEq(holePars[1], 4);
        assertEq(holePars[2], 5);
        assertEq(holePars[3], 3);
        assertEq(holePars[4], 4);
        assertEq(holePars[5], 4);
        assertEq(holePars[6], 3);
        assertEq(holePars[7], 4);
        assertEq(holePars[8], 5);

        uint256[] memory payoutPercent = Golf3Round(roundAddressSolo).getPayoutPercent();
        assertEq(payoutPercent.length, 0);

        string memory tempString;
        address tempAddress;
        uint256 tempUint1;
        uint256 tempUint2;
        uint256 tempUint3;

        (tempString, tempAddress, tempUint1, tempUint2, tempUint3) = Golf3Round(roundAddressSolo).roundInit();
        assertEq(tempString, "testCourse");
        assertEq(tempAddress, address(0));
        assertEq(tempUint1, 0);
        assertEq(tempUint2, 0);
        assertEq(tempUint3, 1 days);
    }

    function testInitializeMulti(address _testAddress) public {
        vm.assume(_testAddress !=  address(0));
        vm.assume(_testAddress != testPlayers[0]);
        vm.assume(_testAddress != testPlayers[1]);
        vm.assume(_testAddress != testPlayers[2]);
        vm.assume(_testAddress != testPlayers[3]);
        vm.assume(_testAddress != testPlayers[4]);
        vm.assume(_testAddress != testPlayers[5]);
        vm.assume(_testAddress != testPlayers[6]);
        vm.assume(_testAddress != testPlayers[7]);

        assertTrue(!Golf3Round(roundAddressMulti).roundClosed());
        assertTrue(!Golf3Round(roundAddressMulti).moneyRound());
        assertTrue(!Golf3Round(roundAddressMulti).skinsRound());
        assertTrue(!Golf3Round(roundAddressMulti).isPlayer(_testAddress));
        assertTrue(!Golf3Round(roundAddressMulti).paidBuyIn(_testAddress));
        assertTrue(!Golf3Round(roundAddressMulti).paidSkinsBuyIn(_testAddress));
        assertEq(Golf3Round(roundAddressMulti).amountDeposited(_testAddress), 0);
        assertEq(Golf3Round(roundAddressMulti).amountClaimable(_testAddress), 0);
        for (uint i; i < testPlayers.length; ++i) {
            assertTrue(Golf3Round(roundAddressMulti).isPlayer(testPlayers[i]));
            assertTrue(!Golf3Round(roundAddressMulti).paidBuyIn(testPlayers[i]));
            assertTrue(!Golf3Round(roundAddressMulti).paidSkinsBuyIn(testPlayers[i]));
            assertEq(Golf3Round(roundAddressMulti).amountDeposited(testPlayers[i]), 0);
            assertEq(Golf3Round(roundAddressMulti).amountClaimable(testPlayers[i]), 0);
        }
        assertEq(Golf3Round(roundAddressMulti).moneyRoundTotal(), 0);
        assertEq(Golf3Round(roundAddressMulti).skinsRoundTotal(), 0);
        assertEq(Golf3Round(roundAddressMulti).startTime(), block.timestamp);

        address[] memory players = Golf3Round(roundAddressMulti).getPlayers();
        assertEq(players.length, 8);
        assertEq(players[0], testPlayers[0]);
        assertEq(players[1], testPlayers[1]);
        assertEq(players[2], testPlayers[2]);
        assertEq(players[3], testPlayers[3]);
        assertEq(players[4], testPlayers[4]);
        assertEq(players[5], testPlayers[5]);
        assertEq(players[6], testPlayers[6]);
        assertEq(players[7], testPlayers[7]);

        uint8[] memory holePars = Golf3Round(roundAddressMulti).getHolePars();
        assertEq(holePars.length, 3);
        assertEq(holePars[0], 3);
        assertEq(holePars[1], 3);
        assertEq(holePars[2], 3);

        uint256[] memory payoutPercent = Golf3Round(roundAddressMulti).getPayoutPercent();
        assertEq(payoutPercent.length, 0);

        string memory tempString;
        address tempAddress;
        uint256 tempUint1;
        uint256 tempUint2;
        uint256 tempUint3;

        (tempString, tempAddress, tempUint1, tempUint2, tempUint3) = Golf3Round(roundAddressMulti).roundInit();
        assertEq(tempString, "testCourse");
        assertEq(tempAddress, address(0));
        assertEq(tempUint1, 0);
        assertEq(tempUint2, 0);
        assertEq(tempUint3, 1 days);
    }

    function testInitializeMoney(address _testAddress) public {
        vm.assume(_testAddress !=  address(0));
        vm.assume(_testAddress != testPlayers[0]);
        vm.assume(_testAddress != testPlayers[1]);
        vm.assume(_testAddress != testPlayers[2]);
        vm.assume(_testAddress != testPlayers[3]);
        vm.assume(_testAddress != testPlayers[4]);
        vm.assume(_testAddress != testPlayers[5]);
        vm.assume(_testAddress != testPlayers[6]);
        vm.assume(_testAddress != testPlayers[7]);

        assertTrue(!Golf3Round(roundAddressMoneyRound).roundClosed());
        assertTrue(Golf3Round(roundAddressMoneyRound).moneyRound());
        assertTrue(!Golf3Round(roundAddressMoneyRound).skinsRound());
        assertTrue(!Golf3Round(roundAddressMoneyRound).isPlayer(_testAddress));
        assertTrue(!Golf3Round(roundAddressMoneyRound).paidBuyIn(_testAddress));
        assertTrue(!Golf3Round(roundAddressMoneyRound).paidSkinsBuyIn(_testAddress));
        assertEq(Golf3Round(roundAddressMoneyRound).amountDeposited(_testAddress), 0);
        assertEq(Golf3Round(roundAddressMoneyRound).amountClaimable(_testAddress), 0);
        for (uint i; i < testPlayers.length; ++i) {
            assertTrue(Golf3Round(roundAddressMoneyRound).isPlayer(testPlayers[i]));
            assertTrue(!Golf3Round(roundAddressMoneyRound).paidBuyIn(testPlayers[i]));
            assertTrue(!Golf3Round(roundAddressMoneyRound).paidSkinsBuyIn(testPlayers[i]));
            assertEq(Golf3Round(roundAddressMoneyRound).amountDeposited(testPlayers[i]), 0);
            assertEq(Golf3Round(roundAddressMoneyRound).amountClaimable(testPlayers[i]), 0);
        }
        assertEq(Golf3Round(roundAddressMoneyRound).moneyRoundTotal(), 0);
        assertEq(Golf3Round(roundAddressMoneyRound).skinsRoundTotal(), 0);
        assertEq(Golf3Round(roundAddressMoneyRound).startTime(), block.timestamp);

        address[] memory players = Golf3Round(roundAddressMoneyRound).getPlayers();
        assertEq(players.length, 8);
        assertEq(players[0], testPlayers[0]);
        assertEq(players[1], testPlayers[1]);
        assertEq(players[2], testPlayers[2]);
        assertEq(players[3], testPlayers[3]);
        assertEq(players[4], testPlayers[4]);
        assertEq(players[5], testPlayers[5]);
        assertEq(players[6], testPlayers[6]);
        assertEq(players[7], testPlayers[7]);

        uint8[] memory holePars = Golf3Round(roundAddressMoneyRound).getHolePars();
        assertEq(holePars.length, 6);
        assertEq(holePars[0], 3);
        assertEq(holePars[1], 4);
        assertEq(holePars[2], 4);
        assertEq(holePars[3], 5);
        assertEq(holePars[4], 4);
        assertEq(holePars[5], 4);

        uint256[] memory payoutPercent = Golf3Round(roundAddressMoneyRound).getPayoutPercent();
        assertEq(payoutPercent.length, 3);
        assertEq(payoutPercent[0], 5000);
        assertEq(payoutPercent[1], 3000);
        assertEq(payoutPercent[2], 2000);

        string memory tempString;
        address tempAddress;
        uint256 tempUint1;
        uint256 tempUint2;
        uint256 tempUint3;

        (tempString, tempAddress, tempUint1, tempUint2, tempUint3) = Golf3Round(roundAddressMoneyRound).roundInit();
        assertEq(tempString, "testCourse");
        assertEq(tempAddress, address(buyInToken));
        assertEq(tempUint1, 5e18);
        assertEq(tempUint2, 0);
        assertEq(tempUint3, 1 days);
    }

    function testInitializeSkins(address _testAddress) public {
        vm.assume(_testAddress !=  address(0));
        vm.assume(_testAddress != testPlayers[0]);
        vm.assume(_testAddress != testPlayers[1]);
        vm.assume(_testAddress != testPlayers[2]);
        vm.assume(_testAddress != testPlayers[3]);
        vm.assume(_testAddress != testPlayers[4]);
        vm.assume(_testAddress != testPlayers[5]);
        vm.assume(_testAddress != testPlayers[6]);
        vm.assume(_testAddress != testPlayers[7]);

        assertTrue(!Golf3Round(roundAddressSkinsRound).roundClosed());
        assertTrue(!Golf3Round(roundAddressSkinsRound).moneyRound());
        assertTrue(Golf3Round(roundAddressSkinsRound).skinsRound());
        assertTrue(!Golf3Round(roundAddressSkinsRound).isPlayer(_testAddress));
        assertTrue(!Golf3Round(roundAddressSkinsRound).paidBuyIn(_testAddress));
        assertTrue(!Golf3Round(roundAddressSkinsRound).paidSkinsBuyIn(_testAddress));
        assertEq(Golf3Round(roundAddressSkinsRound).amountDeposited(_testAddress), 0);
        assertEq(Golf3Round(roundAddressSkinsRound).amountClaimable(_testAddress), 0);
        for (uint i; i < testPlayers.length; ++i) {
            assertTrue(Golf3Round(roundAddressSkinsRound).isPlayer(testPlayers[i]));
            assertTrue(!Golf3Round(roundAddressSkinsRound).paidBuyIn(testPlayers[i]));
            assertTrue(!Golf3Round(roundAddressSkinsRound).paidSkinsBuyIn(testPlayers[i]));
            assertEq(Golf3Round(roundAddressSkinsRound).amountDeposited(testPlayers[i]), 0);
            assertEq(Golf3Round(roundAddressSkinsRound).amountClaimable(testPlayers[i]), 0);
        }
        assertEq(Golf3Round(roundAddressSkinsRound).moneyRoundTotal(), 0);
        assertEq(Golf3Round(roundAddressSkinsRound).skinsRoundTotal(), 0);
        assertEq(Golf3Round(roundAddressSkinsRound).startTime(), block.timestamp);

        address[] memory players = Golf3Round(roundAddressSkinsRound).getPlayers();
        assertEq(players.length, 8);
        assertEq(players[0], testPlayers[0]);
        assertEq(players[1], testPlayers[1]);
        assertEq(players[2], testPlayers[2]);
        assertEq(players[3], testPlayers[3]);
        assertEq(players[4], testPlayers[4]);
        assertEq(players[5], testPlayers[5]);
        assertEq(players[6], testPlayers[6]);
        assertEq(players[7], testPlayers[7]);

        uint8[] memory holePars = Golf3Round(roundAddressSkinsRound).getHolePars();
        assertEq(holePars.length, 6);
        assertEq(holePars[0], 3);
        assertEq(holePars[1], 4);
        assertEq(holePars[2], 4);
        assertEq(holePars[3], 5);
        assertEq(holePars[4], 4);
        assertEq(holePars[5], 4);

        uint256[] memory payoutPercent = Golf3Round(roundAddressSkinsRound).getPayoutPercent();
        assertEq(payoutPercent.length, 0);

        string memory tempString;
        address tempAddress;
        uint256 tempUint1;
        uint256 tempUint2;
        uint256 tempUint3;

        (tempString, tempAddress, tempUint1, tempUint2, tempUint3) = Golf3Round(roundAddressSkinsRound).roundInit();
        assertEq(tempString, "testCourse");
        assertEq(tempAddress, address(buyInToken));
        assertEq(tempUint1, 0);
        assertEq(tempUint2, 60e18);
        assertEq(tempUint3, 1 days);
    }

    function testInitializeMoneyAndSkins(address _testAddress) public {
        vm.assume(_testAddress !=  address(0));
        vm.assume(_testAddress != testPlayers[0]);
        vm.assume(_testAddress != testPlayers[1]);
        vm.assume(_testAddress != testPlayers[2]);
        vm.assume(_testAddress != testPlayers[3]);
        vm.assume(_testAddress != testPlayers[4]);
        vm.assume(_testAddress != testPlayers[5]);
        vm.assume(_testAddress != testPlayers[6]);
        vm.assume(_testAddress != testPlayers[7]);

        assertTrue(!Golf3Round(roundAddressMoneyAndSkins).roundClosed());
        assertTrue(Golf3Round(roundAddressMoneyAndSkins).moneyRound());
        assertTrue(Golf3Round(roundAddressMoneyAndSkins).skinsRound());
        assertTrue(!Golf3Round(roundAddressMoneyAndSkins).isPlayer(_testAddress));
        assertTrue(!Golf3Round(roundAddressMoneyAndSkins).paidBuyIn(_testAddress));
        assertTrue(!Golf3Round(roundAddressMoneyAndSkins).paidSkinsBuyIn(_testAddress));
        assertEq(Golf3Round(roundAddressMoneyAndSkins).amountDeposited(_testAddress), 0);
        assertEq(Golf3Round(roundAddressMoneyAndSkins).amountClaimable(_testAddress), 0);
        for (uint i; i < testPlayers.length; ++i) {
            assertTrue(Golf3Round(roundAddressMoneyAndSkins).isPlayer(testPlayers[i]));
            assertTrue(!Golf3Round(roundAddressMoneyAndSkins).paidBuyIn(testPlayers[i]));
            assertTrue(!Golf3Round(roundAddressMoneyAndSkins).paidSkinsBuyIn(testPlayers[i]));
            assertEq(Golf3Round(roundAddressMoneyAndSkins).amountDeposited(testPlayers[i]), 0);
            assertEq(Golf3Round(roundAddressMoneyAndSkins).amountClaimable(testPlayers[i]), 0);
        }
        assertEq(Golf3Round(roundAddressMoneyAndSkins).moneyRoundTotal(), 0);
        assertEq(Golf3Round(roundAddressMoneyAndSkins).skinsRoundTotal(), 0);
        assertEq(Golf3Round(roundAddressMoneyAndSkins).startTime(), block.timestamp);

         address[] memory players = Golf3Round(roundAddressMoneyAndSkins).getPlayers();
        assertEq(players.length, 8);
        assertEq(players[0], testPlayers[0]);
        assertEq(players[1], testPlayers[1]);
        assertEq(players[2], testPlayers[2]);
        assertEq(players[3], testPlayers[3]);
        assertEq(players[4], testPlayers[4]);
        assertEq(players[5], testPlayers[5]);
        assertEq(players[6], testPlayers[6]);
        assertEq(players[7], testPlayers[7]);

        uint8[] memory holePars = Golf3Round(roundAddressMoneyAndSkins).getHolePars();
        assertEq(holePars.length, 6);
        assertEq(holePars[0], 3);
        assertEq(holePars[1], 4);
        assertEq(holePars[2], 4);
        assertEq(holePars[3], 5);
        assertEq(holePars[4], 4);
        assertEq(holePars[5], 4);

        uint256[] memory payoutPercent = Golf3Round(roundAddressMoneyAndSkins).getPayoutPercent();
        assertEq(payoutPercent.length, 3);
        assertEq(payoutPercent[0], 8000);
        assertEq(payoutPercent[1], 1500);
        assertEq(payoutPercent[2], 500);

        string memory tempString;
        address tempAddress;
        uint256 tempUint1;
        uint256 tempUint2;
        uint256 tempUint3;

        (tempString, tempAddress, tempUint1, tempUint2, tempUint3) = Golf3Round(roundAddressMoneyAndSkins).roundInit();
        assertEq(tempString, "testCourse");
        assertEq(tempAddress, address(buyInToken));
        assertEq(tempUint1, 5e18);
        assertEq(tempUint2, 1e18);
        assertEq(tempUint3, 1 days);
    }

    /*////////////////////////////////////////////////
                        depositBuyIn
    ////////////////////////////////////////////////*/

    function testRevertDepositRoundNotOpen() public {
        // round has already been finalized
        (,, uint256 buyInAmount,,) = Golf3Round(roundAddressSolo).roundInit();
        vm.warp(block.timestamp);
        vm.startPrank(testAdmin);
        uint8[] memory score = new uint8[](9);
        score[0] = 3;
        score[1] = 3;
        score[2] = 3;
        score[3] = 3;
        score[4] = 3;
        score[5] = 3;
        score[6] = 3;
        score[7] = 3;
        score[8] = 3;
        uint8[] memory putts;
        bool[] memory fir;
        bool[] memory gir;
        Golf3Round(roundAddressSolo).finalizeRound(score, putts, fir, gir);
        vm.expectRevert("round closed");
        Golf3Round(roundAddressSolo).depositBuyIn(0, 0);
        vm.stopPrank();

        // round has timed out
        uint256 roundTimeoutPeriod;
        (,, buyInAmount,, roundTimeoutPeriod) = Golf3Round(roundAddressMoneyRound).roundInit();
        vm.warp(block.timestamp + roundTimeoutPeriod + 1);
        vm.prank(testPlayers[0]);
        vm.expectRevert("round timed out");
        Golf3Round(roundAddressMoneyRound).depositBuyIn(buyInAmount, 0);
    }

    function testRevertDepositNullToken() public {
        vm.prank(testAdmin);
        vm.expectRevert("token address null");
        Golf3Round(roundAddressSolo).depositBuyIn(10, 0);

        vm.prank(testPlayers[0]);
        vm.expectRevert("token address null");
        Golf3Round(roundAddressMulti).depositBuyIn(10, 0);
    }

    function testRevertDepositNotPlayer(address _testAddress, uint256 _buyInAmount) public {
        vm.assume(_testAddress != testAdmin);
        vm.assume(_testAddress != testPlayers[0]);
        vm.assume(_testAddress != testPlayers[1]);
        vm.assume(_testAddress != testPlayers[2]);
        vm.assume(_testAddress != testPlayers[3]);
        vm.assume(_testAddress != testPlayers[4]);
        vm.assume(_testAddress != testPlayers[5]);
        vm.assume(_testAddress != testPlayers[6]);
        vm.assume(_testAddress != testPlayers[7]);
        vm.assume(_buyInAmount > 0);

        vm.startPrank(_testAddress);
        deal(address(buyInToken), _testAddress, type(uint256).max);

        vm.expectRevert("not in round");
        Golf3Round(roundAddressMoneyRound).depositBuyIn(_buyInAmount, 0);

        vm.expectRevert("not in round");
        Golf3Round(roundAddressSkinsRound).depositBuyIn(_buyInAmount, 0);

        vm.expectRevert("not in round");
        Golf3Round(roundAddressMoneyAndSkins).depositBuyIn(_buyInAmount, 0);

        vm.expectRevert("not in round");
        Golf3Round(roundAddressMoneyAndSkins).depositBuyIn(0, _buyInAmount);

        vm.stopPrank();
    }

    function testRevertDepositNotEnoughBalance(uint256 _buyInAmount, uint256 _skinsBuyInAmount) public {
        vm.assume(_buyInAmount > 0);
        vm.assume(_buyInAmount < 1e70);
        vm.assume(_skinsBuyInAmount > 0);
        vm.assume(_skinsBuyInAmount < 1e70);

        vm.startPrank(testPlayers[0]);
        vm.expectRevert("not enough balance");
        Golf3Round(roundAddressMoneyRound).depositBuyIn(_buyInAmount, 0);
        vm.expectRevert("not enough balance");
        Golf3Round(roundAddressSkinsRound).depositBuyIn(0, _skinsBuyInAmount);
        vm.expectRevert("not enough balance");
        Golf3Round(roundAddressMoneyAndSkins).depositBuyIn(_buyInAmount, _skinsBuyInAmount);
        vm.stopPrank();
    }

    function testRevertDepositNotMoneyRound(uint256 _amount) public {
        vm.assume(_amount > 0);

        // rounds that do not incorporate payments revert before this check

        vm.startPrank(testPlayers[0]);
        deal(address(buyInToken), testPlayers[0], type(uint256).max);
        vm.expectRevert("not moneyRound");
        Golf3Round(roundAddressSkinsRound).depositBuyIn(_amount, 0);
        vm.stopPrank();
    }

    function testRevertDepositNotSkinsRound(uint256 _amount) public {
        vm.assume(_amount > 0);

        // rounds that do not incorporate payments revert before this check

        vm.startPrank(testPlayers[0]);
        deal(address(buyInToken), testPlayers[0], type(uint256).max);
        vm.expectRevert("not skinsRound");
        Golf3Round(roundAddressMoneyRound).depositBuyIn(0, _amount);
        vm.stopPrank();
    }

    function testReverDepositNoAmount() public {
        vm.startPrank(testPlayers[0]);
        deal(address(buyInToken), testPlayers[0], type(uint256).max);
        vm.expectRevert("no amount input");
        Golf3Round(roundAddressMoneyRound).depositBuyIn(0, 0);
        vm.stopPrank();
    }

    function testRevertDepositNotEnoughBuyIn(uint256 _amount) public {
        vm.assume(_amount > 0);
        vm.assume(_amount < 5e18);

        vm.startPrank(testPlayers[0]);
        deal(address(buyInToken), testPlayers[0], type(uint256).max);
        vm.expectRevert("not enough buy in");
        Golf3Round(roundAddressMoneyRound).depositBuyIn(_amount, 0);
        vm.stopPrank();
    }

    function testRevertDepositNotEnoughSkinsBuyIn(uint256 _amount) public {
        vm.assume(_amount > 0);
        vm.assume(_amount < 60e18);

        vm.startPrank(testPlayers[0]);
        deal(address(buyInToken), testPlayers[0], type(uint256).max);
        vm.expectRevert("not enough skins buy in");
        Golf3Round(roundAddressSkinsRound).depositBuyIn(0, _amount);
        vm.stopPrank();
    }

    function testRevertDepositAlreadyPaidMoneyRound() public {
        uint256 buyInAmount;
        (,, buyInAmount,,) = Golf3Round(roundAddressMoneyRound).roundInit();
        vm.startPrank(testPlayers[0]);
        deal(address(buyInToken), testPlayers[0], type(uint256).max);
        buyInToken.approve(address(roundAddressMoneyRound), type(uint256).max);
        Golf3Round(roundAddressMoneyRound).depositBuyIn(buyInAmount, 0);
        vm.expectRevert("already paid");
        Golf3Round(roundAddressMoneyRound).depositBuyIn(buyInAmount, 0);
        vm.stopPrank();
    }

    function testRevertDepositAlreadyPaidSkinsRound() public {
        uint256 buyInAmount;
        (,,,buyInAmount,) = Golf3Round(roundAddressSkinsRound).roundInit();
        vm.startPrank(testPlayers[0]);
        deal(address(buyInToken), testPlayers[0], type(uint256).max);
        buyInToken.approve(address(roundAddressSkinsRound), type(uint256).max);
        Golf3Round(roundAddressSkinsRound).depositBuyIn(0, buyInAmount);
        vm.expectRevert("already paid skins");
        Golf3Round(roundAddressSkinsRound).depositBuyIn(0, buyInAmount);
        vm.stopPrank();
    }

    function testDepositBuyInMoneyRound(uint256 _amount) public {
        uint256 buyInAmount;
        (,, buyInAmount,,) = Golf3Round(roundAddressMoneyRound).roundInit();
        vm.assume(_amount >= buyInAmount);

        assertTrue(Golf3Round(roundAddressMoneyRound).isPlayer(testPlayers[0]));
        assertTrue(!Golf3Round(roundAddressMoneyRound).paidBuyIn(testPlayers[0]));
        assertTrue(!Golf3Round(roundAddressMoneyRound).paidSkinsBuyIn(testPlayers[0]));
        assertEq(Golf3Round(roundAddressMoneyRound).moneyRoundTotal(), 0);
        assertEq(Golf3Round(roundAddressMoneyRound).skinsRoundTotal(), 0);
        assertEq(Golf3Round(roundAddressMoneyRound).amountDeposited(testPlayers[0]), 0);

        vm.startPrank(testPlayers[0]);
        deal(address(buyInToken), testPlayers[0], type(uint256).max);
        buyInToken.approve(address(roundAddressMoneyRound), type(uint256).max);
        vm.expectEmit(true, true, false, false);
        emit DepositedBuyIn(address(roundAddressMoneyRound), testPlayers[0], _amount, _amount, block.timestamp);
        Golf3Round(roundAddressMoneyRound).depositBuyIn(_amount, 0);

        assertTrue(Golf3Round(roundAddressMoneyRound).isPlayer(testPlayers[0]));
        assertTrue(Golf3Round(roundAddressMoneyRound).paidBuyIn(testPlayers[0]));
        assertTrue(!Golf3Round(roundAddressMoneyRound).paidSkinsBuyIn(testPlayers[0]));
        assertEq(Golf3Round(roundAddressMoneyRound).moneyRoundTotal(), _amount);
        assertEq(Golf3Round(roundAddressMoneyRound).skinsRoundTotal(), 0);
        assertEq(Golf3Round(roundAddressMoneyRound).amountDeposited(testPlayers[0]), _amount);
        vm.stopPrank();
    }

    function testDepositBuyInMoneyRoundAllPlayers(uint256 _amount) public {
        uint256 buyInAmount;
        (,, buyInAmount,,) = Golf3Round(roundAddressMoneyRound).roundInit();
        vm.assume(_amount >= buyInAmount);
        vm.assume(_amount < 1e70);

        for (uint256 i; i < testPlayers.length; ++i) {
            assertTrue(Golf3Round(roundAddressMoneyRound).isPlayer(testPlayers[i]));
            assertTrue(!Golf3Round(roundAddressMoneyRound).paidBuyIn(testPlayers[i]));
            assertTrue(!Golf3Round(roundAddressMoneyRound).paidSkinsBuyIn(testPlayers[i]));
            assertEq(Golf3Round(roundAddressMoneyRound).moneyRoundTotal(), i * _amount);
            assertEq(Golf3Round(roundAddressMoneyRound).skinsRoundTotal(), 0);
            assertEq(Golf3Round(roundAddressMoneyRound).amountDeposited(testPlayers[i]), 0);

            vm.startPrank(testPlayers[i]);
            deal(address(buyInToken), testPlayers[i], type(uint256).max);
            buyInToken.approve(address(roundAddressMoneyRound), type(uint256).max);
            vm.expectEmit(true, true, false, false);
            emit DepositedBuyIn(address(roundAddressMoneyRound), testPlayers[i], _amount, (i + 1) *_amount, block.timestamp);
            Golf3Round(roundAddressMoneyRound).depositBuyIn(_amount, 0);

            assertTrue(Golf3Round(roundAddressMoneyRound).isPlayer(testPlayers[i]));
            assertTrue(Golf3Round(roundAddressMoneyRound).paidBuyIn(testPlayers[i]));
            assertTrue(!Golf3Round(roundAddressMoneyRound).paidSkinsBuyIn(testPlayers[i]));
            assertEq(Golf3Round(roundAddressMoneyRound).moneyRoundTotal(), (i + 1) *_amount);
            assertEq(Golf3Round(roundAddressMoneyRound).skinsRoundTotal(), 0);
            assertEq(Golf3Round(roundAddressMoneyRound).amountDeposited(testPlayers[i]), _amount);

            vm.stopPrank();
        }
    }

    function testDepositBuyInSkinsRound(uint256 _amount) public {
        uint256 skinsBuyInAmount;
        (,,, skinsBuyInAmount,) = Golf3Round(roundAddressSkinsRound).roundInit();
        vm.assume(_amount >= skinsBuyInAmount);

        assertTrue(Golf3Round(roundAddressSkinsRound).isPlayer(testPlayers[0]));
        assertTrue(!Golf3Round(roundAddressSkinsRound).paidBuyIn(testPlayers[0]));
        assertTrue(!Golf3Round(roundAddressSkinsRound).paidSkinsBuyIn(testPlayers[0]));
        assertEq(Golf3Round(roundAddressSkinsRound).moneyRoundTotal(), 0);
        assertEq(Golf3Round(roundAddressSkinsRound).skinsRoundTotal(), 0);
        assertEq(Golf3Round(roundAddressSkinsRound).amountDeposited(testPlayers[0]), 0);

        vm.startPrank(testPlayers[0]);
        deal(address(buyInToken), testPlayers[0], type(uint256).max);
        buyInToken.approve(address(roundAddressSkinsRound), type(uint256).max);
        vm.expectEmit(true, true, false, false);
        emit DepositSkinsBuyIn(address(roundAddressSkinsRound), testPlayers[0], _amount, _amount, block.timestamp);
        Golf3Round(roundAddressSkinsRound).depositBuyIn(0, _amount);

        assertTrue(Golf3Round(roundAddressSkinsRound).isPlayer(testPlayers[0]));
        assertTrue(!Golf3Round(roundAddressSkinsRound).paidBuyIn(testPlayers[0]));
        assertTrue(Golf3Round(roundAddressSkinsRound).paidSkinsBuyIn(testPlayers[0]));
        assertEq(Golf3Round(roundAddressSkinsRound).moneyRoundTotal(), 0);
        assertEq(Golf3Round(roundAddressSkinsRound).skinsRoundTotal(), _amount);
        assertEq(Golf3Round(roundAddressSkinsRound).amountDeposited(testPlayers[0]), _amount);
        vm.stopPrank();

    }

    function testDepositBuyInSkinsRoundAllPlayers(uint256 _amount) public {
        uint256 skinsBuyInAmount;
        (,,, skinsBuyInAmount,) = Golf3Round(roundAddressSkinsRound).roundInit();
        vm.assume(_amount >= skinsBuyInAmount);
        vm.assume(_amount < 1e70);

        for (uint256 i; i < testPlayers.length; ++i) {
            assertTrue(Golf3Round(roundAddressSkinsRound).isPlayer(testPlayers[i]));
            assertTrue(!Golf3Round(roundAddressSkinsRound).paidBuyIn(testPlayers[i]));
            assertTrue(!Golf3Round(roundAddressSkinsRound).paidSkinsBuyIn(testPlayers[i]));
            assertEq(Golf3Round(roundAddressSkinsRound).moneyRoundTotal(), 0);
            assertEq(Golf3Round(roundAddressSkinsRound).skinsRoundTotal(), i * _amount);
            assertEq(Golf3Round(roundAddressSkinsRound).amountDeposited(testPlayers[i]), 0);

            vm.startPrank(testPlayers[i]);
            deal(address(buyInToken), testPlayers[i], type(uint256).max);
            buyInToken.approve(address(roundAddressSkinsRound), type(uint256).max);
            vm.expectEmit(true, true, false, false);
            emit DepositSkinsBuyIn(address(roundAddressSkinsRound), testPlayers[i], _amount, (i + 1) *_amount, block.timestamp);
            Golf3Round(roundAddressSkinsRound).depositBuyIn(0, _amount);

            assertTrue(Golf3Round(roundAddressSkinsRound).isPlayer(testPlayers[i]));
            assertTrue(!Golf3Round(roundAddressSkinsRound).paidBuyIn(testPlayers[i]));
            assertTrue(Golf3Round(roundAddressSkinsRound).paidSkinsBuyIn(testPlayers[i]));
            assertEq(Golf3Round(roundAddressSkinsRound).moneyRoundTotal(), 0);
            assertEq(Golf3Round(roundAddressSkinsRound).skinsRoundTotal(), (i + 1) *_amount);
            assertEq(Golf3Round(roundAddressSkinsRound).amountDeposited(testPlayers[i]), _amount);

            vm.stopPrank();
        }
    }

    function testDepositBuyInMoneyAndSkins(uint256 _buyInAmount, uint256 _skinsBuyInAmount) public {
        uint256 buyInAmount;
        uint256 skinsBuyInAmount;
        (,, buyInAmount, skinsBuyInAmount,) = Golf3Round(roundAddressMoneyAndSkins).roundInit();
        vm.assume(_buyInAmount >= buyInAmount);
        vm.assume(_buyInAmount < 1e70);
        vm.assume(_skinsBuyInAmount >= skinsBuyInAmount);
        vm.assume(_skinsBuyInAmount < 1e70);

        assertTrue(Golf3Round(roundAddressMoneyAndSkins).isPlayer(testPlayers[0]));
        assertTrue(!Golf3Round(roundAddressMoneyAndSkins).paidBuyIn(testPlayers[0]));
        assertTrue(!Golf3Round(roundAddressMoneyAndSkins).paidSkinsBuyIn(testPlayers[0]));
        assertEq(Golf3Round(roundAddressMoneyAndSkins).moneyRoundTotal(), 0);
        assertEq(Golf3Round(roundAddressMoneyAndSkins).skinsRoundTotal(), 0);
        assertEq(Golf3Round(roundAddressMoneyAndSkins).amountDeposited(testPlayers[0]), 0);

        vm.startPrank(testPlayers[0]);
        deal(address(buyInToken), testPlayers[0], type(uint256).max);
        buyInToken.approve(address(roundAddressMoneyAndSkins), type(uint256).max);
        Golf3Round(roundAddressMoneyAndSkins).depositBuyIn(_buyInAmount, _skinsBuyInAmount);

        assertTrue(Golf3Round(roundAddressMoneyAndSkins).isPlayer(testPlayers[0]));
        assertTrue(Golf3Round(roundAddressMoneyAndSkins).paidBuyIn(testPlayers[0]));
        assertTrue(Golf3Round(roundAddressMoneyAndSkins).paidSkinsBuyIn(testPlayers[0]));
        assertEq(Golf3Round(roundAddressMoneyAndSkins).moneyRoundTotal(), _buyInAmount);
        assertEq(Golf3Round(roundAddressMoneyAndSkins).skinsRoundTotal(), _skinsBuyInAmount);
        assertEq(Golf3Round(roundAddressMoneyAndSkins).amountDeposited(testPlayers[0]), _buyInAmount + _skinsBuyInAmount);
        vm.stopPrank();
    }

    /*////////////////////////////////////////////////
                        donate
    ////////////////////////////////////////////////*/

    function testRevertDonateRoundNotOpen() public {
        // round has already been finalized
        vm.startPrank(testAdmin);
        uint8[] memory score = new uint8[](9);
        score[0] = 3;
        score[1] = 3;
        score[2] = 3;
        score[3] = 3;
        score[4] = 3;
        score[5] = 3;
        score[6] = 3;
        score[7] = 3;
        score[8] = 3;
        uint8[] memory putts;
        bool[] memory fir;
        bool[] memory gir;
        Golf3Round(roundAddressSolo).finalizeRound(score, putts, fir, gir);
        vm.expectRevert("round closed");
        Golf3Round(roundAddressSolo).donate(1e18);
        vm.stopPrank();

        // round has timed out
        uint256 buyInAmount;
        uint256 roundTimeoutPeriod;
        (,, buyInAmount,, roundTimeoutPeriod) = Golf3Round(roundAddressMoneyRound).roundInit();
        vm.warp(block.timestamp + roundTimeoutPeriod + 1);
        vm.prank(testPlayers[0]);
        vm.expectRevert("round timed out");
        Golf3Round(roundAddressMoneyRound).donate(1e18);
    }

    function testRevertDonateNotMoneyRound(uint256 _amount) public {
        vm.assume(_amount > 0);

        vm.prank(testAdmin);
        vm.expectRevert("not moneyRound");
        Golf3Round(roundAddressSolo).donate(_amount);

        vm.startPrank(testPlayers[0]);
        vm.expectRevert("not moneyRound");
        Golf3Round(roundAddressMulti).donate(_amount);

        vm.expectRevert("not moneyRound");
        Golf3Round(roundAddressSkinsRound).donate(_amount);

        vm.stopPrank();
    }

    function testRevertDonateNoAmount() public {
        vm.startPrank(testPlayers[0]);
        vm.expectRevert("no donate amount");
        Golf3Round(roundAddressMoneyRound).donate(0);

        vm.expectRevert("no donate amount");
        Golf3Round(roundAddressMoneyAndSkins).donate(0);

        vm.stopPrank();
    }

    function testRevertDonateNotEnoughBalance(uint256 _amount) public {
        vm.assume(_amount > 0);
        
        vm.prank(testPlayers[0]);
        vm.expectRevert("not enough balance");
        Golf3Round(roundAddressMoneyRound).donate(_amount);

        vm.prank(testPlayers[0]);
        vm.expectRevert("not enough balance");
        Golf3Round(roundAddressMoneyAndSkins).donate(_amount);
    }

    function testDonate(address _donor, uint256 _amount) public {
        vm.assume(_amount > 0);
        vm.assume(_amount < 1e70);
        vm.assume(_donor != address(0));
        vm.assume(_donor != testPlayers[0]);
        vm.assume(_donor != address(roundAddressSolo));
        vm.assume(_donor != address(roundAddressMulti));
        vm.assume(_donor != address(roundAddressMoneyRound));
        vm.assume(_donor != address(roundAddressSkinsRound));
        vm.assume(_donor != address(roundAddressMoneyAndSkins));

        // first donate

        assertEq(Golf3Round(roundAddressMoneyRound).moneyRoundTotal(), 0);
        assertEq(Golf3Round(roundAddressMoneyRound).skinsRoundTotal(), 0);
        assertEq(Golf3Round(roundAddressMoneyRound).amountDeposited(_donor), 0);

        vm.startPrank(_donor);
        deal(address(buyInToken), _donor, type(uint256).max);
        buyInToken.approve(address(roundAddressMoneyRound), type(uint256).max);
        vm.expectEmit(true, true, false, false);
        emit Donated(address(roundAddressMoneyRound), _donor, _amount, _amount, block.timestamp);
        Golf3Round(roundAddressMoneyRound).donate(_amount);

        assertEq(Golf3Round(roundAddressMoneyRound).moneyRoundTotal(), _amount);
        assertEq(Golf3Round(roundAddressMoneyRound).skinsRoundTotal(), 0);
        assertEq(Golf3Round(roundAddressMoneyRound).amountDeposited(_donor), _amount);

        // second donate

        vm.expectEmit(true, true, false, false);
        emit Donated(address(roundAddressMoneyRound), _donor, _amount, 2 * _amount, block.timestamp);
        Golf3Round(roundAddressMoneyRound).donate(_amount);

        assertEq(Golf3Round(roundAddressMoneyRound).moneyRoundTotal(), 2 * _amount);
        assertEq(Golf3Round(roundAddressMoneyRound).skinsRoundTotal(), 0);
        assertEq(Golf3Round(roundAddressMoneyRound).amountDeposited(_donor), 2 * _amount);

        vm.stopPrank();

        // another address

        vm.startPrank(testPlayers[0]);
        deal(address(buyInToken), testPlayers[0], type(uint256).max);
        buyInToken.approve(address(roundAddressMoneyRound), type(uint256).max);
        vm.expectEmit(true, true, false, false);
        emit Donated(address(roundAddressMoneyRound), testPlayers[0], _amount, 3 * _amount, block.timestamp);
        Golf3Round(roundAddressMoneyRound).donate(_amount);

        assertEq(Golf3Round(roundAddressMoneyRound).moneyRoundTotal(), 3 * _amount);
        assertEq(Golf3Round(roundAddressMoneyRound).skinsRoundTotal(), 0);
        assertEq(Golf3Round(roundAddressMoneyRound).amountDeposited(testPlayers[0]), _amount);

        vm.stopPrank();
    }

    /*////////////////////////////////////////////////
                    withdrawFromTimeout
    ////////////////////////////////////////////////*/

    function testRevertWithdrawNotTimedOut() public {
        // round has already been closed
        vm.startPrank(testAdmin);
        uint8[] memory score = new uint8[](9);
        score[0] = 3;
        score[1] = 3;
        score[2] = 3;
        score[3] = 3;
        score[4] = 3;
        score[5] = 3;
        score[6] = 3;
        score[7] = 3;
        score[8] = 3;
        uint8[] memory putts;
        bool[] memory fir;
        bool[] memory gir;
        Golf3Round(roundAddressSolo).finalizeRound(score, putts, fir, gir);
        vm.expectRevert("round closed");
        Golf3Round(roundAddressSolo).withdrawDeposit();
        vm.stopPrank();

        // round has not been closed but has not yet timed out
        uint256 buyInAmount;
        (,, buyInAmount,,) = Golf3Round(roundAddressMoneyRound).roundInit();
        vm.prank(testPlayers[0]);
        vm.expectRevert("no timeout");
        Golf3Round(roundAddressMoneyRound).withdrawDeposit();
    }

    function testRevertWithdrawNoBalance() public {
        uint256 roundTimeoutPeriod;
        (,,,, roundTimeoutPeriod) = Golf3Round(roundAddressSolo).roundInit();
        vm.warp(block.timestamp + roundTimeoutPeriod + 1);
        vm.prank(testAdmin);
        vm.expectRevert("no balance");
        Golf3Round(roundAddressSolo).withdrawDeposit();
    }

    function testWithdrawDeposit(uint256 _depositAmount) public {
        (,, uint256 buyInAmount,, uint256 roundTimeoutPeriod) = Golf3Round(roundAddressMoneyRound).roundInit();
        vm.assume(_depositAmount >= buyInAmount);
        vm.assume(_depositAmount < 1e70);

        vm.startPrank(testPlayers[0]);
        deal(address(buyInToken), testPlayers[0], type(uint256).max);
        buyInToken.approve(address(roundAddressMoneyRound), type(uint256).max);
        vm.expectEmit(true, true, false, false);
        emit DepositedBuyIn(address(roundAddressMoneyRound), testPlayers[0], _depositAmount, _depositAmount, block.timestamp);
        Golf3Round(roundAddressMoneyRound).depositBuyIn(_depositAmount, 0);

        assertTrue(Golf3Round(roundAddressMoneyRound).isPlayer(testPlayers[0]));
        assertTrue(Golf3Round(roundAddressMoneyRound).paidBuyIn(testPlayers[0]));
        assertTrue(!Golf3Round(roundAddressMoneyRound).paidSkinsBuyIn(testPlayers[0]));
        assertEq(Golf3Round(roundAddressMoneyRound).moneyRoundTotal(), _depositAmount);
        assertEq(Golf3Round(roundAddressMoneyRound).skinsRoundTotal(), 0);
        assertEq(Golf3Round(roundAddressMoneyRound).amountDeposited(testPlayers[0]), _depositAmount);

        vm.warp(block.timestamp + roundTimeoutPeriod + 1);
        vm.expectEmit(true, true, false, false);
        emit Withdraw(roundAddressMoneyRound, testPlayers[0], _depositAmount, block.timestamp);
        Golf3Round(roundAddressMoneyRound).withdrawDeposit();

        assertTrue(Golf3Round(roundAddressMoneyRound).isPlayer(testPlayers[0]));
        assertTrue(Golf3Round(roundAddressMoneyRound).paidBuyIn(testPlayers[0]));
        assertTrue(!Golf3Round(roundAddressMoneyRound).paidSkinsBuyIn(testPlayers[0]));
        assertEq(Golf3Round(roundAddressMoneyRound).moneyRoundTotal(), 0);
        assertEq(Golf3Round(roundAddressMoneyRound).skinsRoundTotal(), 0);
        assertEq(Golf3Round(roundAddressMoneyRound).amountDeposited(testPlayers[0]), 0);
        vm.stopPrank();
    }

    function testWithdrawDepositAllPlayers(uint256 _depositAmount) public {
        (,, uint256 buyInAmount,, uint256 roundTimeoutPeriod) = Golf3Round(roundAddressMoneyRound).roundInit();
        vm.assume(_depositAmount >= buyInAmount);
        vm.assume(_depositAmount < 1e70);

        // every player deposits
        for (uint256 i; i < testPlayers.length; ++i) {
            vm.startPrank(testPlayers[i]);
            deal(address(buyInToken), testPlayers[i], type(uint256).max);
            buyInToken.approve(address(roundAddressMoneyRound), type(uint256).max);
            vm.expectEmit(true, true, false, false);
            emit DepositedBuyIn(address(roundAddressMoneyRound), testPlayers[i], _depositAmount, (i + 1) * _depositAmount, block.timestamp);
            Golf3Round(roundAddressMoneyRound).depositBuyIn(_depositAmount, 0);

            assertTrue(Golf3Round(roundAddressMoneyRound).isPlayer(testPlayers[i]));
            assertTrue(Golf3Round(roundAddressMoneyRound).paidBuyIn(testPlayers[i]));
            assertTrue(!Golf3Round(roundAddressMoneyRound).paidSkinsBuyIn(testPlayers[i]));
            assertEq(Golf3Round(roundAddressMoneyRound).moneyRoundTotal(), (i + 1) * _depositAmount);
            assertEq(Golf3Round(roundAddressMoneyRound).skinsRoundTotal(), 0);
            assertEq(Golf3Round(roundAddressMoneyRound).amountDeposited(testPlayers[i]), _depositAmount);
            vm.stopPrank();
        }

        // warp to timeout
        uint256 maxDeposited = _depositAmount * testPlayers.length;
        vm.warp(block.timestamp + roundTimeoutPeriod + 1);

        // every player withdraws
        for (uint256 i; i < testPlayers.length; ++i) {
            vm.startPrank(testPlayers[i]);
            vm.expectEmit(true, true, false, false);
            emit Withdraw(roundAddressMoneyRound, testPlayers[i], _depositAmount, block.timestamp);
            Golf3Round(roundAddressMoneyRound).withdrawDeposit();

            assertTrue(Golf3Round(roundAddressMoneyRound).isPlayer(testPlayers[i]));
            assertTrue(Golf3Round(roundAddressMoneyRound).paidBuyIn(testPlayers[i]));
            assertTrue(!Golf3Round(roundAddressMoneyRound).paidSkinsBuyIn(testPlayers[i]));
            assertEq(Golf3Round(roundAddressMoneyRound).moneyRoundTotal(), maxDeposited - ((i + 1) * _depositAmount));
            assertEq(Golf3Round(roundAddressMoneyRound).skinsRoundTotal(), 0);
            assertEq(Golf3Round(roundAddressMoneyRound).amountDeposited(testPlayers[i]), 0);
            vm.stopPrank();
        }
    }

    /*////////////////////////////////////////////////
                    finalizeRound
    ////////////////////////////////////////////////*/

    function testRevertFinalizeNotAdmin(address _caller) public {
        vm.assume(_caller != testAdmin);
        vm.assume(_caller != roundAddressSolo);
        vm.assume(_caller != roundAddressMulti);
        vm.assume(_caller != roundAddressMoneyRound);
        vm.assume(_caller != roundAddressSkinsRound);
        vm.assume(_caller != roundAddressMoneyAndSkins);
        vm.startPrank(_caller);
        uint8[] memory score = new uint8[](9);
        uint8[] memory putts;
        bool[] memory fir;
        bool[] memory gir;
        vm.expectRevert("only admin");
        Golf3Round(roundAddressSolo).finalizeRound(score, putts, fir, gir);
    }

    function testRevertFinalizeAlreadyClose() public {
        vm.startPrank(testAdmin);
        uint8[] memory score = new uint8[](9);
        score[0] = 3;
        score[1] = 3;
        score[2] = 3;
        score[3] = 3;
        score[4] = 3;
        score[5] = 3;
        score[6] = 3;
        score[7] = 3;
        score[8] = 3;
        uint8[] memory putts;
        bool[] memory fir;
        bool[] memory gir;
        Golf3Round(roundAddressSolo).finalizeRound(score, putts, fir, gir);
        vm.expectRevert("round closed");
        Golf3Round(roundAddressSolo).finalizeRound(score, putts, fir, gir);
        vm.stopPrank();
    }

    function testRevertFinalizeTimedOut() public {
        vm.startPrank(testAdmin);
        uint8[] memory score = new uint8[](9);
        score[0] = 3;
        score[1] = 3;
        score[2] = 3;
        score[3] = 3;
        score[4] = 3;
        score[5] = 3;
        score[6] = 3;
        score[7] = 3;
        score[8] = 3;
        uint8[] memory putts;
        bool[] memory fir;
        bool[] memory gir;
        vm.warp(block.timestamp + 10 days);
        vm.expectRevert("round timed out");
        Golf3Round(roundAddressSolo).finalizeRound(score, putts, fir, gir);
        vm.stopPrank();
    }

    function testRevertFinalizeInvalidScoreSizeSolo(uint8 _amountOfScores) public {
        vm.startPrank(testAdmin);
        vm.assume(_amountOfScores != 0);
        vm.assume(_amountOfScores != 9);
        uint8[] memory score = new uint8[](_amountOfScores);
        for (uint8 i; i < _amountOfScores; ++i) {
            score[i] = 3;
        }
        uint8[] memory putts;
        bool[] memory fir;
        bool[] memory gir;
        vm.expectRevert("invalid score array");
        Golf3Round(roundAddressSolo).finalizeRound(score, putts, fir, gir);
        vm.stopPrank();
    }

    function testRevertFinalizeInvalidPuttsSizeSolo(uint8 _amountOfPutts) public {
        vm.startPrank(testAdmin);
        vm.assume(_amountOfPutts != 0);
        vm.assume(_amountOfPutts != 9);
        uint8[] memory score = new uint8[](9);
        for (uint8 i; i < score.length; ++i) {
            score[i] = 3;
        }
        uint8[] memory putts = new uint8[](_amountOfPutts);
        for (uint8 i; i < _amountOfPutts; ++i) {
            putts[i] = 2;
        }
        bool[] memory fir;
        bool[] memory gir;
        vm.expectRevert("invalid putts array");
        Golf3Round(roundAddressSolo).finalizeRound(score, putts, fir, gir);
        vm.stopPrank();
    }

    function testRevertFinalizeInvalidFirSizeSolo(uint8 _amountOfFir) public {
        vm.startPrank(testAdmin);
        vm.assume(_amountOfFir != 0);
        vm.assume(_amountOfFir != 9);
        uint8[] memory score = new uint8[](9);
        for (uint8 i; i < score.length; ++i) {
            score[i] = 3;
        }
        uint8[] memory putts;
        bool[] memory fir = new bool[](_amountOfFir);
        bool[] memory gir;
        vm.expectRevert("invalid fir array");
        Golf3Round(roundAddressSolo).finalizeRound(score, putts, fir, gir);
        vm.stopPrank();
    }

    function testRevertFinalizeInvalidGirSizeSolo(uint8 _amountOfGir) public {
        vm.startPrank(testAdmin);
        vm.assume(_amountOfGir != 0);
        vm.assume(_amountOfGir != 9);
        uint8[] memory score = new uint8[](9);
        for (uint8 i; i < score.length; ++i) {
            score[i] = 3;
        }
        uint8[] memory putts;
        bool[] memory fir;
        bool[] memory gir = new bool[](_amountOfGir);
        vm.expectRevert("invalid gir array");
        Golf3Round(roundAddressSolo).finalizeRound(score, putts, fir, gir);
        vm.stopPrank();
    }

    function testFinalizeSimpleSolo() public {
        vm.startPrank(testAdmin);
        uint8[] memory score = new uint8[](9);
        for (uint8 i; i < score.length; ++i) {
            score[i] = 3;
        }
        uint8[] memory putts;
        bool[] memory fir;
        bool[] memory gir;

        address[] memory players = Golf3Round(roundAddressSolo).getPlayers();

        assertTrue(!Golf3Round(roundAddressSolo).roundClosed());

        vm.expectEmit(false, false, false, false);
        emit FinalizeRound(roundAddressSolo, players, score, putts, fir, gir);
        Golf3Round(roundAddressSolo).finalizeRound(score, putts, fir, gir);

        for (uint8 i; i < score.length; ++i) {
            assertEq(Golf3Round(roundAddressSolo).finalScores(i), 3);
        }

        assertTrue(Golf3Round(roundAddressSolo).roundClosed());

        vm.stopPrank();
    }

    function testFinalizeSoloWithStats() public {
        vm.startPrank(testAdmin);
        uint256 arraySize = 9;
        uint8[] memory score = new uint8[](arraySize);
        uint8[] memory putts = new uint8[](arraySize);
        bool[] memory fir = new bool[](arraySize);
        bool[] memory gir = new bool[](arraySize);
        for (uint8 i; i < score.length; ++i) {
            score[i] = 3;
            putts[i] = 2;
            fir[i] = true;
            gir[i] = false;
        }

        address[] memory players = Golf3Round(roundAddressSolo).getPlayers();

        assertTrue(!Golf3Round(roundAddressSolo).roundClosed());

        vm.expectEmit(false, false, false, false);
        emit FinalizeRound(roundAddressSolo, players, score, putts, fir, gir);
        Golf3Round(roundAddressSolo).finalizeRound(score, putts, fir, gir);

        for (uint8 i; i < score.length; ++i) {
            assertEq(Golf3Round(roundAddressSolo).finalScores(i), 3);
        }

        assertTrue(Golf3Round(roundAddressSolo).roundClosed());

        vm.stopPrank();
    }

    function testFinalizeSimpleMulti() public {
        vm.startPrank(testAdmin);
        uint256 arraySize = testPlayers.length * 3;
        uint8[] memory score = new uint8[](arraySize);
        for (uint8 i; i < score.length; ++i) {
            score[i] = 3;
        }
        uint8[] memory putts;
        bool[] memory fir;
        bool[] memory gir;

        address[] memory players = Golf3Round(roundAddressMulti).getPlayers();

        assertTrue(!Golf3Round(roundAddressMulti).roundClosed());

        vm.expectEmit(false, false, false, false);
        emit FinalizeRound(roundAddressMulti, players, score, putts, fir, gir);
        Golf3Round(roundAddressMulti).finalizeRound(score, putts, fir, gir);

        for (uint8 i; i < score.length; ++i) {
            assertEq(Golf3Round(roundAddressMulti).finalScores(i), 3);
        }

        assertTrue(Golf3Round(roundAddressMulti).roundClosed());

        vm.stopPrank();
    }

    function testFinalizeMultiWithStats() public {
        vm.startPrank(testAdmin);
        uint256 arraySize = testPlayers.length * 3;
        uint8[] memory score = new uint8[](arraySize);
        uint8[] memory putts = new uint8[](arraySize);
        bool[] memory fir = new bool[](arraySize);
        bool[] memory gir = new bool[](arraySize);
        for (uint8 i; i < score.length; ++i) {
            score[i] = 3;
            putts[i] = 2;
            fir[i] = true;
            gir[i] = false;
        }

        address[] memory players = Golf3Round(roundAddressMulti).getPlayers();

        assertTrue(!Golf3Round(roundAddressMulti).roundClosed());

        vm.expectEmit(false, false, false, false);
        emit FinalizeRound(roundAddressMulti, players, score, putts, fir, gir);
        Golf3Round(roundAddressMulti).finalizeRound(score, putts, fir, gir);

        for (uint8 i; i < score.length; ++i) {
            assertEq(Golf3Round(roundAddressMulti).finalScores(i), 3);
        }

        assertTrue(Golf3Round(roundAddressMulti).roundClosed());

        vm.stopPrank();
    }

    function testFinalizeMoneyRound(uint256 _amount) public {
        uint256 arraySize = testPlayers.length * 6;
        uint8[] memory score = new uint8[](arraySize);
        uint8[] memory putts = new uint8[](arraySize);
        bool[] memory fir = new bool[](arraySize);
        bool[] memory gir = new bool[](arraySize);

        address[] memory players = Golf3Round(roundAddressMoneyRound).getPlayers();

        uint256 buyInAmount;
        (,, buyInAmount,,) = Golf3Round(roundAddressMoneyRound).roundInit();
        vm.assume(_amount >= buyInAmount);
        vm.assume(_amount < 1e70);

        // each player deposits
        for (uint256 i; i < players.length; ++i) {
            assertTrue(Golf3Round(roundAddressMoneyRound).isPlayer(players[i]));
            assertTrue(!Golf3Round(roundAddressMoneyRound).paidBuyIn(players[i]));
            assertTrue(!Golf3Round(roundAddressMoneyRound).paidSkinsBuyIn(players[i]));
            assertEq(Golf3Round(roundAddressMoneyRound).moneyRoundTotal(), i * _amount);
            assertEq(Golf3Round(roundAddressMoneyRound).skinsRoundTotal(), 0);
            assertEq(Golf3Round(roundAddressMoneyRound).amountDeposited(players[i]), 0);

            vm.startPrank(players[i]);
            deal(address(buyInToken), players[i], 1e70);
            buyInToken.approve(address(roundAddressMoneyRound), 1e70);
            vm.expectEmit(true, true, false, false);
            emit DepositedBuyIn(address(roundAddressMoneyRound), players[i], _amount, (i + 1) *_amount, block.timestamp);
            Golf3Round(roundAddressMoneyRound).depositBuyIn(_amount, 0);

            assertTrue(Golf3Round(roundAddressMoneyRound).isPlayer(players[i]));
            assertTrue(Golf3Round(roundAddressMoneyRound).paidBuyIn(players[i]));
            assertTrue(!Golf3Round(roundAddressMoneyRound).paidSkinsBuyIn(players[i]));
            assertEq(Golf3Round(roundAddressMoneyRound).moneyRoundTotal(), (i + 1) *_amount);
            assertEq(Golf3Round(roundAddressMoneyRound).skinsRoundTotal(), 0);
            assertEq(Golf3Round(roundAddressMoneyRound).amountDeposited(players[i]), _amount);
            assertEq(MockERC20(buyInToken).balanceOf(players[i]), 1e70 - _amount);

            vm.stopPrank();
        }

        uint256 beforeFinalizeMoneyRoundTotal = Golf3Round(roundAddressMoneyRound).moneyRoundTotal();
        assertEq(beforeFinalizeMoneyRoundTotal, _amount*players.length);

        // last player gets best score, second to last gets second best, so on...
        // to get that the score sort for payout distribution is correct
        for (uint8 i; i < score.length; ++i) {
            score[i] = 8 - (i / 6);   // first player gets all scores of 8, second gets 7, etc.
            putts[i] = 2;
            fir[i] = true;
            gir[i] = false;
        }

        assertTrue(!Golf3Round(roundAddressMoneyRound).roundClosed());

        vm.startPrank(testAdmin);

        vm.expectEmit(false, false, false, false);
        emit FinalizeRound(roundAddressMoneyRound, players, score, putts, fir, gir);
        Golf3Round(roundAddressMoneyRound).finalizeRound(score, putts, fir, gir);

        for (uint8 i; i < score.length; ++i) {
            assertEq(Golf3Round(roundAddressMoneyRound).finalScores(i), 8 - (i / 6));
        }

        assertTrue(Golf3Round(roundAddressMoneyRound).roundClosed());
        assertTrue(Golf3Round(roundAddressMoneyRound).moneyRound());

        uint256[] memory payoutPercent = Golf3Round(roundAddressMoneyRound).getPayoutPercent();
        assertEq(payoutPercent.length, 3);

        uint256 moneyRoundTotal = Golf3Round(roundAddressMoneyRound).moneyRoundTotal();
        uint256 totalClaimable;
        for (uint8 i; i < players.length; ++i) {
            assertEq(MockERC20(buyInToken).balanceOf(players[i]), 1e70 - _amount);
            totalClaimable += Golf3Round(roundAddressMoneyRound).amountClaimable(players[i]);
        }
        assertTrue(totalClaimable > 0);
        assertEq(moneyRoundTotal, players.length*_amount - totalClaimable);

        assertEq(Golf3Round(roundAddressMoneyRound).amountClaimable(players[players.length-1]),
            beforeFinalizeMoneyRoundTotal*payoutPercent[0]/BASE);
        assertEq(Golf3Round(roundAddressMoneyRound).amountClaimable(players[players.length-2]),
            beforeFinalizeMoneyRoundTotal*payoutPercent[1]/BASE);
        assertEq(Golf3Round(roundAddressMoneyRound).amountClaimable(players[players.length-3]),
            beforeFinalizeMoneyRoundTotal*payoutPercent[2]/BASE);
        for (uint256 i; i < players.length - payoutPercent.length; ++i) {
            assertEq(Golf3Round(roundAddressMoneyRound).amountClaimable(players[i]), 0);
        }

        vm.stopPrank();

        //
        for (uint8 i; i < players.length; ++i) {
            if (i < payoutPercent.length) {
                assertEq(MockERC20(buyInToken).balanceOf(players[players.length-1-i]), 1e70 - _amount);
                vm.prank(players[players.length-1-i]);
                vm.expectEmit(true, true, false, false);
                emit Claim(
                    address(roundAddressMoneyRound),
                    players[players.length-1-i],
                    beforeFinalizeMoneyRoundTotal*payoutPercent[i]/BASE,
                    block.timestamp);
                Golf3Round(roundAddressMoneyRound).claim();
                assertEq(MockERC20(buyInToken).balanceOf(players[players.length-1-i]),
                    1e70 - _amount + payoutPercent[i]*beforeFinalizeMoneyRoundTotal/BASE);
            } else {
                assertEq(MockERC20(buyInToken).balanceOf(players[players.length-1-i]), 1e70 - _amount);
                vm.prank(players[players.length-1-i]);
                vm.expectRevert("no claim amount");
                Golf3Round(roundAddressMoneyRound).claim();
                assertEq(MockERC20(buyInToken).balanceOf(players[players.length-1-i]), 1e70 - _amount);
            }
        }
        
    }

    function testFinalizeMoneyRoundEveryoneTies(uint256 _amount) public {
        uint256 arraySize = testPlayers.length * 6;
        uint8[] memory score = new uint8[](arraySize);
        uint8[] memory putts = new uint8[](arraySize);
        bool[] memory fir = new bool[](arraySize);
        bool[] memory gir = new bool[](arraySize);

        address[] memory players = Golf3Round(roundAddressMoneyRound).getPlayers();

        uint256 buyInAmount;
        (,, buyInAmount,,) = Golf3Round(roundAddressMoneyRound).roundInit();
        vm.assume(_amount >= buyInAmount);
        vm.assume(_amount < 1e70);

        // each player deposits
        for (uint256 i; i < players.length; ++i) {
            assertTrue(Golf3Round(roundAddressMoneyRound).isPlayer(players[i]));
            assertTrue(!Golf3Round(roundAddressMoneyRound).paidBuyIn(players[i]));
            assertTrue(!Golf3Round(roundAddressMoneyRound).paidSkinsBuyIn(players[i]));
            assertEq(Golf3Round(roundAddressMoneyRound).moneyRoundTotal(), i * _amount);
            assertEq(Golf3Round(roundAddressMoneyRound).skinsRoundTotal(), 0);
            assertEq(Golf3Round(roundAddressMoneyRound).amountDeposited(players[i]), 0);

            vm.startPrank(players[i]);
            deal(address(buyInToken), players[i], 1e70);
            buyInToken.approve(address(roundAddressMoneyRound), 1e70);
            vm.expectEmit(true, true, false, false);
            emit DepositedBuyIn(address(roundAddressMoneyRound), players[i], _amount, (i + 1) *_amount, block.timestamp);
            Golf3Round(roundAddressMoneyRound).depositBuyIn(_amount, 0);

            assertTrue(Golf3Round(roundAddressMoneyRound).isPlayer(players[i]));
            assertTrue(Golf3Round(roundAddressMoneyRound).paidBuyIn(players[i]));
            assertTrue(!Golf3Round(roundAddressMoneyRound).paidSkinsBuyIn(players[i]));
            assertEq(Golf3Round(roundAddressMoneyRound).moneyRoundTotal(), (i + 1) *_amount);
            assertEq(Golf3Round(roundAddressMoneyRound).skinsRoundTotal(), 0);
            assertEq(Golf3Round(roundAddressMoneyRound).amountDeposited(players[i]), _amount);
            assertEq(MockERC20(buyInToken).balanceOf(players[i]), 1e70 - _amount);

            vm.stopPrank();
        }

        // everyone ties
        for (uint8 i; i < score.length; ++i) {
            score[i] = 4;
            putts[i] = 2;
            fir[i] = true;
            gir[i] = false;
        }

        assertTrue(!Golf3Round(roundAddressMoneyRound).roundClosed());

        vm.startPrank(testAdmin);

        vm.expectEmit(false, false, false, false);
        emit FinalizeRound(roundAddressMoneyRound, players, score, putts, fir, gir);
        Golf3Round(roundAddressMoneyRound).finalizeRound(score, putts, fir, gir);

        for (uint8 i; i < score.length; ++i) {
            assertEq(Golf3Round(roundAddressMoneyRound).finalScores(i), 4);
        }

        assertTrue(Golf3Round(roundAddressMoneyRound).roundClosed());

        uint256[] memory payoutPercent = Golf3Round(roundAddressMoneyRound).getPayoutPercent();
        assertEq(payoutPercent.length, 3);
        uint256 moneyRoundTotal = Golf3Round(roundAddressMoneyRound).moneyRoundTotal();
        assertTrue(moneyRoundTotal < players.length *_amount);
        assertTrue(moneyRoundTotal >= 0);
        
        // because all players tied, the total accumulated percent was equal to the BASE (100%)
        uint256 claimAmount = (players.length*_amount) * BASE / BASE / players.length;
        assertTrue(claimAmount > 0);
        for (uint8 i; i < players.length; ++i) {
            assertEq(MockERC20(buyInToken).balanceOf(players[i]), 1e70 - _amount);
            // all players have the same total claimable because they all tied
            assertEq(
                Golf3Round(roundAddressMoneyRound).amountClaimable(players[i]),
                claimAmount
            );
        }

        vm.stopPrank();

        // have all players claim

        for (uint8 i; i < players.length; ++i) {
            vm.prank(players[i]);
            vm.expectEmit(false, false, false, false);
            emit Claim(roundAddressMoneyRound, players[i], claimAmount, block.timestamp);
            Golf3Round(roundAddressMoneyRound).claim();
            assertEq(MockERC20(buyInToken).balanceOf(players[i]), 1e70 - _amount + claimAmount);
        }
    }

    function testFinalizeSkinsRound(uint256 _amount) public {
        uint256 arraySize = testPlayers.length * 6;
        uint8[] memory score = new uint8[](arraySize);
        uint8[] memory putts = new uint8[](arraySize);
        bool[] memory fir = new bool[](arraySize);
        bool[] memory gir = new bool[](arraySize);

        address[] memory players = Golf3Round(roundAddressSkinsRound).getPlayers();

        uint256 buyInAmount;
        (,,, buyInAmount,) = Golf3Round(roundAddressSkinsRound).roundInit();
        vm.assume(_amount >= buyInAmount);
        vm.assume(_amount < 1e70);

        // each player deposits
        for (uint256 i; i < players.length; ++i) {
            assertTrue(Golf3Round(roundAddressSkinsRound).isPlayer(players[i]));
            assertTrue(!Golf3Round(roundAddressSkinsRound).paidBuyIn(players[i]));
            assertTrue(!Golf3Round(roundAddressSkinsRound).paidSkinsBuyIn(players[i]));
            assertEq(Golf3Round(roundAddressSkinsRound).moneyRoundTotal(), 0);
            assertEq(Golf3Round(roundAddressSkinsRound).skinsRoundTotal(), i * _amount);
            assertEq(Golf3Round(roundAddressSkinsRound).amountDeposited(players[i]), 0);

            vm.startPrank(players[i]);
            deal(address(buyInToken), players[i], 1e70);
            buyInToken.approve(address(roundAddressSkinsRound), 1e70);
            vm.expectEmit(true, true, false, false);
            emit DepositSkinsBuyIn(address(roundAddressSkinsRound), players[i], _amount, (i + 1) *_amount, block.timestamp);
            Golf3Round(roundAddressSkinsRound).depositBuyIn(0, _amount);

            assertTrue(Golf3Round(roundAddressSkinsRound).isPlayer(players[i]));
            assertTrue(!Golf3Round(roundAddressSkinsRound).paidBuyIn(players[i]));
            assertTrue(Golf3Round(roundAddressSkinsRound).paidSkinsBuyIn(players[i]));
            assertEq(Golf3Round(roundAddressSkinsRound).moneyRoundTotal(), 0);
            assertEq(Golf3Round(roundAddressSkinsRound).skinsRoundTotal(), (i + 1) *_amount);
            assertEq(Golf3Round(roundAddressSkinsRound).amountDeposited(players[i]), _amount);
            assertEq(MockERC20(buyInToken).balanceOf(players[i]), 1e70 - _amount);

            vm.stopPrank();
        }

        // submit scores
        // player[0] gets 1 skin, player[2] gets 3 skins, 2 skins left over

        for (uint8 i; i < score.length; ++i) {
            putts[i] = 2;
            fir[i] = true;
            gir[i] = false;
        }

        // player 0
        score[0] = 1; // skins won: 1
        score[1] = 4;
        score[2] = 4;
        score[3] = 3;
        score[4] = 3;
        score[5] = 5;
        //player 1
        score[6] = 2;
        score[7] = 4;
        score[8] = 4;
        score[9] = 3;
        score[10] = 3;
        score[11] = 5;
        //player 2
        score[12] = 2;
        score[13] = 4;
        score[14] = 4;
        score[15] = 2; // skins won: 3
        score[16] = 3;
        score[17] = 5;
        //player 3
        score[18] = 2;
        score[19] = 4;
        score[20] = 4;
        score[21] = 3;
        score[22] = 3;
        score[23] = 5;
        //player 4
        score[24] = 2;
        score[25] = 4;
        score[26] = 4;
        score[27] = 3;
        score[28] = 3;
        score[29] = 5;
        //player 5
        score[30] = 2;
        score[31] = 4;
        score[32] = 5;
        score[33] = 3;
        score[34] = 3;
        score[35] = 5;
        //player 6
        score[36] = 2;
        score[37] = 4;
        score[38] = 5;
        score[39] = 3;
        score[40] = 3;
        score[41] = 5;
        //player 7
        score[42] = 2;
        score[43] = 4;
        score[44] = 4;
        score[45] = 3;
        score[46] = 3;
        score[47] = 5;

        assertTrue(!Golf3Round(roundAddressSkinsRound).roundClosed());

        vm.startPrank(testAdmin);

        vm.expectEmit(false, false, false, false);
        emit FinalizeRound(roundAddressSkinsRound, players, score, putts, fir, gir);
        Golf3Round(roundAddressSkinsRound).finalizeRound(score, putts, fir, gir);

        assertTrue(Golf3Round(roundAddressSkinsRound).roundClosed());

        uint256 skinsRoundTotal = Golf3Round(roundAddressSkinsRound).skinsRoundTotal();
        assertTrue(skinsRoundTotal < players.length *_amount);
        assertTrue(skinsRoundTotal >= 0);

        vm.stopPrank();
    }

    /*////////////////////////////////////////////////
                        Events
    ////////////////////////////////////////////////*/

    event FinalizeRound(
        address indexed roundAddress,
        address[] players,
        uint8[] scores,
        uint8[] putts,
        bool[] fir,
        bool[] gir
    );

    event Claim(address indexed roundAddress, address indexed userAddress, uint256 claimAmount, uint256 timestamp);

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

    event Withdraw(address indexed roundAddress, address indexed userAddress, uint256 withdrawAmount, uint256 timestamp);
}