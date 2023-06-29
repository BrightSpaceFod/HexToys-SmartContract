require('dotenv').config()
const hre = require('hardhat')

async function main() {
  const ethers = hre.ethers
  const upgrades = hre.upgrades;

  console.log('network:', await ethers.provider.getNetwork())

  const signer = (await ethers.getSigners())[0]
  console.log('signer:', await signer.getAddress())
  
  

  /**
   * Upgrade HexToysMultipleFixed
   */
   const multipleFixedAddress = "0x3a12fbd965ca1b8358b6800a638ded2728b267d5";

   const HexToysMultipleFixedV2 = await ethers.getContractFactory('HexToysMultipleFixed', {
     signer: (await ethers.getSigners())[0]
   })

   const upgradedFactoryContract = await upgrades.upgradeProxy(multipleFixedAddress, HexToysMultipleFixedV2);
   console.log('HexToysMultipleFixed upgraded: ', upgradedFactoryContract.address)

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
