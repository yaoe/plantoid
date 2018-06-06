//this migration file is used only for testing purpose

var Plantoid = artifacts.require('./Plantoid.sol');
var Proxy = artifacts.require('./Proxy.sol');



var threshold = 100;
var artist = "0x73Db6408abbea97C5DB8A2234C4027C315094936";


module.exports = async function(deployer) {
    deployer.deploy(Proxy,artist,threshold).then(async function(){
      var proxy = await Proxy.deployed();
      await deployer.deploy(Plantoid,artist,threshold);
      var plantoidInstance = await Plantoid.deployed();
      await proxy.upgradeTo(plantoidInstance.address);
  });
};
