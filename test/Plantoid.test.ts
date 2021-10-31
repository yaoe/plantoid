import { ethers } from 'hardhat'
import { solidity } from 'ethereum-waffle'
import { use, expect } from 'chai'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'

import { Plantoid } from '../src/types/Plantoid'
import { PlantoidSpawn } from '../src/types/PlantoidSpawn'
import { Wallet } from '@ethersproject/wallet'
import { ContractFactory, ContractTransaction } from '@ethersproject/contracts'
import { BaseProvider } from '@ethersproject/providers'

use(solidity)

// chai
//   .use(require('chai-as-promised'))
//   .should();

const zeroAddress = '0x0000000000000000000000000000000000000000'

const testKey = '0xdd631135f3a99e4d747d763ab5ead2f2340a69d2a90fab05e20104731365fde3'

const getNewPlantoidAddress = async (tx: ContractTransaction): Promise<string> => {
    const receipt = await ethers.provider.getTransactionReceipt(tx.hash)
    let plantoidSummonAbi = ['event PlantoidSpawned(address indexed plantoid, address indexed artist)']
    let iface = new ethers.utils.Interface(plantoidSummonAbi)
    let log = iface.parseLog(receipt.logs[0])
    const { plantoid } = log.args
    return plantoid
}

describe('Plantoid NFT', function () {
  let plantoidInstance: Plantoid
  let plantoidSpawn: PlantoidSpawn
  let plantoidAsApplicant: Plantoid
  let plantoidAsSupporter: Plantoid

  let plantoidOracle: Wallet
  let firstCreator: SignerWithAddress
  let applicant: SignerWithAddress
  let supporter: SignerWithAddress

  let Plantoid: ContractFactory
  let PlantoidSpawn: ContractFactory

  let provider: BaseProvider

  this.beforeAll(async function () {
    const adminAbstract = new ethers.Wallet(testKey)
    provider = ethers.provider
    plantoidOracle = await adminAbstract.connect(provider)
    ;[firstCreator, applicant, supporter] = await ethers.getSigners()
    Plantoid = await ethers.getContractFactory('Plantoid')
    PlantoidSpawn = await ethers.getContractFactory('PlantoidSpawn')
    const plantoidAbstract = (await Plantoid.deploy()) as Plantoid
    plantoidSpawn = (await PlantoidSpawn.deploy(plantoidAbstract.address)) as PlantoidSpawn
  })

  beforeEach(async function () {
    const tx = await plantoidSpawn.spawnPlantoid(plantoidOracle.address, firstCreator.address)
    const plantoid = await getNewPlantoidAddress(tx)
    plantoidInstance = (await Plantoid.attach(plantoid)) as Plantoid

    plantoidAsSupporter = plantoidInstance.connect(supporter)
    plantoidAsApplicant = plantoidInstance.connect(applicant)
  })

  describe('constructor', function () {
    it('verify deployment parameters', async function () {
      expect(await plantoidInstance.artist()).to.equal(firstCreator.address)
      expect(await plantoidInstance.plantoidAddress()).to.equal(plantoidOracle.address)
    })

    describe('donation', function () {
      it('Allows supporter to donate ETH', async function () {
        const balanceBefore = await provider.getBalance(plantoidInstance.address)
        await supporter.sendTransaction({ to: plantoidInstance.address, value: ethers.utils.parseEther('1') })
        const balanceAfter = await provider.getBalance(plantoidInstance.address)
        expect(balanceBefore).to.equal(0)
        expect(balanceAfter).to.equal(ethers.utils.parseEther('1'))
      })
    })
  })

  describe('minting', function () {
    it('Allows supporter to mint with signature from plantoid oracle', async function () {
      const nonce = 1
      const testUri = 'test'
      console.log({ plantoidOracle: plantoidOracle.address })
      const msgHash = ethers.utils.arrayify(
        ethers.utils.solidityKeccak256(['uint256', 'string', 'address', 'address'], [nonce, testUri, supporter.address, plantoidInstance.address])
      )
      const sig = await plantoidOracle.signMessage(msgHash)
      await plantoidAsSupporter.mintSeed(nonce, supporter.address, testUri, sig)
      expect(await plantoidInstance.balanceOf(supporter.address)).to.equal(1)
    })
  })

  describe('proposals, voting', function () {
    it('Allows people to submit prop if threshold is reached', async function () {
      await supporter.sendTransaction({ to: plantoidInstance.address, value: ethers.utils.parseEther('3') })
      await plantoidAsApplicant.submitProposal(0, 'test.com')
      expect(await plantoidInstance.proposalCounter(0)).to.equal(1)
      const proposal = await plantoidInstance.proposals(0, 1)
      expect(proposal.proposalUri).to.equal('test.com')
      expect(proposal.proposer).to.equal(applicant.address)
    })

    it('Allows people to submit vote if threshold is reached', async function () {
      const nonce = 1
      const testUri = 'test'
      const msgHash = ethers.utils.arrayify(
        ethers.utils.solidityKeccak256(['uint256', 'string', 'address', 'address'], [nonce, testUri, supporter.address, plantoidInstance.address])
      )
      const sig = await plantoidOracle.signMessage(msgHash)
      await plantoidAsSupporter.mintSeed(nonce, supporter.address, testUri, sig)

      await supporter.sendTransaction({ to: plantoidInstance.address, value: ethers.utils.parseEther('3') })
      await plantoidAsApplicant.submitProposal(0, 'test.com')
      await plantoidAsSupporter.submitVote(0, 1, [1])
      expect(await plantoidInstance.votes(0, 1)).to.equal(1)
      expect(await plantoidInstance.voted(0, 1)).to.equal(true)
    })

    it('Allows creator to accept winner', async function () {
      const nonce = 1
      const testUri = 'test'
      const msgHash = ethers.utils.arrayify(
        ethers.utils.solidityKeccak256(['uint256', 'string', 'address', 'address'], [nonce, testUri, supporter.address, plantoidInstance.address])
      )
      const sig = await plantoidOracle.signMessage(msgHash)
      await plantoidAsSupporter.mintSeed(nonce, supporter.address, testUri, sig)

      await supporter.sendTransaction({ to: plantoidInstance.address, value: ethers.utils.parseEther('3') })
      await plantoidAsApplicant.submitProposal(0, 'test.com')
      await plantoidAsSupporter.submitVote(0, 1, [1])
      await plantoidInstance.acceptWinner(0, 1)
    })
    
    it('Allows winner to spawn new plantoid and sends ETH to creator', async function () {
      const nonce = 1
      const testUri = 'test'
      const msgHash = ethers.utils.arrayify(
        ethers.utils.solidityKeccak256(['uint256', 'string', 'address', 'address'], [nonce, testUri, supporter.address, plantoidInstance.address])
      )
      const sig = await plantoidOracle.signMessage(msgHash)
      await plantoidAsSupporter.mintSeed(nonce, supporter.address, testUri, sig)

      await supporter.sendTransaction({ to: plantoidInstance.address, value: ethers.utils.parseEther('3') })
      await plantoidAsApplicant.submitProposal(0, 'test.com')
      await plantoidAsSupporter.submitVote(0, 1, [1])
      await plantoidInstance.acceptWinner(0, 1)
      
      const tx = await plantoidAsApplicant.spawn(plantoidOracle.address)
      const plantoid = await getNewPlantoidAddress(tx)
      
      const newPlantoid = (await Plantoid.attach(plantoid)) as Plantoid
      
      expect(await newPlantoid.artist()).to.equal(applicant.address)
    })
  })
})
