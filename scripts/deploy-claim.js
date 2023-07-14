require('dotenv').config()
const hre = require('hardhat')

const sleep = (delay) => new Promise((resolve) => setTimeout(resolve, delay * 1000));

async function main() {
  const ethers = hre.ethers;
  const upgrades = hre.upgrades;
  console.log('network:', await ethers.provider.getNetwork());

  const signer = (await ethers.getSigners())[0];
  console.log('signer:', await signer.getAddress());
  
  const signerAddress = process.env.SIGNER_ADDRESS;
  const colAddress = process.env.COLLECTION_ADDRESS;

  /**
   *  Deploy and Verify HexToysClaim
   */
  {   
    const HexToysClaim = await ethers.getContractFactory('HexToysClaim', {
      signer: (await ethers.getSigners())[0]
    });
    const claim = await upgrades.deployProxy(HexToysClaim, [colAddress, signerAddress], { initializer: 'initialize' });
    await claim.deployed()

    console.log('HexToysClaim proxy deployed: ', claim.address)
    
    await sleep(60);
    // Verify HexToysClaim
    try {
      await hre.run('verify:verify', {
        address: claim.address,
        constructorArguments: []
      })
      console.log('HexToysClaim verified')
    } catch (error) {
      console.log('HexToysClaim verification failed : ', error)
    }    
  }
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
