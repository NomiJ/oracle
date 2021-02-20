const common = require('./utils/common.js')
const SLEEP_INTERVAL = process.env.SLEEP_INTERVAL || 2000
const PRIVATE_KEY_FILE_NAME = process.env.PRIVATE_KEY_FILE || '../caller/caller_private_key'
const CallerJSON = require('../bin/caller/CallerContract.json')
const OracleJSON = require('../bin/oracle/EthPriceOracle.json')
const EthPriceOracleAddress = '0x8a0698bf3Da06b840c58b77df649025DD85d5a48'
const CallerContractAddress = '0x26371AE4b065acBA0af481da9bB55c9A49b71FF2'

async function getCallerContract(web3js) {
    const networkId = await web3js.eth.net.getId()
    return new web3js.eth.Contract(CallerJSON.abi, CallerContractAddress)
}

async function retrieveLatestEthPrice() {
    const resp = await axios({
        url: 'https://api.binance.com/api/v3/ticker/price',
        params: {
            symbol: 'ETHUSDT'
        },
        method: 'get'
    })
    return resp.data.price
}

async function filterEvents(callerContract) {
    callerContract.events.PriceUpdatedEvent({ filter: {} }, async(err, event) => {
        if (err) console.error('Error on event', err)
        console.log('* New PriceUpdated event. ethPrice: ' + event.returnValues.ethPrice)
    })
    callerContract.events.ReceivedNewRequestIdEvent({ filter: {} }, async(err, event) => {
        if (err) console.error('Error on event', err)
    })
}

async function init() {
    const { ownerAddress, web3js, client } = common.loadAccount(PRIVATE_KEY_FILE_NAME)
    const callerContract = await getCallerContract(web3js)
    filterEvents(callerContract)
    return { callerContract, ownerAddress, client, web3js }
}

(async() => {
    try {
        console.log('Starting client... ')
        const { callerContract, ownerAddress, client, web3js } = await init()
        process.on('SIGINT', () => {
            console.log('Calling client.disconnect()')
            client.disconnect();
            process.exit();
        })
        const networkId = await web3js.eth.net.getId()
        const oracleAddress = EthPriceOracleAddress
        await callerContract.methods.setOracleInstanceAddress(oracleAddress).send({ from: ownerAddress })
        setInterval(async() => {
            await callerContract.methods.updateEthPrice().send({ from: ownerAddress })
        }, SLEEP_INTERVAL);
    } catch (e) {
        console.log('This is e ' + e)
    }
})()