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
   *  Deploy and Verify HexToysNFTFactory
   */
  {   
    const HexToysNFTFactory = await ethers.getContractFactory('HexToysNFTFactory', {
      signer: (await ethers.getSigners())[0]
    });
    const nftFactory = await upgrades.deployProxy(HexToysNFTFactory, [], { initializer: 'initialize' });
    await nftFactory.deployed()

    console.log('HexToysNFTFactory proxy deployed: ', nftFactory.address)
    
    await sleep(60);
    // Verify HexToysNFTFactory
    try {
      await hre.run('verify:verify', {
        address: nftFactory.address,
        constructorArguments: []
      })
      console.log('HexToysNFTFactory verified')
    } catch (error) {
      console.log('HexToysNFTFactory verification failed : ', error)
    }    
  }
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
