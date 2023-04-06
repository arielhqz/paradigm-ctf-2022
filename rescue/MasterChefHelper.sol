// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

import "./UniswapV2Like.sol";

interface ERC20Like {
    function transferFrom(address, address, uint) external;
    function transfer(address, uint) external;
    function approve(address, uint) external;
    function balanceOf(address) external view returns (uint);
}

interface MasterChefLike {
    function poolInfo(uint256 id) external returns (
        address lpToken,
        uint256 allocPoint,
        uint256 lastRewardBlock,
        uint256 accSushiPerShare
    );
} // 有两个接口

contract MasterChefHelper {

    MasterChefLike public constant masterchef = MasterChefLike(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);
    UniswapV2RouterLike public constant router = UniswapV2RouterLike(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    // 可以做swap的合约

    function swapTokenForPoolToken(uint256 poolId, address tokenIn, uint256 amountIn, uint256 minAmountOut) external {
        // 整个合约三个函数，只有这个函数能外部调用
        (address lpToken,,,) = masterchef.poolInfo(poolId);
        // 拿到该流动池的poolId
        address tokenOut0 = UniswapV2PairLike(lpToken).token0();
        address tokenOut1 = UniswapV2PairLike(lpToken).token1();
        // 找到poolId对应的pair

        ERC20Like(tokenIn).approve(address(router), type(uint256).max);
        ERC20Like(tokenOut0).approve(address(router), type(uint256).max);
        ERC20Like(tokenOut1).approve(address(router), type(uint256).max);
        // 这三个是授权转移，能转移tokenIn、tokenOut0、tokenOut1
        ERC20Like(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        // 把用户的钱转移到该合约地址中

        // swap for both tokens of the lp pool
        _swap(tokenIn, tokenOut0, amountIn / 2);
        _swap(tokenIn, tokenOut1, amountIn / 2);
        // 把用户打入的钱，对半分，分别换成该pair的两种token

        // add liquidity and give lp tokens to msg.sender
        _addLiquidity(tokenOut0, tokenOut1, minAmountOut);
        // 把换得的该pair的两种token，都加入流动池
    }

    function _addLiquidity(address token0, address token1, uint256 minAmountOut) internal {
        (,, uint256 amountOut) = router.addLiquidity(
            token0, 
            token1, 
            ERC20Like(token0).balanceOf(address(this)), 
            ERC20Like(token1).balanceOf(address(this)), 
            // 关键点在这，balanceOf，添加该地址下全部量的该代币
            // 一般情况，添加输入量代币
            // 在该题中，保证token0或token1为weth，即可保证该合约中最终没有weth
            // 所以，往回推，在最开始输入含weth pair的poolId，然后调用这个合约，就能把合约中的weth转入流动池
            0, 
            0, 
            msg.sender, 
            block.timestamp
        );
        require(amountOut >= minAmountOut);
    }

    function _swap(address tokenIn, address tokenOut, uint256 amountIn) internal {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        router.swapExactTokensForTokens(
            amountIn,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
}