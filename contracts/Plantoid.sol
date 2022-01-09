// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface IPlantoidSpawner {
    function spawnPlantoid(
        address,
        address,
        uint256,
        string memory,
        string memory
    ) external returns (bool);
}

/// @title Plantoid
/// @dev Blockchain based lifeform
///
///
contract Plantoid is ERC721Enumerable, Initializable {
    using ECDSA for bytes32; /*ECDSA for signature recovery for license mints*/

    event Deposit(uint256 amount, address sender);
    event ProposalSubmitted(address proposer, string proposalUri);

    struct Proposal {
        address proposer;
        string proposalUri;
    }

    /*****************
    Reproduction state mgmt
    *****************/
    uint256 threshold; /*Threshold of received ETH to trigger a spawning round*/

    mapping(uint256 => uint256) public proposalCounter; /* spawn count => proposal count*/
    mapping(uint256 => mapping(uint256 => Proposal)) public proposals; /* spawn count => proposal Id => Proposal */
    mapping(uint256 => uint256) public winningProposal; /* spawn count => winning proposal Id */

    mapping(uint256 => mapping(uint256 => bool)) public voted; /* spawn count => token ID => voted */
    mapping(uint256 => mapping(uint256 => uint256)) public votes; /* spawn count => proposal Id => votes*/

    uint256 public spawnCount; /*Track how many children - used for voting rounds*/
    address public artist;

    /*****************
    Minting state mgmt
    *****************/
    mapping(bytes32 => bool) public signatureUsed; /* track if minting signature has been used */
    address public plantoidAddress; /* Plantoid oracle TODO make changeable by creator? */
    uint256 _tokenIds;
    mapping(uint256 => string) private _tokenUris;

    /*****************
    Config state mgmt
    *****************/
    string private _name; /*Token name override*/
    string private _symbol; /*Token symbol override*/
    string public contractURI; /*contractURI contract metadata json*/

    IPlantoidSpawner spawner;

    /*****************
    Configuration
    *****************/

    /// @dev contructor creates an unusable plantoid for future spawn templates
    constructor() ERC721("", "") initializer {
        /* initializer modifier makes it so init cannot be called on template*/
        plantoidAddress = address(0xdead); /*Set address to dead so receive fallback of template fails*/
    }

    /// @dev Initialize
    /// @param _plantoid Address of plantoid oracle on physical sculpture
    /// @param _artist Address of creator of this plantoid
    /// @param name_ Token name for supporter seeds
    /// @param symbol_ Token symbol for supporter seeds
    function init(
        address _plantoid,
        address _artist,
        uint256 _threshold,
        string calldata name_,
        string calldata symbol_
    ) external initializer {
        plantoidAddress = _plantoid;
        artist = _artist;
        threshold = _threshold;
        _name = name_;
        _symbol = symbol_;
        spawner = IPlantoidSpawner(msg.sender); /*Initialize interface to spawner*/
    }

    /*****************
    External Data
    *****************/
    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return _tokenUris[_tokenId];
    }

    /*****************
    Reproductive functions
    *****************/
    /// @dev Propose reproduction if threshold is reached
    /// @param _round Round to propose for - round is same as spawn count for this plantoid
    /// @param _proposalUri Link to artist proposal
    function submitProposal(uint256 _round, string memory _proposalUri)
        external
    {
        require(address(this).balance >= threshold, "!threshold");
        require(_round == spawnCount, "!round");
        proposalCounter[spawnCount] += 1;
        proposals[spawnCount][proposalCounter[spawnCount]] = Proposal(
            msg.sender,
            _proposalUri
        );
        emit ProposalSubmitted(msg.sender, _proposalUri);
    }

    // TODO move voting and proposals off chain to snapshot?

    /// @dev Submit vote on round proposal
    /// @param _round Round to vote for
    /// @param _proposal ID of proposal
    /// @param _votingTokenIds IDs of tokens to use for vote
    function submitVote(
        uint256 _round,
        uint256 _proposal,
        uint256[] memory _votingTokenIds
    ) external {
        require(address(this).balance >= threshold, "!threshold");
        require(_round == spawnCount, "!round");
        require(
            proposals[spawnCount][_proposal].proposer != address(0),
            "!proposal"
        );
        require(_votingTokenIds.length > 0, "!tokens");
        for (uint256 index = 0; index < _votingTokenIds.length; index++) {
            require(ownerOf(_votingTokenIds[index]) == msg.sender, "!owner");
            voted[spawnCount][_votingTokenIds[index]] = true;
        }
        votes[spawnCount][_proposal] += _votingTokenIds.length;
    }

    /// @dev Accept winner by the artist
    /// @param _round Round to accept for
    /// @param _winningProposal Proposal ID
    function acceptWinner(uint256 _round, uint256 _winningProposal) external {
        require(address(this).balance >= threshold, "!threshold");
        require(_round == spawnCount, "!round");
        require(msg.sender == artist, "!authorized");
        require(
            proposals[spawnCount][_winningProposal].proposer != address(0),
            "!proposal"
        );
        winningProposal[spawnCount] = _winningProposal;
    }

    // todo allow artist to veto winning proposal - move on to next spawn count

    /// @dev Spawn new plantoid by winning artist
    /// @param _newPlantoid address of new plantoid oracle
    /// @param _plantoidThreshold deposit threshold for new plantoid
    /// @param _plantoidName token name of new plantoid
    /// @param _plantoidSymbol token symbol
    function spawn(
        address _newPlantoid,
        uint256 _plantoidThreshold,
        string memory _plantoidName,
        string memory _plantoidSymbol
    ) external {
        require(
            proposals[spawnCount][winningProposal[spawnCount]].proposer ==
                msg.sender,
            "!winner"
        );
        (bool _success, ) = artist.call{value: threshold}(""); /*Send ETH to artist first*/
        // todo royalties
        require(_success, "could not send");
        require(
            spawner.spawnPlantoid(
                _newPlantoid,
                msg.sender,
                _plantoidThreshold,
                _plantoidName,
                _plantoidSymbol
            ),
            "Failed to spawn"
        );
    }

    /// @dev Spawn new plantoid using custom contract by winning artist
    /// @param _newPlantoidSpawner address of new plantoid spawner
    /// @param _newPlantoid address of new plantoid oracle
    /// @param _plantoidThreshold deposit threshold for new plantoid
    /// @param _plantoidName token name of new plantoid
    /// @param _plantoidSymbol token symbol
    function spawnCustom(
        IPlantoidSpawner _newPlantoidSpawner,
        address _newPlantoid,
        uint256 _plantoidThreshold,
        string memory _plantoidName,
        string memory _plantoidSymbol
    ) external {
        require(
            proposals[spawnCount][winningProposal[spawnCount]].proposer ==
                msg.sender,
            "!winner"
        );
        (bool _success, ) = artist.call{value: threshold}(""); /*Send ETH to artist first*/
        // todo royalties
        require(_success, "could not send");
        require(
            _newPlantoidSpawner.spawnPlantoid(
                _newPlantoid,
                msg.sender,
                _plantoidThreshold,
                _plantoidName,
                _plantoidSymbol
            ),
            "Failed to spawn"
        );
    }

    /*****************
    Supporter functions
    *****************/
    receive() external payable {
        require(
            plantoidAddress != address(0xdead),
            "Cannot send ETH to dead plantoid"
        );
        emit Deposit(msg.value, msg.sender);
    }

    /// @dev Mint a supporter NFT using signature from the plantoid oracle
    /// @param _nonce Signature nonce
    /// @param _recipient User who donated the ETH
    /// @param _tokenUri URI of metadata for plantoid interaction
    /// @param _signature Permission sig from plantoid
    function mintSeed(
        uint256 _nonce,
        address _recipient,
        string memory _tokenUri,
        bytes memory _signature
    ) external {
        bytes32 _digest = keccak256(
            abi.encodePacked(_nonce, _tokenUri, _recipient, address(this))
        );
        require(!signatureUsed[_digest], "signature already used");
        signatureUsed[_digest] = true; /*Mark signature as used so we cannot use it again*/

        require(_verify(_digest, _signature, plantoidAddress), "Not signer");

        _tokenIds += 1;

        uint256 _id = _tokenIds;
        _safeMint(_recipient, _id);
        _setTokenURI(_id, _tokenUri);
    }

    /*****************
    Internal utils
    *****************/
    /// @dev Internal util to confirm seed sig
    /// @param data Message hash
    /// @param signature Sig from primary token holder
    /// @param account address to compare with recovery
    function _verify(
        bytes32 data,
        bytes memory signature,
        address account
    ) internal pure returns (bool) {
        return data.toEthSignedMessageHash().recover(signature) == account;
    }

    function _setTokenURI(uint256 _tokenId, string memory _tokenUri) internal {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        _tokenUris[_tokenId] = _tokenUri;
    }
}

contract CloneFactory {
    function createClone(address payable target)
        internal
        returns (address payable result)
    {
        // eip-1167 proxy pattern adapted for payable platoid spawner
        bytes20 targetBytes = bytes20(address(target));
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }
    }
}

contract PlantoidSpawn is CloneFactory, IPlantoidSpawner {
    address payable public immutable template; // fixed template using eip-1167 proxy pattern

    event PlantoidSpawned(address indexed plantoid, address indexed artist);

    constructor(address payable _template) {
        template = _template;
    }

    // add a generic data bytes field so people can make new templates
    function spawnPlantoid(
        address _plantoidAddr,
        address _artist,
        uint256 _threshold,
        string memory _name,
        string memory _symbol
    ) external override returns (bool) {
        Plantoid _plantoid = Plantoid(createClone(template));
        _plantoid.init(_plantoidAddr, _artist, _threshold, _name, _symbol);
        emit PlantoidSpawned(address(_plantoid), _artist);
        return true;
    }
}
