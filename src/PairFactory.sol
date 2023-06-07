// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IPairFactory } from "./interfaces/IPairFactory.sol";
import { Pair } from "./Pair.sol";

contract PairFactory is IPairFactory {
    address public voter;
    uint256 public stableFee;
    uint256 public volatileFee;
    uint256 public constant MAX_FEE = 500; // 5%
    address public feeManager;
    address public pendingFeeManager;

    mapping(address => mapping(address => mapping(bool => address))) public getPair;

    address[] public allPairs;

    mapping(address => bool) public isPair; // simplified check if its a pair, given that `stable` flag might not be available in peripherals

    address internal _temp0;
    address internal _temp1;
    bool internal _temp;

    struct CustomFee {
        bool enabled;
        uint16 value;
    }
    
    mapping(address => CustomFee) public customFee;

    event PairCreated(
        address indexed token0,
        address indexed token1,
        bool stable,
        address pair,
        uint256
    );
    
    event CustomFeeChanged(address indexed pair, bool enabled, uint value);
    event VolatileFeeChanged(uint value);
    event StableFeeChanged(uint value);

    constructor () {
        feeManager = msg.sender;
        stableFee = 2; // 0.02%
        volatileFee = 2;
    }

    // we will deploy `voter` and all the ve-related stuff later
    function setVoter(address _voter) external {
        require(voter == address(0), "initialized");
        require(msg.sender == address(feeManager), "initialized");
        voter = _voter;
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function setFeeManager(address _feeManager) external {
        require(msg.sender == feeManager, "auth failed");
        pendingFeeManager = _feeManager;
    }

    function acceptFeeManager() external {
        require(msg.sender == pendingFeeManager, "not pending fee manager");
        feeManager = pendingFeeManager;
    }

    function setVolatileFee(uint256 _fee) external {
        require(msg.sender == feeManager, "auth failed");
        require(_fee <= MAX_FEE, "fee too high");
        volatileFee = _fee;
        emit VolatileFeeChanged(_fee);
    }

    function setStableFee(uint256 _fee) external {
        require(msg.sender == feeManager, "auth failed");
        require(_fee <= MAX_FEE, "fee too high");
        stableFee = _fee;
        emit StableFeeChanged(_fee);
    }

    // pass 3735928559 to disable
    function setCustomFee(address _pair, uint256 _fee) external {
        require(msg.sender == feeManager, "auth failed");
        CustomFee memory feeConfig;
        if (_fee != 0xdeadbeef) {
            require(_fee <= MAX_FEE, "fee too high");
            feeConfig = CustomFee(true, uint16(_fee));
        }
        customFee[_pair] = feeConfig;
        emit CustomFeeChanged(_pair, feeConfig.enabled, feeConfig.value);
    }

    function getFee(address _pair, bool _stable) public view returns (uint256) {
        CustomFee memory feeConfig = customFee[_pair];
        if (feeConfig.enabled) {
            return feeConfig.value;
        }
        return _stable ? stableFee : volatileFee;
    }

    function createPair(address tokenA, address tokenB, bool stable) external returns (address pair) {
        require(tokenA != tokenB, 'IA'); // Pair: IDENTICAL_ADDRESSES
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ZA'); // Pair: ZERO_ADDRESS
        require(getPair[token0][token1][stable] == address(0), 'PE'); // Pair: PAIR_EXISTS - single check is sufficient
        bytes32 salt = keccak256(abi.encodePacked(token0, token1, stable)); // notice salt includes stable as well, 3 parameters
        (_temp0, _temp1, _temp) = (token0, token1, stable);
        pair = address(new Pair{salt:salt}());
        getPair[token0][token1][stable] = pair;
        getPair[token1][token0][stable] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        isPair[pair] = true;
        emit PairCreated(token0, token1, stable, pair, allPairs.length);
    }

    function pairCodeHash() external pure returns (bytes32) {
        return keccak256(abi.encodePacked(type(Pair).creationCode));
    }

    function getInitializable() external view returns (address, address, bool) {
        return (_temp0, _temp1, _temp);
    }
}