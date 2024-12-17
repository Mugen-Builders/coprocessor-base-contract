// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface ICoprocessorOutputs {
    function Notice(bytes calldata payload) external;
}

interface ICoprocessorCallback {
    function coprocessorCallbackOutputsOnly(bytes32 machineHash, bytes32 payloadHash, bytes[] calldata outputs)
        external;
}
