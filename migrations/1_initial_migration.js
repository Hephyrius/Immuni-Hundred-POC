
const contract  = artifacts.require ("./Example.sol");

module.exports = async(deployer) => {
  var deployedContract = await contract.new() 
  console.log(deployedContract.address)
};

