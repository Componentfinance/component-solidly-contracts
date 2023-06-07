// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IPairFactory {
    function allPairsLength() external view returns (uint);
    function getFee(address _pair, bool _isStable) external view returns (uint);
    function isPair(address pair) external view returns (bool);
    function getPair(address tokenA, address token, bool stable) external view returns (address);
    function createPair(address tokenA, address tokenB, bool stable) external returns (address pair);
    function voter() external view returns (address);
    function pairCodeHash() external pure returns (bytes32);
    function getInitializable() external view returns (address, address, bool);
}