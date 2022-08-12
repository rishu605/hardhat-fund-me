const {networkConfig, developmentChains} = require('./../helper-hardhat-config')
const {network} = require("hardhat")
const {verify} = require('./../utils/verify')

module.exports = async (hre) => {
    const {getNamedAccounts, deployments} = hre
    const {deploy, log, get} = deployments
    const {deployer} = await getNamedAccounts()
    const chainId = network.config.chainId

    let ethUsdPriceFeedAddress
    if(developmentChains.includes(network.name)) {
        const ethUsdAggregator = await get("MockV3Aggregator")
        ethUsdPriceFeedAddress = ethUsdAggregator.address
    } else {
        ethUsdPriceFeedAddress = networkConfig[chainId].ethUsdPriceFeed
    }


    // If the contract does NOT exist, we deploy a minimal version for our local testing
    const args = [ethUsdPriceFeedAddress]
    const fundMe = await deploy("FundMe", {
        from: deployer,
        args: args, // put price feed address
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1
    })

    if(!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        await verify(fundMe.address, args)
    }
    log("----------------------------------------------")
}

module.exports.tags = ["all", "fundme"]