const { parseFixed } = require("@ethersproject/bignumber");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Test", function () {
  before(async function () {

    this.signers = await ethers.getSigners()
    this.owner = this.signers[0]
    this.alice = this.signers[3]
    this.bob = this.signers[4]
    this.marketingWallet = this.signers[1]
    this.teamWallet = this.signers[2]
    this.vault = this.signers[5]
    this.provider = await ethers.provider
    this.router = await new ethers.Contract('0x10ED43C718714eb63d5aA57B78B54704E256024E', ['function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity)', 'function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts)', 'function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts)', 'function swapExactTokensForETHSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external'], this.provider)
    
    const RouterWSigner = await this.router.connect(this.owner)
    this.Token = await ethers.getContractFactory("EmpireToken")
    this.token = await this.Token.deploy("0x10ED43C718714eb63d5aA57B78B54704E256024E", this.marketingWallet.address, this.teamWallet.address, this.vault.address)
    await this.token.deployed()

    this.Busd = await ethers.getContractFactory("MockBUSD")
    this.busd = await this.Busd.deploy()
    await this.busd.deployed()

    await this.token.setEnableTrading(true)
    await this.token.approve('0x10ED43C718714eb63d5aA57B78B54704E256024E', 900000000000000);
    await RouterWSigner.addLiquidityETH(
      this.token.address,
      90000000000000,
      90000000000000,
      ethers.utils.parseEther("200"),
      this.owner.address ,
      Math.floor(Date.now() / 1000) + 60 * 10,
      {value : ethers.utils.parseEther("200")}
    );
    const pair = await this.token.uniswapV2Pair()
    const MiniRouter = await ethers.getContractFactory("GooseBumpsMiniRouter")
    this.miniRouter = await MiniRouter.deploy(this.token.address, '0x10ED43C718714eb63d5aA57B78B54704E256024E', 1, pair);
    await this.miniRouter.deployed();

    await this.token.setExcludeFromFee(this.miniRouter.address, true)
    //await this.token.setExcludeFromFee("0x10ED43C718714eb63d5aA57B78B54704E256024E", true)
    await this.token.transfer(this.alice.address, 90000000000000)

    const pairAddr = await this.token.uniswapV2Pair()
    const pairr = await ethers.getContractAt("IUniswapV2Pair", pairAddr);
    const lpBalance = await pairr.balanceOf(this.owner.address);
    await console.log(lpBalance)
  })
  
  it("should create and set pair correctly", async function(){
    await this.miniRouter.createPair(this.router.address, this.busd.address)
    let pair = await this.miniRouter.pairAddr(this.router.address, this.busd.address)
    expect(pair).not.equal("0x0000000000000000000000000000000000000000")


    let WBNB = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c"
    
    expect(await this.miniRouter.createPair(this.router.address, WBNB)).to.be.revertedWith("GooseBumpsMiniRouter: Pair exists")
    
  })

  it("addLiquidityETH", async function () {
    await this.token.connect(this.alice).approve(this.miniRouter.address, 900000000000000);
    await this.miniRouter.connect(this.alice).addLiquidityETH(20000000000000, ethers.utils.parseEther("10"), 1, { value: ethers.utils.parseEther("10") })
  });

  it("removeLiquidityETH", async function () {
   
    const pairAddr = await this.token.uniswapV2Pair()
    const pair = await ethers.getContractAt("IUniswapV2Pair", pairAddr);
    const lpBalance = await pair.balanceOf(this.alice.address);
    await console.log(lpBalance)
    await pair.connect(this.alice).approve(this.miniRouter.address, lpBalance);
    await pair.connect(this.alice).approve("0x10ed43c718714eb63d5aa57b78b54704e256024e", lpBalance);
    await this.miniRouter.connect(this.alice).removeLiquidityETH(lpBalance, 1)
    
    
  });

  it("addLiquidityTokens", async function () {
   
   
    await this.token.approve(this.miniRouter.address, 900000000000000);
    await this.busd.approve(this.miniRouter.address, ethers.utils.parseEther("10000"));
    await this.miniRouter.addLiquidityTokens(this.busd.address, 20000000000000, ethers.utils.parseEther("10000"), 1)
    
    
    
  });

  //it("removeLiquidityTokens", async function () {
  // 
  //  const pairAddr = await this.miniRouter.pairAddr(this.router.address, this.busd.address)
  //  const pair = await ethers.getContractAt("IUniswapV2Pair", pairAddr);
  //  const lpBalance = await pair.balanceOf(this.owner.address);
  //  await console.log(lpBalance)
  //  await pair.approve(this.miniRouter.address, lpBalance);
  //  await pair.approve("0x10ed43c718714eb63d5aa57b78b54704e256024e", lpBalance);
  //  await this.miniRouter.removeLiquidityETH(lpBalance, 1)
  //  
  //  
  //});

});