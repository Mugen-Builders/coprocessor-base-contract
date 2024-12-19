// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./ICoprocessor.sol";
import "./ICoprocessorCallback.sol";

/// @title BaseContract
/// @notice A base contract, which should be inherited for interacting with the Coprocessor
abstract contract BaseContract is ICoprocessorCallback {
    ICoprocessor public coprocessor;
    bytes32 public machineHash;

    error UnauthorizedCaller(address caller);
    error InvalidOutputLength(uint256 length);
    error ComputationNotFound(bytes32 payloadHash);
    error MachineHashMismatch(bytes32 current, bytes32 expected);
    error InvalidOutputSelector(bytes4 selector, bytes4 expected);

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
    function coprocessorCallbackOutputsOnly(bytes32 _machineHash, bytes32 _payloadHash, bytes[] calldata outputs)
        external
        override
    {
        if (msg.sender != address(coprocessor)) {
            revert UnauthorizedCaller(msg.sender);
        }

        if (_machineHash != machineHash) {
            revert MachineHashMismatch(_machineHash, machineHash);
        }

        if (!computationSent[_payloadHash]) {
            revert ComputationNotFound(_payloadHash);
        }

        for (uint256 i = 0; i < outputs.length; i++) {
            bytes calldata output = outputs[i];

            if (output.length <= 3) {
                revert InvalidOutputLength(output.length);
            }

            bytes4 selector = bytes4(output[:4]);
            bytes calldata arguments = output[4:];

            if (selector != ICoprocessorOutputs.Notice.selector) {
                revert InvalidOutputSelector(selector, ICoprocessorOutputs.Notice.selector);
            }

            handleNotice(arguments);
        }

        delete computationSent[_payloadHash];
    }

    /// @notice Handles a notice from the coprocessor
    /// @param notice The notice data
    function handleNotice(bytes calldata notice) internal virtual {
        emit ResultReceived(notice);
    }
}
