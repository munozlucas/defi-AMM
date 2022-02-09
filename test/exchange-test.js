/* eslint-disable no-undef */
const { expect } = require('chai')
const { ethers, waffle } = require('hardhat')
const { provider } = waffle

describe('Exchange', function () {

  let token
  let exchange

  const amountA = ethers.utils.parseEther('2000')
  const amountB = ethers.utils.parseEther('1000')

  beforeEach(async () => {
    const Token = await ethers.getContractFactory('LucasCoin')
    token = await Token.deploy(ethers.utils.parseEther('10000'))
    await token.deployed()

    const Exchange = await ethers.getContractFactory('Exchange')
    exchange = await Exchange.deploy(token.address)
    await exchange.deployed()

    /**
     * En este punto tengo una cuenta con 1000 de LucasCoin y un Exchange
     * conectado a LucasCoin.
     * Ya puedo agregar liquidity desde la cuenta que tiene los tokens
    */ 
  })

  it('Adds liquidity', async function () {
    await token.approve(exchange.address, 200)
    await exchange.addLiquidity(200, { value: 100 })

    expect(await provider.getBalance(exchange.address)).to.equal(100)
    expect(await exchange.getReserve()).to.equal(200)
  })


  it('Returns the right amount of token', async function () {
    await token.approve(exchange.address, amountA)
    await exchange.addLiquidity(amountA, { value: amountB })

    /**
      * en el balance hay 2000 de ether y 1000 de token
      * si pongo 1 ether recibo 1.99 tokens
    */ 
    let tokenOut = await exchange.getTokenAmount(ethers.utils.parseEther('1'))

    expect(ethers.utils.formatEther(tokenOut)).to.equal('1.998001998001998001')
  })

  it('Returns the right amount of ether', async function () {
    await token.approve(exchange.address, amountA)
    await exchange.addLiquidity(amountA, { value: amountB })

    /**
      * en el balance hay 2000 de ether y 1000 de token
      * si pongo 2 token recibo 0.99 ethers
    */ 
    let ethOut = await exchange.getEthAmount(ethers.utils.parseEther('2'))

    expect(ethers.utils.formatEther(ethOut)).to.equal('0.999000999000999')
  })
})
