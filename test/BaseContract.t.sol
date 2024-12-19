// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/BaseContract.sol";
import "../src/ICoprocessor.sol";
import "../src/ICoprocessorCallback.sol";

contract MockCoprocessor is ICoprocessor {
    event TaskIssued(bytes32 machineHash, bytes input, address callback);

    function issueTask(bytes32 machineHash, bytes calldata input, address callback) external override {
        emit TaskIssued(machineHash, input, callback);
    }
}

contract TestBaseContract is BaseContract {
    constructor(address _coprocessorAddress, bytes32 _machineHash) BaseContract(_coprocessorAddress, _machineHash) {}


    function handleCallCoProcessor(bytes calldata input) external {
        callCoprocessor(input);
    }
}

contract BaseContractTest is Test {
    MockCoprocessor public mockCoprocessor;
    TestBaseContract public testBaseContract;

    bytes32 constant MACHINE_HASH = keccak256("machine_hash");

    function setUp() public {
        // Deploy the mock coprocessor
        mockCoprocessor = new MockCoprocessor();

        // Deploy the test contract
        testBaseContract = new TestBaseContract(address(mockCoprocessor), MACHINE_HASH);
    }

    function testInitialization() public view {
        assertEq(address(testBaseContract.coprocessor()), address(mockCoprocessor), "Coprocessor address mismatch");
        assertEq(testBaseContract.machineHash(), MACHINE_HASH, "Machine hash mismatch");
    }

    function testCallCoprocessor() public {
        bytes memory input = "test input";
        bytes32 inputHash = keccak256(input);

        // Expect the issueTask event
        vm.expectEmit(true, true, true, true);
        emit MockCoprocessor.TaskIssued(MACHINE_HASH, input, address(testBaseContract));

        testBaseContract.handleCallCoProcessor(input);

        // Ensure computationSent is updated
        assertTrue(testBaseContract.computationSent(inputHash), "ComputationSent should be true");
    }
}
