//this migration file is used only for testing purpose

var Plantoid = artifacts.require('./Plantoid.sol');
var GenesisProtocol = artifacts.require("./GenesisProtocol.sol");
var AbsoluteVote = artifacts.require("./AbsoluteVote.sol");
const App = artifacts.require("./App.sol");
const Package = artifacts.require("./Package.sol");
var ImplementationDirectory = artifacts.require("./ImplementationDirectory.sol");
var PlantoidFactory = artifacts.require("./PlantoidFactory.sol");

const NULL_ADDRESS = '0x0000000000000000000000000000000000000000';
const NULL_HASH = '0x0000000000000000000000000000000000000000000000000000000000000000';

var threshold = 100;
var artist = "0xC67Ff51c2c79F0036493B51e12560f94291fEF98";
var ganache2 = "0xb913BFd7A9a2B3E40864CFa08637848e37E5a042";
var ganache1 = "0x95200d9955C6A01495ceDEADe04B62909736e3a9";
var proxyAdmin = "0x95200d9955C6A01495ceDEADe04B62909736e3a9";

var packageName = "Plantoid";
var version = [0,1,0];


module.exports = async function(deployer,network,provider) {

    deployer.deploy(Package).then(async function(){
      var packageInstance = await Package.deployed();
      var appInstance = await deployer.deploy(App);
      var implementationDirectory = await deployer.deploy(ImplementationDirectory);
      await packageInstance.addVersion(version,implementationDirectory.address,NULL_HASH);
      await appInstance.setPackage(packageName,packageInstance.address,version);
      var plantoidImplementation = await deployer.deploy(Plantoid);
      await implementationDirectory.setImplementation("Plantoid",plantoidImplementation.address);
      var plantoidFactory = await deployer.deploy(PlantoidFactory);
      await plantoidFactory.initialize(appInstance.address);
      var genesisProtocol = await deployer.deploy(GenesisProtocol,NULL_ADDRESS);
      var absoluteVote = await deployer.deploy(AbsoluteVote);
      console.log("gp",genesisProtocol.address);
      console.log("am",absoluteVote.address);

      var tx = await plantoidFactory.createPlantoid(threshold,
                                                     [artist,artist,proxyAdmin],
                                                     [absoluteVote.address,genesisProtocol.address],
                                                     [artist, ganache2, ganache1],
                                                     version,
                                                     {gas:6000000});

      var platoind = await Plantoid.at(tx.logs[0].args._proxy);

      console.log("genesisProtocol vm",await platoind.hcVotingMachine());
      console.log("absoluteVote vm",await platoind.amVotingMachine());
      console.log("plantoid:",platoind.address);
      console.log("seedcnt:",(await platoind.seedCnt()).toNumber());
      console.log("sh deploy.sh",platoind.address,genesisProtocol.address,absoluteVote.address);
  });
};
