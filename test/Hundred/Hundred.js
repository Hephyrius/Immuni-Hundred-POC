const { BN, expectRevert, send, ether } = require('@openzeppelin/test-helpers');
const baseContract  = artifacts.require ("./Hundred.sol");

contract("Hundred Attack POC", async accounts => {

  var deployedContract

  it('should be able to deploy', async () => {
    deployedContract = await baseContract.new({from: accounts[0]})
  });
  
  it('should be able to start', async () => {
    await deployedContract.startAttack({from: accounts[0]})
  });

});