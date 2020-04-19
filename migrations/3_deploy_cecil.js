//this migration file is used only for testing purpose

var Cecil = artifacts.require('./Cecil.sol');

var GenesisProtocol = artifacts.require("./GenesisProtocol.sol");
var AbsoluteVote = artifacts.require("./AbsoluteVote.sol")

const NULL_ADDRESS = '0x0000000000000000000000000000000000000000';


var plantoid = "0xC67Ff51c2c79F0036493B51e12560f94291fEF98";
var ganache2 = "0xb913BFd7A9a2B3E40864CFa08637848e37E5a042";
var ganache1 = "0x95200d9955C6A01495ceDEADe04B62909736e3a9";

module.exports = async function(deployer,network,provider) {

    deployer.deploy(Cecil,plantoid).then(async function(){
      console.log(1)
      var cecil = await Cecil.deployed({gas:6000000});
      console.log(2)

      var genesisProtocol = await deployer.deploy(GenesisProtocol,NULL_ADDRESS,{gas:6000000});
      var AMmachine = await deployer.deploy(AbsoluteVote, {gas:6000000});
      await cecil.init();
      await cecil.setHCVotingMachine(genesisProtocol.address);
      await cecil.setAMVotingMachine(AMmachine.address, [plantoid, ganache2, ganache1]);

      console.log("sh deploy-cecil.sh",cecil.address,genesisProtocol.address,AMmachine.address);
  });
};
