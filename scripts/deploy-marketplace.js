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
  const signerAddress = process.env.SIGNER_ADDRESS;

  /**
   *  Deploy and Verify HexToysSingleAuction
   */
  {   
    const HexToysSingleAuction = await ethers.getContractFactory('HexToysSingleAuction', {
      signer: (await ethers.getSigners())[0]
    });
    const singleAuction = await upgrades.deployProxy(HexToysSingleAuction, [feeAddress, signerAddress], { initializer: 'initialize' });
    await singleAuction.deployed()

    console.log('HexToysSingleAuction proxy deployed: ', singleAuction.address)
    
    await sleep(60);
    // Verify HexToysSingleAuction
    try {
      await hre.run('verify:verify', {
        address: singleAuction.address,
        constructorArguments: []
      })
      console.log('HexToysSingleAuction verified')
    } catch (error) {
      console.log('HexToysSingleAuction verification failed : ', error)
    }    
  }

    /**
   *  Deploy and Verify HexToysSingleFixed
   */
    {   
      const HexToysSingleFixed = await ethers.getContractFactory('HexToysSingleFixed', {
        signer: (await ethers.getSigners())[0]
      });
      const singleFixed = await upgrades.deployProxy(HexToysSingleFixed, [feeAddress, signerAddress], { initializer: 'initialize' });
      await singleFixed.deployed()
  
      console.log('HexToysSingleFixed proxy deployed: ', singleFixed.address)
      
      await sleep(60);
      // Verify HexToysSingleFixed
      try {
        await hre.run('verify:verify', {
          address: singleFixed.address,
          constructorArguments: []
        })
        console.log('HexToysSingleFixed verified')
      } catch (error) {
        console.log('HexToysSingleFixed verification failed : ', error)
      }    
    }
    /**
   *  Deploy and Verify HexToysMultipleFixed
   */
    {   
      const HexToysMultipleFixed = await ethers.getContractFactory('HexToysMultipleFixed', {
        signer: (await ethers.getSigners())[0]
      });
      const multipleFixed = await upgrades.deployProxy(HexToysMultipleFixed, [feeAddress, signerAddress], { initializer: 'initialize' });
      await multipleFixed.deployed()
  
      console.log('HexToysMultipleFixed proxy deployed: ', multipleFixed.address)
      
      await sleep(60);
      // Verify HexToysMultipleFixed
      try {
        await hre.run('verify:verify', {
          address: multipleFixed.address,
          constructorArguments: []
        })
        console.log('HexToysMultipleFixed verified')
      } catch (error) {
        console.log('HexToysMultipleFixed verification failed : ', error)
      }    
    }  
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
