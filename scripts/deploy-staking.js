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
    const contractFactory = await ethers.getContractFactory('HexToysSingleNFTStakingFactory');
    const contract = await contractFactory.deploy(feeAddress);
    await contract.deployed();

    console.log('HexToysSingleNFTStakingFactory Deployed: ', contract.address);

    await sleep(60);
    // Verify HexToysSingleNFTStakingFactory
    try {
      await hre.run('verify:verify', {
        address: contract.address,
        constructorArguments: [feeAddress]
      });
      console.log('HexToysSingleNFTStakingFactory verified');
    } catch (error) {
      console.log('HexToysSingleNFTStakingFactory verification failed : ', error);
    }
  }

  /**
  *  Deploy and Verify HexToysMultiNFTStakingFactory
  */
   {
    const contractFactory = await ethers.getContractFactory('HexToysMultiNFTStakingFactory');
    const contract = await contractFactory.deploy(feeAddress);
    await contract.deployed();

    console.log('HexToysMultiNFTStakingFactory Deployed: ', contract.address);

    await sleep(60);
    // Verify HexToysMultiNFTStakingFactory
    try {
      await hre.run('verify:verify', {
        address: contract.address,
        constructorArguments: [feeAddress]
      });
      console.log('HexToysMultiNFTStakingFactory verified');
    } catch (error) {
      console.log('HexToysMultiNFTStakingFactory verification failed : ', error);
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
