const {getNamedAccounts, ethers} = require("hardhat")


async function main() {
    const {deployer} = await getNamedAccounts()
    const fundMe = await ethers.getContract("FundMe", deployer)
    console.log("Funding contract...")
    const transactionResponse = await fundMe.withdraw()
    await transactionResponse.wait(1)
    console.log("Got it!!")
}

main()
.then(() => process.exit(0))
.catch(err => {
    console.error(err)
    process.exit(1)
})