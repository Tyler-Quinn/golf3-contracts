// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./Golf3Round.sol";
import "./libraries/Clones.sol";

contract Golf3Factory is IGolf3Round{
    address public immutable ROUND_LOGIC;

    constructor(
        address _golf3RoundLogic
    ) {
        require(_golf3RoundLogic != address(0), "cant pass null round address");
        ROUND_LOGIC = _golf3RoundLogic;
    }

    function createRound(IGolf3Round.RoundInit calldata _roundInit) public returns (address roundAddress) {
        roundAddress = Clones.clone(ROUND_LOGIC);
        Golf3Round(roundAddress).initialize(_roundInit, msg.sender);

        emit CreateRound(roundAddress, msg.sender, _roundInit, block.timestamp);
    }
}