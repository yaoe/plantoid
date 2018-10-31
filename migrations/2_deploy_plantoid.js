//this migration file is used only for testing purpose

var Plantoid = artifacts.require('./Plantoid.sol');
var Proxy = artifacts.require('./Proxy.sol');
var ERC827TokenMock = artifacts.require("./ERC827TokenMock.sol");
var GenesisProtocol = artifacts.require("./GenesisProtocol.sol");



var threshold = 50;
var artist = "0xb913BFd7A9a2B3E40864CFa08637848e37E5a042";
module.exports = async function(deployer,network,provider) {

    deployer.deploy(Proxy,artist,artist,threshold).then(async function(){
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
      console.log(1);
      await plantoid.setVotingMachine(genesisProtocol.address);
  });
};
