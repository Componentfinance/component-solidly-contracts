// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import { PairFactory } from "../src/PairFactory.sol";
import { Pair } from "../src/Pair.sol";
import { ERC20, ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract FactoryTest is Test {
    PairFactory public factory;

    function setUp() public {
        factory = new PairFactory();
    }

    function testPairAddressCalc() public {
        address t0 = address(new ERC20("", ""));
        address t1 = address(new ERC20("", ""));

        if (t0 > t1) {
            (t0, t1) = (t1, t0);
        }

        bytes32 saltStable = keccak256(abi.encodePacked(t0, t1, true));
        address expectedStablePairAddress = computeCreate2Address(saltStable, factory.pairCodeHash(), address(factory));
        address stablePair = factory.createPair(t0, t1, true);
        assertEq(stablePair, expectedStablePairAddress);

        bytes32 saltVolatile = keccak256(abi.encodePacked(t0, t1, false));
        address expectedVolatilePairAddress = computeCreate2Address(saltVolatile, factory.pairCodeHash(), address(factory));
        address volatilePair = factory.createPair(t0, t1, false);
        assertEq(volatilePair, expectedVolatilePairAddress);
    }

    function testMintSwapBurn() public {
        ERC20Mock t0 = new ERC20Mock();
        ERC20Mock t1 = new ERC20Mock();

        if (address(t0) > address(t1)) {
            (t0, t1) = (t1, t0);
        }

        factory.createPair(address(t0), address(t1), true);

        Pair pair = Pair(factory.getPair(address(t0), address(t1), true));

        t0.mint(address(pair), 1e18);
        t1.mint(address(pair), 1e18);

        pair.mint(address(this));

        uint minted = pair.balanceOf(address(this));
        assertEq(minted, 1e18 - 1000);

        t0.mint(address(pair), 100);

        uint amount1Out;

        amount1Out = 99;

        pair.swap(0, amount1Out, address(this), new bytes(0));
        assertEq(t1.balanceOf(address(this)), 99);

        pair.transfer(address(pair), 1e18 - 1000);
        pair.burn(address(1));

        assertEq(pair.balanceOf(address(pair)), 0);
        assertGt(t0.balanceOf(address(1)), 0);
        assertGt(t1.balanceOf(address(1)), 0);
    }
}
