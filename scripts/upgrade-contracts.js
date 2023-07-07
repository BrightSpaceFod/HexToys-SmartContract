require('dotenv').config()
const hre = require('hardhat')

async function main() {
  const ethers = hre.ethers
  const upgrades = hre.upgrades;

  console.log('network:', await ethers.provider.getNetwork())

  const signer = (await ethers.getSigners())[0]
  console.log('signer:', await signer.getAddress())
  
  

  /**
   * Upgrade HexToysMarketV2
   */
   const marketV2 = "0xc16d32ecf660290c9351a9c878d0d482235be233";

   const HexToysMarketV2 = await ethers.getContractFactory('HexToysMarketV2', {
     signer: (await ethers.getSigners())[0]
   })

   const upgradedFactoryContract = await upgrades.upgradeProxy(marketV2, HexToysMarketV2);
   console.log('HexToysMarketV2 upgraded: ', upgradedFactoryContract.address)

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
