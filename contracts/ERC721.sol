// pragma solidity ^0.8.20;

// contract SimpleNFT {
//     string public name;
//     string public symbol;
//     uint256 private _tokenIds;

//     mapping(uint256 => address) private _owners;
//     mapping(address => uint256) private _balances;
//     mapping(uint256 => address) private _tokenApprovals;
//     mapping(address => mapping(address => bool)) private _operatorApprovals;
//     mapping(uint256 => string) private _tokenURIs;

//     event Transfer(
//         address indexed from,
//         address indexed to,
//         uint256 indexed tokenId
//     );
//     event Approval(
//         address indexed owner,
//         address indexed approved,
//         uint256 indexed tokenId
//     );
//     event ApprovalForAll(
//         address indexed owner,
//         address indexed operator,
//         bool approved
//     );

//     constructor(string memory _name, string memory _symbol) {
//         name = _name;
//         symbol = _symbol;
//     }

//     function balanceOf(address owner) public view returns (uint256) {
//         require(owner != address(0), "Zero address not valid");
//         return _balances[owner];
//     }

//     function ownerOf(uint256 tokenId) public view returns (address) {
//         address owner = _owners[tokenId];
//         require(owner != address(0), "Token does not exist");
//         return owner;
//     }

//     function approve(address to, uint256 tokenId) public {
//         address owner = ownerOf(tokenId);
//         require(
//             msg.sender == owner || isApprovedForAll(owner, msg.sender),
//             "Not authorized"
//         );
//         _tokenApprovals[tokenId] = to;
//         emit Approval(owner, to, tokenId);
//     }

//     function getApproved(uint256 tokenId) public view returns (address) {
//         require(_owners[tokenId] != address(0), "Token does not exist");
//         return _tokenApprovals[tokenId];
//     }

//     function setApprovalForAll(address operator, bool approved) public {
//         _operatorApprovals[msg.sender][operator] = approved;
//         emit ApprovalForAll(msg.sender, operator, approved);
//     }

//     function isApprovedForAll(
//         address owner,
//         address operator
//     ) public view returns (bool) {
//         return _operatorApprovals[owner][operator];
//     }

//     function transferFrom(address from, address to, uint256 tokenId) public {
//         address owner = ownerOf(tokenId);
//         require(
//             msg.sender == owner ||
//                 msg.sender == getApproved(tokenId) ||
//                 isApprovedForAll(owner, msg.sender),
//             "Not authorized"
//         );
//         require(from == owner, "Incorrect owner");
//         require(to != address(0), "Cannot transfer to zero address");

//         _tokenApprovals[tokenId] = address(0);

//         _balances[from] -= 1;
//         _balances[to] += 1;
//         _owners[tokenId] = to;

//         emit Transfer(from, to, tokenId);
//     }

//     function mint(address to, string memory uri) public returns (uint256) {
//         require(to != address(0), "Cannot mint to zero address");
//         _tokenIds += 1;
//         uint256 newTokenId = _tokenIds;

//         _owners[newTokenId] = to;
//         _balances[to] += 1;
//         _tokenURIs[newTokenId] = uri; // <-- set URI

//         emit Transfer(address(0), to, newTokenId);
//         return newTokenId;
//     }

//     function tokenURI(uint256 tokenId) public view returns (string memory) {
//         require(_owners[tokenId] != address(0), "Token does not exist");
//         return _tokenURIs[tokenId];
//     }
// }

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyOpenNFT is ERC721URIStorage, Ownable {
    uint256 private _tokenIds;

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) Ownable(msg.sender) {}

    function mintNFT(
        address to,
        string memory uri
    ) public onlyOwner returns (uint256) {
        _tokenIds += 1;
        uint256 newTokenId = _tokenIds;

        _mint(to, newTokenId);
        _setTokenURI(newTokenId, uri);

        return newTokenId;
    }
}
