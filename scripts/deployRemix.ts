const { ethers } = require('hardhat')

import { RemixNft } from '../src/types/RemixNft'

async function main() {
  const [deployer] = await ethers.getSigners()
  
    const RemixNft = await ethers.getContractFactory('RemixNFT')

  const remix = (await RemixNft.deploy()) as RemixNft
      // await remix.mintPrimary("test", [], [])

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
