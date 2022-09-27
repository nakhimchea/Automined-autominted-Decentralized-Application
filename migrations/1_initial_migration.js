const Migrations = artifacts.require("WingPoint");

module.exports = function (deployer) {
  deployer.deploy(Migrations);
};
