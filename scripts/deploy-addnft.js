require('dotenv').config()
const hre = require('hardhat')

const sleep = (delay) => new Promise((resolve) => setTimeout(resolve, delay * 1000));

async function main() {
  const ethers = hre.ethers;
  const upgrades = hre.upgrades;
  console.log('network:', await ethers.provider.getNetwork());

  const signer = (await ethers.getSigners())[0];
  console.log('signer:', await signer.getAddress());
  
  /**
   *  Deploy and Verify HexToysAddNFTCollection
   */
  {   
    const HexToysAddNFTCollection = await ethers.getContractFactory('HexToysAddNFTCollection', {
      signer: (await ethers.getSigners())[0]
    });
    const addNFTCollection = await upgrades.deployProxy(HexToysAddNFTCollection, [], { initializer: 'initialize' });
    await addNFTCollection.deployed()

    console.log('HexToysAddNFTCollection proxy deployed: ', addNFTCollection.address)
    
    await sleep(60);
    // Verify HexToysAddNFTCollection
    try {
      await hre.run('verify:verify', {
        address: addNFTCollection.address,
        constructorArguments: []
      })
      console.log('HexToysAddNFTCollection verified')
    } catch (error) {
      console.log('HexToysAddNFTCollection verification failed : ', error)
    }    
  }
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
