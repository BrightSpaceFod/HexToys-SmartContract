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
   *  Deploy and Verify HexToysSubscription
   */
  {   
    const HexToysSubscription = await ethers.getContractFactory('HexToysSubscription', {
      signer: (await ethers.getSigners())[0]
    });
    const subscription = await upgrades.deployProxy(HexToysSubscription, [], { initializer: 'initialize' });
    await subscription.deployed()

    console.log('HexToysSubscription proxy deployed: ', subscription.address)
    
    await sleep(60);
    // Verify HexToysSubscription
    try {
      await hre.run('verify:verify', {
        address: subscription.address,
        constructorArguments: []
      })
      console.log('HexToysSubscription verified')
    } catch (error) {
      console.log('HexToysSubscription verification failed : ', error)
    }    
  }
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })