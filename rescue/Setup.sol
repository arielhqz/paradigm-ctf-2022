// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

import "./MasterChefHelper.sol";

interface WETH9 is ERC20Like {
    function deposit() external payable;
}

contract Setup {
    
    WETH9 public constant weth = WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    // 定义了一个weth的地址
    MasterChefHelper public immutable mcHelper;
    // 定义了一个合约地址，由import载入

    constructor() payable {
        mcHelper = new MasterChefHelper(); // 新建了一个MasterChefHelper合约
        weth.deposit{value: 10 ether}(); // 把10个eth换成10个weth
        weth.transfer(address(mcHelper), 10 ether); // whoops
        // 不小心把10个weth转移到新建的MasterChefHelper合约中
        // 题面：把误转入的10个weth转回/拯救回来
    }

    function isSolved() external view returns (bool) {
        return weth.balanceOf(address(mcHelper)) == 0;
        // 最终结果合约中的weth为0
    }

}