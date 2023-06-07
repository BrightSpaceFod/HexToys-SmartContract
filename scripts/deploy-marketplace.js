require('dotenv').config()
const hre = require('hardhat')

const sleep = (delay) => new Promise((resolve) => setTimeout(resolve, delay * 1000));

async function main() {
  const ethers = hre.ethers;
  console.log('network:', await ethers.provider.getNetwork());

  const signer = (await ethers.getSigners())[0];
  console.log('signer:', await signer.getAddress());

  const feeAddress = process.env.FEE_ADDRESS;  
  /**
   *  Deploy SingleAuction
   */
  {
    const contractFactory = await ethers.getContractFactory('SingleAuction');
    const contract = await contractFactory.deploy(feeAddress);
    await contract.deployed();

    console.log('SingleAuction Deployed: ', contract.address);

  }

  /**
   *  Deploy SingleFixed
   */
  {
    const contractFactory = await ethers.getContractFactory('SingleFixed');
    const contract = await contractFactory.deploy(feeAddress);
    await contract.deployed();

    console.log('SingleFixed Deployed: ', contract.address);
  }

  /**
   *  Deploy MultipleFixed
   */
  {
    const contractFactory = await ethers.getContractFactory('MultipleFixed');
    const contract = await contractFactory.deploy(feeAddress);
    await contract.deployed();

    console.log('MultipleFixed Deployed: ', contract.address);
  }
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
