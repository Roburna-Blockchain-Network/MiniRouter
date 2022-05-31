// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";



contract GooseBumpsMiniRouter is Ownable {
    
    IERC20 public empire;
    address public EMPIRE_ADDRESS;


    mapping(uint256 => address) public idToRouter;
    mapping(address => bool) public supportsRouter;
    ///@notice router addr + second token addr = pair addr
    mapping(address => mapping(address => address)) public pairAddr;
    mapping(address => bool) public pairExists;

    event LogSetRouter(address router);
    event LogSetPair(address pair);
    event LogDeleteRouter(address router);
    event LogDeletePair(address pair);
    event LogUpdateEmpire(IERC20 empire);
    event LogUpdateEmpireAddress(address empire);
    event LogAddLiquidityETH(address recipient, uint256 empireAmount, uint256 ethAmount, address router);
    event LogAddLiquidityTokens(address recipient, address tokenB, uint256 empireAmount, uint256 tokenBAmount, address router);
    event LogRemoveLiquidityETH(address recipient, uint256 liquidity, address router);
    event LogRemoveLiquidityTokens(address recipient, uint256 liquidity, address router, address tokenB);
    
    constructor(address _empire, address router, uint256 routerId, address pair){
        EMPIRE_ADDRESS = _empire;
        empire = IERC20(_empire);

        setRouter(router, routerId);
        address tokenB = IUniswapV2Router02(router).WETH();
        setPair(tokenB, router, pair);   
    }

    function updateEmpireAddress(address _empire) external onlyOwner{
        require(EMPIRE_ADDRESS != _empire, "GooseBumpsMiniRouter: Already set to this address");
        EMPIRE_ADDRESS = _empire;
        emit LogUpdateEmpireAddress(_empire);
    }

    function updateEmpire(IERC20 _empire) external onlyOwner{
        require(empire != _empire, "GooseBumpsMiniRouter: Already set to this address");
        empire = _empire;
        emit LogUpdateEmpire(_empire);
    }

    function setRouter(address router, uint256 routerId) public onlyOwner{
        require(supportsRouter[router] != true, "GooseBumpsMiniRouter: Router exists");
        idToRouter[routerId] = router;
        supportsRouter[router] = true;
        emit LogSetRouter(router);
    }

    function setPair(address tokenB, address router, address pair) public onlyOwner{
        require(pairExists[pair] != true, "GooseBumpsMiniRouter: Pair exists");
        pairAddr[router][tokenB] = pair;
        pairExists[pair] = true;
        emit LogSetPair(pair);
    }

    function deleteRouter(address router) external onlyOwner{
        require(supportsRouter[router] = true, "GooseBumpsMiniRouter: Router does not exist");
        supportsRouter[router] = false;
        emit LogDeleteRouter(router);
    }

    function deletePair(address pair) external onlyOwner{
        require(pairExists[pair] = true, "GooseBumpsMiniRouter: Pair does not exist");
        pairExists[pair] = false;
        emit LogDeletePair(pair);
    }

    function createPair(address router, address tokenB) external onlyOwner {
       address checkPair = IUniswapV2Factory(IUniswapV2Router02(router).factory()).getPair(EMPIRE_ADDRESS, tokenB);
       require(checkPair == address(0), "GooseBumpsMiniRouter: Pair exists");
       address pair = IUniswapV2Factory(IUniswapV2Router02(router).factory())
           .createPair(EMPIRE_ADDRESS, tokenB);
       
       setPair(tokenB, router, pair); 
    }

    function addLiquidityETH(uint256 empireAmount, uint256 ethAmount, uint256 routerId) external payable{
        require(ethAmount == msg.value, "GooseBumpsMiniRouter: ETH amount should be equal msg.value");
        address router = idToRouter[routerId];
        address recipient = _msgSender();
        address pair = pairAddr[router][IUniswapV2Router02(router).WETH()];
        require(pairExists[pair] = true, "GooseBumpsMiniRouter: The pair is not supported");
        require(supportsRouter[router] = true, "GooseBumpsMiniRouter: The Router is not supported");
        require(empire.approve(router, empireAmount), "GooseBumpsMiniRouter: Approve failed");
        require(empire.transferFrom(msg.sender, address(this), empireAmount), "GooseBumpsMiniRouter: TransferFrom failed");
        IUniswapV2Router02(router).addLiquidityETH{value: ethAmount}(
            EMPIRE_ADDRESS,
            empireAmount,
            0,
            0,
            recipient,
            block.timestamp + 1200
        );

        emit LogAddLiquidityETH(recipient, empireAmount, ethAmount, router);
    }

    function addLiquidityTokens(address tokenB, uint256 empireAmount, uint256 tokenBAmount, uint256 routerId) external {
        address router = idToRouter[routerId];
        address recipient = _msgSender();
        address pair = pairAddr[router][tokenB];
        require(pairExists[pair] = true, "GooseBumpsMiniRouter: The pair is not supported");
        require(supportsRouter[router] = true, "GooseBumpsMiniRouter: The Router is not supported");
        require(empire.transferFrom(msg.sender, address(this), empireAmount), "GooseBumpsMiniRouter: TransferFrom failed");
        require(empire.approve(router, empireAmount), "GooseBumpsMiniRouter: Approve failed");
        require(IERC20(tokenB).transferFrom(msg.sender, address(this), tokenBAmount), "GooseBumpsMiniRouter: TransferFrom failed");
        require(IERC20(tokenB).approve(router , tokenBAmount), "GooseBumpsMiniRouter: Approve failed");
        IUniswapV2Router02(router).addLiquidity(
            EMPIRE_ADDRESS,
            tokenB,
            empireAmount,
            tokenBAmount,
            0,
            0,
            recipient,
            block.timestamp + 1200
        );

        emit LogAddLiquidityTokens(recipient, tokenB, empireAmount, tokenBAmount, router);
    }

    function removeLiquidityTokens(address tokenB, uint256 liquidity, uint256 routerId) external {
        address router = idToRouter[routerId];
        address recipient = _msgSender();
        address pair = pairAddr[router][tokenB];
        require(pairExists[pair] = true, "GooseBumpsMiniRouter: Pair does not exist");
        require(supportsRouter[router] = true, "GooseBumpsMiniRouter: The Router is not supported");
        require(IUniswapV2Pair(pair).transferFrom(msg.sender, address(this), liquidity), "GooseBumpsMiniRouter: TransferFrom failed");
        require(IUniswapV2Pair(pair).approve(router, liquidity), "GooseBumpsMiniRouter: Approve failed");
        IUniswapV2Router02(router).removeLiquidity(
            EMPIRE_ADDRESS,
            tokenB,
            liquidity,
            0,
            0,
            recipient,
            block.timestamp + 1200
        );

        emit LogRemoveLiquidityTokens(recipient, liquidity, router, tokenB);
    }

    function removeLiquidityETH(uint256 liquidity, uint256 routerId) external {
        address router = idToRouter[routerId];
        address recipient = _msgSender();
        address pair = pairAddr[router][IUniswapV2Router02(router).WETH()];
        require(pairExists[pair] = true, "GooseBumpsMiniRouter: Pair does not exist");
        require(IUniswapV2Pair(pair).transferFrom(msg.sender, address(this), liquidity), "GooseBumpsMiniRouter: TransferFrom failed");
        require(IUniswapV2Pair(pair).approve(router, liquidity), "GooseBumpsMiniRouter: Approve failed");
        IUniswapV2Router02(router).removeLiquidityETHSupportingFeeOnTransferTokens(
            EMPIRE_ADDRESS,
            liquidity,
            0,
            0,
            recipient,
            block.timestamp + 1200
        );

        emit LogRemoveLiquidityETH(recipient, liquidity, router);
    }
}