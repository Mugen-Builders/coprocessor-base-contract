// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./ICoprocessor.sol";
import "./ICoprocessorCallback.sol";

/// @title BaseContract
/// @notice A base contract, which should be inherited for interacting with the Coprocessor
abstract contract BaseContract is ICoprocessorCallback {
    ICoprocessor public coprocessor;
    bytes32 public machineHash;

    /// @notice Tracks whether a computation has been sent for a specific input hash
    mapping(bytes32 => bool) public computationSent;

    /// @notice Emitted when a result is received
    event ResultReceived(bytes output);

    /// @param _coprocessorAddress The address of the ICoprocessor contract
    /// @param _machineHash The machine hash associated with dapp whose logic the coProcessor would run
    constructor(address _coprocessorAddress, bytes32 _machineHash) {
        require(_coprocessorAddress != address(0), "Invalid coprocessor address");
        coprocessor = ICoprocessor(_coprocessorAddress);
        machineHash = _machineHash;
    }

    /// @notice Issues a task to the coprocessor
    /// @param input The input data to process
    function callCoprocessor(bytes calldata input) internal {
        bytes32 inputHash = keccak256(input);

        require(!computationSent[inputHash], "Computation already sent");

        computationSent[inputHash] = true;

        coprocessor.issueTask(machineHash, input, address(this));
    }

    /// @notice Callback function called by the coprocessor with outputs
    /// @param _machineHash The machine hash associated with dapp whose logic the coProcessor would run
    /// @param _payloadHash The hash of the input payload
    /// @param outputs The outputs returned by the coprocessor
    function coprocessorCallbackOutputsOnly(
        bytes32 _machineHash,
        bytes32 _payloadHash,
        bytes[] calldata outputs
    ) external override {
        require(msg.sender == address(coprocessor), "Unauthorized caller");
        require(_machineHash == machineHash, "Machine hash mismatch");
        require(computationSent[_payloadHash], "Computation not found");

        // Process each output
        for (uint256 i = 0; i < outputs.length; i++) {
            bytes calldata output = outputs[i];
            require(output.length > 3, "Output too short");

            bytes4 selector = bytes4(output[:4]);
            bytes calldata arguments = output[4:];

            require(selector == ICoprocessorOutputs.Notice.selector);
            handleCallback(arguments);
        }

        // Clean up the mapping
        delete computationSent[_payloadHash];
    }

    /// @notice Handles a notice from the coprocessor
    /// @param notice The notice data
    function handleCallback(bytes calldata notice) internal virtual {
        emit ResultReceived(notice);
    }
}
