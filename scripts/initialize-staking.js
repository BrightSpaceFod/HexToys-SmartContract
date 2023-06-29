require('dotenv').config()
const hre = require('hardhat')

async function main() {
  const ethers = hre.ethers;  

  console.log('network:', await ethers.provider.getNetwork())

  const signer = (await ethers.getSigners())[0]
  console.log('signer:', await signer.getAddress())

  const subscriptions = [
    {
      name: 'Basic',
      period: 2592000, // 1 months
      price: '2000000'
    },
    {
      name: 'Standard',
      period: 7776000, // 3 months
      price: '5000000'
    },
    {
      name: 'Premium',
      period: 15552000, // 6 months
      price: '10000000'
    }
  ];
  const aprs = [
    50, // 5 %
    100, // 10 %
    150, // 15 %
    200, // 20 %
    250, // 25 %
    300, // 30 %
  ];

  /**
  * Initialize HexToysSingleNFTStakingFactory
  */
  {
    console.log('Initialize HexToysSingleNFTStakingFactory...')
    const singleFactoryAddress = '0xa292a8adaac47f04ea4af3fdb63119a1987d90e1';
    const HexToysSingleNFTStakingFactory = await ethers.getContractFactory('HexToysSingleNFTStakingFactory', {
      signer: (await ethers.getSigners())[0]
    });
    const singleNFTStakingFactory = HexToysSingleNFTStakingFactory.attach(singleFactoryAddress);
    // Add Subscriptions    
    for (let index = 0; index < subscriptions.length; index++) {
      const subscription = subscriptions[index];
      const tx = await singleNFTStakingFactory.addSubscription(subscription.name, subscription.period, ethers.utils.parseEther(subscription.price));
      await tx.wait();
      console.log('Add subscription : ', JSON.stringify(subscription));
    }

    // Add APR      
    for (let index = 0; index < aprs.length; index++) {
      const apr = aprs[index];
      const tx = await singleNFTStakingFactory.addApr(apr);
      await tx.wait();
      console.log('Add apr : ', apr);
    }
  }

  /**
  * Initialize HexToysMultiNFTStakingFactory
  */
  {
    console.log('Initialize HexToysMultiNFTStakingFactory...')
    const multiFactoryAddress = '0x06438db8be430fb74821dbcfb34db1f4b35ac843';
    const HexToysMultiNFTStakingFactory = await ethers.getContractFactory('HexToysMultiNFTStakingFactory', {
      signer: (await ethers.getSigners())[0]
    });
    const multiNFTStakingFactory = HexToysMultiNFTStakingFactory.attach(multiFactoryAddress);
  
    // Add Subscriptions    
    for (let index = 0; index < subscriptions.length; index++) {
      const subscription = subscriptions[index];
      const tx = await multiNFTStakingFactory.addSubscription(subscription.name, subscription.period, ethers.utils.parseEther(subscription.price));
      await tx.wait();
      console.log('Add subscription : ', JSON.stringify(subscription));
    }
  
    // Add APR      
    for (let index = 0; index < aprs.length; index++) {
      const apr = aprs[index];
      const tx = await multiNFTStakingFactory.addApr(apr);
      await tx.wait();
      console.log('Add apr : ', apr);
    }
  }

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
