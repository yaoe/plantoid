pragma solidity ^0.5.17;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/upgrades/contracts/application/App.sol";
import "@openzeppelin/upgrades/contracts/application/ImplementationDirectory.sol";
import "@openzeppelin/upgrades/contracts/upgradeability/AdminUpgradeabilityProxy.sol";


contract PlantoidFactory is Initializable {

    event ProxyCreated(address indexed _proxy);
    App public app;
    string public constant PACKAGE_NAME = "Plantoid";

    function initialize(address _appContractAddress) external initializer {
        app = App(_appContractAddress);
    }

    /**
     * @dev Create a new palntoid
     * the proxy admin is the plantoid (the dao)
     * @param _threshold threshold
     * @param _addresses addresses
     *  addresses[0] - artist
     *  addresses[1] - parent
     * @param _votingMachines VotingMachines
     *  VotingMachines[0] - absoluteVote
     *  VotingMachines[1] - genesisProtocol
     * @param _owners - array of initial owners (for the absoluteVote)
     * @return The address of the new platoind created
    */
    function createPlantoid (
        uint256 _threshold,
        address[2] calldata _addresses,
        address[2] calldata _votingMachines,
        address[] calldata _owners,
        uint64[3] calldata _version)
        external
        returns(address) {
        //calling private function due to "stack too deep issue".
            AdminUpgradeabilityProxy plantoid =  _createPlantoid(
            _threshold,
            _addresses,
            _votingMachines,
            _owners,
            _version
        );
            plantoid.changeAdmin(address(plantoid));
            emit ProxyCreated(address(plantoid));
            return address(plantoid);
        }

    /**
     * @dev Create a new palntoid
     * @return The address of the new platoind created
    */
    function _createPlantoid (
        uint256 _threshold,
        address[2] memory _addresses,
        address[2] memory _votingMachines,
        address[] memory _owners,
        uint64[3] memory _version)
        private
        returns(AdminUpgradeabilityProxy) {
            uint64[3] memory packageVersion;
            Package package;
            uint64[3] memory latestVersion;
            (package, latestVersion) = app.getPackage(PACKAGE_NAME);
            if (package.getContract(_version) == address(0)) {
                require(package.getContract(latestVersion) != address(0), "ImplementationProvider does not exist");
                packageVersion = latestVersion;
            } else {
                packageVersion = _version;
            }
            ImplementationProvider provider = ImplementationProvider(package.getContract(packageVersion));
            address implementation = provider.getImplementation("Plantoid");
            return (new AdminUpgradeabilityProxy).value(msg.value)(implementation, address(this),
            abi.encodeWithSignature(
                "initialize(address,address,uint256,address,address,address[])",
                _addresses[0],
                _addresses[1],
                _threshold,
                _votingMachines[0],
                _votingMachines[1],
                _owners));
        }
}
