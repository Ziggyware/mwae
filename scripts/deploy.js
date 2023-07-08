async function main() {
    const zimoFactory = await ethers.getContractFactory("ZillennialMemeopolis")
  
    // Start deployment, returning a promise that resolves to a contract object
    const zimoContract = await zimoFactory.deploy()
    await zimoContract.deployed()
    console.log("Contract deployed to address:", zimoContract.address)
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error)
      process.exit(1)
    })
  