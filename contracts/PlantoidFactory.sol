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
     * @param _threshold threshold
     * @param _addresses addresses
     *  addresses[0] - artist
     *  addresses[1] - parent
     *  addresses[2] - proxyAdmin
     * @param _votingMachines VotingMachines
     *  VotingMachines[0] - absoluteVote
     *  VotingMachines[1] - genesisProtocol
     * @param _owners - array of initial owners (for the absoluteVote)
     * @return The address of the new platoind created
    */
    function createPlantoid (
        uint256 _threshold,
        address[3] calldata _addresses,
        address[2] calldata _votingMachines,
        address[] calldata _owners,
        uint64[3] calldata _version)
        external
        returns(address) {
            require(_addresses[2] != _addresses[0], "proxy admin cannot be artist");
            require(_addresses[2] != _addresses[1], "proxy admin cannot be parent");
        //calling private function due to "stack too deep issue".
            address proxy =  _createPlantoid(
            _threshold,
            _addresses,
            _votingMachines,
            _owners,
            _version
        );
            emit ProxyCreated(proxy);
            return proxy;
        }

    /**
     * @dev Create a new palntoid
     * @return The address of the new platoind created
    */
    function _createPlantoid (
        uint256 _threshold,
        address[3] memory _addresses,
        address[2] memory _votingMachines,
        address[] memory _owners,
        uint64[3] memory _version)
        private
        returns(address) {
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
            return address((new AdminUpgradeabilityProxy).value(msg.value)(implementation, _addresses[2],
            abi.encodeWithSignature(
                "initialize(address,address,uint256,address,address,address[])",
                _addresses[0],
                _addresses[1],
                _threshold,
                _votingMachines[0],
                _votingMachines[1],
                _owners)));
        }
}
