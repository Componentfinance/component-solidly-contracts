// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { PairFactory } from "../src/PairFactory.sol";
import { Router } from "../src/Router.sol";

contract DeployFactoryRouterGnosis is Script {
    uint key;

    address weth;

    function setUp() public {
        key = vm.envUint("PRIVATE_KEY");
        weth = 0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d;
    }

    function run() public {
        vm.startBroadcast(key);

        address factory = address(new PairFactory());
        new Router(factory, weth);
    }
}
