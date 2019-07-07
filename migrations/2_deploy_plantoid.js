//this migration file is used only for testing purpose

var Plantoid = artifacts.require('./Plantoid.sol');
var Proxy = artifacts.require('./Proxy.sol');
var ERC827TokenMock = artifacts.require("./ERC827TokenMock.sol");
var GenesisProtocol = artifacts.require("./GenesisProtocol.sol");



//var threshold = 1000000000000000000;
var threshold = 100;
var artist = "0xC67Ff51c2c79F0036493B51e12560f94291fEF98";
module.exports = async function(deployer,network,provider) {

    deployer.deploy(Proxy,artist,artist,threshold).then(async function(){
      console.log(1)
      var proxy = await Proxy.deployed({gas:6000000});
      console.log(2)
    //  var stakingToken = await deployer.deploy(ERC827TokenMock,0,0);
      await deployer.deploy(Plantoid);
      var plantoidInstance = await Plantoid.deployed({gas:6000000}); //      console.log(provider);
      console.log(2)

      await proxy.upgradeTo(plantoidInstance.address,{gas:6000000});
      console.log(2)

      var proxyInstance = await Proxy.deployed();
      var plantoid = await Plantoid.at(proxyInstance.address);
      var genesisProtocol = await deployer.deploy(GenesisProtocol,0,{gas:6000000});
      await plantoid.init();
      await plantoid.setVotingMachine(genesisProtocol.address);
      await proxy.transferOwnership(artist);
      console.log(await proxy.owner());
  });
};
