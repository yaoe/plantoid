//this migration file is used only for testing purpose

var Plantoid = artifacts.require('./Plantoid.sol');
var Proxy = artifacts.require('./Proxy.sol');
var ERC827TokenMock = artifacts.require("./ERC827TokenMock.sol");
var GenesisProtocol = artifacts.require("./GenesisProtocol.sol");



var threshold = 50;
//var artist = "0x73Db6408abbea97C5DB8A2234C4027C315094936";
module.exports = async function(deployer,network,provider) {

    deployer.deploy(Proxy,provider[0],provider[0],threshold).then(async function(){
      var proxy = await Proxy.deployed();
      var stakingToken = await deployer.deploy(ERC827TokenMock,0,0);
      await deployer.deploy(Plantoid);
      var plantoidInstance = await Plantoid.deployed({gas:6000000});
      console.log(stakingToken.address);
      console.log(provider);
      await proxy.upgradeTo(plantoidInstance.address,{gas:6000000});
      var proxyInstance = await Proxy.deployed();
      var plantoid = await Plantoid.at(proxyInstance.address);
      var genesisProtocol = await deployer.deploy(GenesisProtocol,stakingToken.address,{gas:6000000});
      await plantoid.init();
      await plantoid.setVotingMachine(genesisProtocol.address);
  });
};
