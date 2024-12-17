// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {BaseContract} from "../src/BaseContract.sol";

contract CounterScript is Script {
    BaseContract public baseContract;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // baseContract = new BaseContract();

        vm.stopBroadcast();
    }
}
