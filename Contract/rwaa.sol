// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "stl-contracts/ERC/ERC5169.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract RWAAV2 is ERC721, ERC721Enumerable, Ownable, ERC5169 {
    uint256 public _nextTokenId;
    uint256 public _nextDocId;

    struct AvailDocMetadata {
        bytes32 blockHash;
        bytes32 txHash;
        string  name;
    }

    struct Notary {
        bytes32 notaryHash;
        uint256 timestamp;
    }

    struct TokenInfo {
        uint256 docId;
        bool isParent;

        // for children only
        uint256 parentTokenId;
        
        // for parent only
        uint256[] readbleTokenIds;
    } 

    mapping(uint256 => AvailDocMetadata) public docId2AvailDocMetadata;  
    mapping(uint256 => TokenInfo) public tokenId2TokenInfo; 
    mapping(uint256 => uint256) public docId2ParentTokenId;
    mapping(uint256 => Notary[]) public tokenNotary;

    mapping(uint256 => string) public tokenURIs;
    mapping(uint256 => string) public names;

    event DocumentCreated(uint256 docId);

    constructor()
        ERC721("RWAA V2", "RWAAV2")
        Ownable(msg.sender)
    {
        
    }

    function getTokenInfo(uint256 tokenId) public view returns (TokenInfo memory)  {

        return TokenInfo( tokenId2TokenInfo[tokenId].docId, tokenId2TokenInfo[tokenId].isParent, tokenId2TokenInfo[tokenId].parentTokenId, tokenId2TokenInfo[tokenId].readbleTokenIds);
    }

    function mint(uint256 tokenId, string calldata name, string calldata uri) public {
        _safeMint(msg.sender, tokenId);
        names[tokenId] = name;
        tokenURIs[tokenId] = uri;
    }

    function notarise(uint256 tokenId, bytes32 docHash) public {
        // can only be from the token owner
        address owner = ownerOf(tokenId);
        require (owner == msg.sender, "Must be owner to notarise");
        Notary memory thisEntry;
        thisEntry.notaryHash = docHash;
        thisEntry.timestamp = block.timestamp;
        tokenNotary[tokenId].push(thisEntry);
    }

    function getNotaryList(uint256 tokenId) public view returns (Notary[] memory) {
        return tokenNotary[tokenId];
    }

    function createDocument(AvailDocMetadata memory availDocMetadata) public onlyOwner {
        uint256 tokenId = _nextTokenId++;
        uint256 docId = _nextDocId++;

        docId2AvailDocMetadata[docId].blockHash = availDocMetadata.blockHash;
        docId2AvailDocMetadata[docId].txHash = availDocMetadata.txHash;
        docId2AvailDocMetadata[docId].name = availDocMetadata.name;

        tokenId2TokenInfo[tokenId].docId = docId;
        tokenId2TokenInfo[tokenId].isParent = true;

        docId2ParentTokenId[docId] = tokenId;

        _safeMint(msg.sender, tokenId);

        emit DocumentCreated(tokenId);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721)
    returns (string memory)
    {
        //string memory url = "https://storage.googleapis.com/opensea-prod.appspot.com/puffs/3.png";

        //string memory name = docId2AvailDocMetadata[tokenId2TokenInfo[tokenId].docId].name;

        bytes memory dataURI = abi.encodePacked(
            "{",
            '"image": "',
            tokenURIs[tokenId],
            '",',
             '"name": "',
            names[tokenId],
            '"'
            "}"
        );

        /*return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );*/

        return string(dataURI);    
    }


    function createReadableToken(uint256 docId, address toAddress) public onlyOwner {

        uint256 readableTokenId = _nextTokenId++;
        uint256 parentTokenId = docId2ParentTokenId[docId];

        tokenId2TokenInfo[parentTokenId].readbleTokenIds.push(readableTokenId);

        tokenId2TokenInfo[readableTokenId].docId = docId;
        tokenId2TokenInfo[readableTokenId].isParent = false;
        tokenId2TokenInfo[readableTokenId].parentTokenId = parentTokenId;

        _safeMint(toAddress, readableTokenId);
    }

    function revokeReadableToken(uint256 parentTokenId, uint256 indexToBeRemoved) public {
        require(msg.sender == ownerOf(parentTokenId), "Caller is not the parent token owner");
        require(indexToBeRemoved < tokenId2TokenInfo[parentTokenId].readbleTokenIds.length, "Invalid indexToBeRemoved");

        tokenId2TokenInfo[parentTokenId].readbleTokenIds[indexToBeRemoved] = tokenId2TokenInfo[parentTokenId].readbleTokenIds[tokenId2TokenInfo[parentTokenId].readbleTokenIds.length-1];
        tokenId2TokenInfo[parentTokenId].readbleTokenIds.pop();
    }

    function getDocIdbyTokenId(uint256 tokenId) public view returns (uint256) {
        return tokenId2TokenInfo[tokenId].docId;
    }


    // The following functions are overrides required by Solidity.

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC5169)
        returns (bool)
    {
        return ERC5169.supportsInterface(interfaceId)
        || super.supportsInterface(interfaceId);
    }

    function _authorizeSetScripts(string[] memory) internal virtual override onlyOwner() {}
}
