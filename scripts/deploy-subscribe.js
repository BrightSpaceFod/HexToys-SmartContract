require('dotenv').config()
const hre = require('hardhat')

const sleep = (delay) => new Promise((resolve) => setTimeout(resolve, delay * 1000));

async function main() {
  const ethers = hre.ethers
  console.log('network:', await ethers.provider.getNetwork())

  const signer = (await ethers.getSigners())[0]
  console.log('signer:', await signer.getAddress())

  // Subscribe Contract
  const Subscribe = await ethers.getContractFactory('HexToysSubscription', { signer: signer })

  const _contract = await Subscribe.deploy();
  await _contract.deployed();
  await sleep(60);
  console.log("Subscribe Deployed Address : ", _contract.address);

  // Verify Template
  try {
    await hre.run('verify:verify', {
      address: _contract.address,
      constructorArguments: []
    })
    console.log('Subscribe Contract verified')
  } catch (error) {
    console.log('Subscribe verification failed : ', error)
  }

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })