require('dotenv').config()
const hre = require('hardhat')

async function main() {
  const ethers = hre.ethers
  const upgrades = hre.upgrades;

  console.log('network:', await ethers.provider.getNetwork())

  const signer = (await ethers.getSigners())[0]
  console.log('signer:', await signer.getAddress())
  
  

  /**
   * Upgrade MultipleFixed
   */
   const multipleFixedAddress = "0x3a12fbd965ca1b8358b6800a638ded2728b267d5";

   const MultipleFixedV2 = await ethers.getContractFactory('MultipleFixed', {
     signer: (await ethers.getSigners())[0]
   })

   const upgradedFactoryContract = await upgrades.upgradeProxy(multipleFixedAddress, MultipleFixedV2);
   console.log('MultipleFixed upgraded: ', upgradedFactoryContract.address)

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
