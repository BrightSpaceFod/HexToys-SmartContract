require('dotenv').config()
const hre = require('hardhat')

const sleep = (delay) => new Promise((resolve) => setTimeout(resolve, delay * 1000));

async function main() {
  const ethers = hre.ethers;
  console.log('network:', await ethers.provider.getNetwork());

  const signer = (await ethers.getSigners())[0];
  console.log('signer:', await signer.getAddress());
  
  /**
   *  Deploy MysteryBoxFactory
   */
  {   
    const contractFactory = await ethers.getContractFactory('MysteryBoxFactory');
    const contract = await contractFactory.deploy();
    await contract.deployed();

    console.log('MysteryBoxFactory Deployed: ', contract.address);     
  }

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
