//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Counter} from "./utils/Counter.sol";
import {Test} from "forge-std-1.9.6/src/Test.sol";
import {SimpleERC20} from "./utils/SimpleERC20.sol";
import {console} from "forge-std-1.9.6/src/console.sol";
import {CoprocessorMock} from "./mock/CoprocessorMock.sol";
import {SafeERC20Transfer} from "./utils/SafeERC20Transfer.sol";
import {ICoprocessorOutputs} from "../src/ICoprocessorOutputs.sol";
import {CoprocessorAdapterSample} from "./utils/CoprocessorAdapterSample.sol";
import {IERC20} from "@openzeppelin-contracts-5.2.0/token/ERC20/IERC20.sol";

contract TestCoprocessorAdapterSampl is Test {
    address caller = vm.addr(4);
    address receiver = vm.addr(5);

    bytes32 machineHash = bytes32(0);

    Counter counter;
    SimpleERC20 token;
    CoprocessorMock mock;
    CoprocessorAdapterSample sample;
    SafeERC20Transfer safeERC20Transfer;

    function setUp() public {
        counter = new Counter();
        mock = new CoprocessorMock();
        safeERC20Transfer = new SafeERC20Transfer();
        sample = new CoprocessorAdapterSample(address(mock), machineHash);
        token = new SimpleERC20(address(sample), 1000);
    }

    function testCallCoprocessorAdapterSampleWithValilNoticeInput() public {
        bytes memory encoded_tx = abi.encodeCall(Counter.setNumber, (1596));
        bytes memory arguments = abi.encode(address(counter), encoded_tx);
        bytes memory notice = abi.encodeCall(ICoprocessorOutputs.Notice, (arguments));

        bytes[] memory outputs = new bytes[](1);
        outputs[0] = notice;

        bytes memory payload = abi.encode("1596");

        vm.expectEmit();
        emit CoprocessorMock.TaskIssued(machineHash, payload, address(sample));
        sample.runExecution(payload);

        vm.prank(address(mock));
        sample.coprocessorCallbackOutputsOnly(machineHash, keccak256(payload), outputs);

        uint256 number = counter.number();
        assertEq(number, 1596);
    }

    function testCallCoprocessorAdapterSampleWithValidVoucherInput() public {
        bytes memory encoded_tx = abi.encodeCall(Counter.setNumber, (1596));
        bytes memory voucher = abi.encodeCall(ICoprocessorOutputs.Voucher, (address(counter), 0, encoded_tx));

        bytes[] memory outputs = new bytes[](1);
        outputs[0] = voucher;

        bytes memory payload = abi.encode("1596");

        vm.expectEmit();
        emit CoprocessorMock.TaskIssued(machineHash, payload, address(sample));

        sample.runExecution(payload);

        vm.prank(address(mock));
        sample.coprocessorCallbackOutputsOnly(machineHash, keccak256(payload), outputs);

        uint256 number = counter.number();
        assertEq(number, 1596);
    }

    function testCallCoprocessorAdapterSampleWithValidVoucherInputAndValue() public {
        bytes memory encoded_tx = abi.encodeCall(IERC20.transfer, (address(receiver), 100));
        bytes memory voucher = abi.encodeCall(ICoprocessorOutputs.Voucher, (address(token), uint256(0), encoded_tx));

        bytes[] memory outputs = new bytes[](1);
        outputs[0] = voucher;

        vm.deal(address(sample), 2024);

        bytes memory payload = abi.encode("1596");

        vm.expectEmit();
        emit CoprocessorMock.TaskIssued(machineHash, payload, address(sample));

        sample.runExecution(payload);

        vm.prank(address(mock));
        sample.coprocessorCallbackOutputsOnly(machineHash, keccak256(payload), outputs);

        assertEq(token.balanceOf(receiver), 100);
    }

    function testCallCoprocessorAdapterSampleWithDelegateCallVoucher() public {
        bytes memory encoded_tx =
            abi.encodeCall(SafeERC20Transfer.safeTransfer, (IERC20(address(token)), address(caller), 500));

        bytes memory delegateCallVoucher =
            abi.encodeCall(ICoprocessorOutputs.DelegateCallVoucher, (address(safeERC20Transfer), encoded_tx));

        bytes[] memory outputs = new bytes[](1);

        outputs[0] = delegateCallVoucher;

        bytes memory payload = abi.encode("1596");

        vm.expectEmit();
        emit CoprocessorMock.TaskIssued(machineHash, payload, address(sample));

        sample.runExecution(payload);

        vm.prank(address(mock));
        sample.coprocessorCallbackOutputsOnly(machineHash, keccak256(payload), outputs);

        assertEq(token.balanceOf(address(caller)), 500);
    }

    function testCallCoprocessorAdapterSampleWithInvalidMachineHash() public {
        bytes memory encoded_tx = abi.encodeCall(Counter.setNumber, (1596));
        bytes memory notice = abi.encodeCall(ICoprocessorOutputs.Notice, (encoded_tx));
        bytes[] memory outputs = new bytes[](1);

        outputs[0] = notice;

        bytes memory payload = abi.encode("1596");

        vm.expectEmit();
        emit CoprocessorMock.TaskIssued(machineHash, payload, address(sample));

        sample.runExecution(payload);

        bytes32 invalidMachineHash = keccak256("1596");

        vm.expectRevert();
        vm.prank(address(mock));
        sample.coprocessorCallbackOutputsOnly(invalidMachineHash, keccak256(payload), outputs);
    }

    function testCallCoprocessorAdapterSampleWithInvalidPayloadHash() public {
        bytes memory encoded_tx = abi.encodeCall(Counter.setNumber, (1596));
        bytes memory arguments = abi.encode(address(counter), encoded_tx);
        bytes memory notice = abi.encodeCall(ICoprocessorOutputs.Notice, (arguments));

        bytes[] memory outputs = new bytes[](1);
        outputs[0] = notice;

        bytes memory payload = abi.encode("1596");

        vm.expectEmit();
        emit CoprocessorMock.TaskIssued(machineHash, payload, address(sample));

        sample.runExecution(payload);

        bytes32 invalidPayloadHash = keccak256("2024");

        vm.expectRevert();
        vm.prank(address(mock));
        sample.coprocessorCallbackOutputsOnly(machineHash, invalidPayloadHash, outputs);
    }
}
