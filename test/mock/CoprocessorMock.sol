// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ICoprocessor} from "../../src/ICoprocessor.sol";

contract CoprocessorMock is ICoprocessor {
    event TaskIssued(bytes32 machineHash, bytes input, address callback);

    function issueTask(bytes32 machineHash, bytes calldata input, address callback) public {
        emit TaskIssued(machineHash, input, callback);
    }
}
