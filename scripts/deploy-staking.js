require('dotenv').config()
const hre = require('hardhat')

const sleep = (delay) => new Promise((resolve) => setTimeout(resolve, delay * 1000));

async function main() {
  const ethers = hre.ethers;
  const upgrades = hre.upgrades;

  console.log('network:', await ethers.provider.getNetwork());

  const signer = (await ethers.getSigners())[0];
  console.log('signer:', await signer.getAddress());

  const feeAddress = process.env.FEE_ADDRESS;

  /**
   *  Deploy and Verify HexToysSingleNFTStakingFactory
   */
  {   
    const HexToysSingleNFTStakingFactory = await ethers.getContractFactory('HexToysSingleNFTStakingFactory', {
      signer: (await ethers.getSigners())[0]
    });
    const singleNFTStakingFactory = await upgrades.deployProxy(HexToysSingleNFTStakingFactory, [feeAddress], { initializer: 'initialize' });
    await singleNFTStakingFactory.deployed()

    console.log('HexToysSingleNFTStakingFactory proxy deployed: ', singleNFTStakingFactory.address)
    
    await sleep(60);
    // Verify HexToysSingleNFTStakingFactory
    try {
      await hre.run('verify:verify', {
        address: singleNFTStakingFactory.address,
        constructorArguments: []
      })
      console.log('HexToysSingleNFTStakingFactory verified')
    } catch (error) {
      console.log('HexToysSingleNFTStakingFactory verification failed : ', error)
    }    
  }

  /**
   *  Deploy and Verify HexToysMultiNFTStakingFactory
   */
  {   
    const HexToysMultiNFTStakingFactory = await ethers.getContractFactory('HexToysMultiNFTStakingFactory', {
      signer: (await ethers.getSigners())[0]
    });
    const multiNFTStakingFactory = await upgrades.deployProxy(HexToysMultiNFTStakingFactory, [feeAddress], { initializer: 'initialize' });
    await multiNFTStakingFactory.deployed()

    console.log('HexToysMultiNFTStakingFactory proxy deployed: ', multiNFTStakingFactory.address)
    
    await sleep(60);
    // Verify HexToysMultiNFTStakingFactory
    try {
      await hre.run('verify:verify', {
        address: multiNFTStakingFactory.address,
        constructorArguments: []
      })
      console.log('HexToysMultiNFTStakingFactory verified')
    } catch (error) {
      console.log('HexToysMultiNFTStakingFactory verification failed : ', error)
    }    
  }
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
