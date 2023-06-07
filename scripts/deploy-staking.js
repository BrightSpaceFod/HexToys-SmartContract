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
  *  Deploy SingleNFTStakingFactory
  */
  {
    const contractFactory = await ethers.getContractFactory('SingleNFTStakingFactory');
    const contract = await contractFactory.deploy(feeAddress);
    await contract.deployed();

    console.log('SingleNFTStakingFactory Deployed: ', contract.address);
    
  }

  /**
  *  Deploy MultiNFTStakingFactory
  */
   {
    const contractFactory = await ethers.getContractFactory('MultiNFTStakingFactory');
    const contract = await contractFactory.deploy(feeAddress);
    await contract.deployed();

    console.log('MultiNFTStakingFactory Deployed: ', contract.address);
    
  }
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
