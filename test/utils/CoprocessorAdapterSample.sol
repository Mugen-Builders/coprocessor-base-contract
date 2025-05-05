//SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../../src/CoprocessorAdapter.sol";

contract CoprocessorAdapterSample is CoprocessorAdapter {
    constructor(address _taskIssuerAddress, bytes32 _machineHash)
        CoprocessorAdapter(_taskIssuerAddress, _machineHash)
    {}

    function runExecution(bytes memory input) external {
        callCoprocessor(input);
    }

    function handleNotice(bytes32 payloadHash, bytes memory notice) internal override {
        address destination;
        bytes memory decodedPayload;

        (destination, decodedPayload) = abi.decode(notice, (address, bytes));

        bool success;
        bytes memory returndata;

        (success, returndata) = destination.call(decodedPayload);
    }
}
