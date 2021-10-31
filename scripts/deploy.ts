const { ethers } = require('hardhat')

import { ContractFactory } from '@ethersproject/contracts'
import { MerkleTree } from 'merkletreejs'
import keccak256 from 'keccak256'

import { MemeNft } from '../src/types/MemeNft'
import { Weth9 } from '../src/types/Weth9'
import { MerkleRoyalties } from '../src/types/MerkleRoyalties'

export function hashToken(account: string, split: number) {
  return Buffer.from(ethers.utils.solidityKeccak256(['address', 'uint256'], [account, split]).slice(2), 'hex')
}

async function main() {
  const [deployer] = await ethers.getSigners()
  const address = await deployer.getAddress()
  const { chainId } = await deployer.provider.getNetwork()

  const MerkleRoyalties = await ethers.getContractFactory('MerkleRoyalties')
  const MemeNft = await ethers.getContractFactory('MemeNFT')
  const Weth = await ethers.getContractFactory('WETH9')

  const weth = (await Weth.deploy()) as Weth9
  const merkleRoyalties = (await MerkleRoyalties.deploy()) as MerkleRoyalties
  const meme = (await MemeNft.deploy('test', weth.address, merkleRoyalties.address)) as MemeNft

  const merkleTree = new MerkleTree([hashToken(deployer.address, 10000)], keccak256)
  await meme.mintPrimary('test', [], 10000, merkleTree.getHexRoot(), ethers.utils.parseEther('1'))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
