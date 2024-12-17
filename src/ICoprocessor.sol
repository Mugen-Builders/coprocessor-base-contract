// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface ICoprocessor {
    function issueTask(bytes32 machineHash, bytes calldata input, address callbackAddress) external;
}
