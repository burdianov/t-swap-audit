// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {PoolFactory} from "../../src/PoolFactory.sol";
import {TSwapPool} from "../../src/TSwapPool.sol";
import {Handler} from "./Handler.t.sol";

contract Invariant is StdInvariant, Test {
    ERC20Mock poolToken;
    ERC20Mock weth;

    PoolFactory factory;
    TSwapPool pool; // pool token / WETH
    Handler handler;

    uint256 constant STARTING_X = 100e18; // Starting ERC20 / poolToken
    uint256 constant STARTING_Y = 50e18; // Starting WETH

    function setUp() public {
        weth = new ERC20Mock();
        poolToken = new ERC20Mock();
        factory = new PoolFactory(address(weth));
        pool = TSwapPool(factory.createPool(address(poolToken)));

        poolToken.mint(address(this), STARTING_X);
        weth.mint(address(this), STARTING_Y);

        poolToken.approve(address(pool), type(uint256).max);
        weth.approve(address(pool), type(uint256).max);

        pool.deposit(
            STARTING_Y,
            STARTING_Y,
            STARTING_X,
            uint64(block.timestamp)
        );

        handler = new Handler(pool);
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = Handler.deposit.selector;
        selectors[1] = Handler.swapPoolTokenForWethBasedOnOutputWeth.selector;

        targetSelector(
            FuzzSelector({addr: address(handler), selectors: selectors})
        );
        targetContract(address(handler));
    }

    function invariant_constantProductFormulaStaysTheSameX() public view {
        assertEq(handler.actualDeltaX(), handler.expectedDeltaX());
    }

    function invariant_constantProductFormulaStaysTheSameY() public view {
        assertEq(handler.actualDeltaY(), handler.expectedDeltaY());
    }
}
