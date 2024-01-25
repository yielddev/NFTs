// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import {ERC721Enumerable} from "@openzeppelin/contracts@v5.0.1/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721} from "@openzeppelin/contracts@v5.0.1/token/ERC721/ERC721.sol";
import {ERC2981} from "@openzeppelin/contracts@v5.0.1/token/common/ERC2981.sol";
import {BitMaps} from "@openzeppelin/contracts@v5.0.1/utils/structs/BitMaps.sol";
import {MerkleProof} from "@openzeppelin/contracts@v5.0.1/utils/cryptography/MerkleProof.sol";
import {Ownable2Step} from "@openzeppelin/contracts@v5.0.1/access/Ownable2Step.sol";
import {Ownable} from "@openzeppelin/contracts@v5.0.1/access/Ownable.sol";
import {console} from "forge-std/console.sol";
error MockKoalas_MaxSupplyReached();   
error MockKoalas_PaymentNotEnough();    
error MockKoalas_TicketAlreadyClaimed();
error MockKoalas_MerkleProofInvalid();
/// @title Koala NFTs contract can be used to earn points
/// @author Yielddev
/// @notice 
contract MockKoalas is ERC721Enumerable, ERC2981, Ownable2Step { 
    using BitMaps for BitMaps.BitMap;
    using MerkleProof for bytes32[];
    uint256 public immutable SUPPLY_CAP = 1000;
    uint256 public immutable PRICE = 1 ether;
    uint256 public immutable PREFFERED_PRICE = 0.5 ether;
    BitMaps.BitMap private _prefferedMinters;

    bytes32 public immutable merkleRoot;
    constructor(bytes32 _merkleRoot) ERC721("MockKoalas", "MKOA") Ownable(msg.sender){
        merkleRoot = _merkleRoot;
        _setDefaultRoyalty(address(msg.sender), 250);
    }

    // function mint(address to) public {
    //     if (totalSupply() >= SUPPLY_CAP) revert MockKoalas_MaxSupplyReached();
    //     _mint(to, totalSupply());
    // }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // merkle file ticket
    // address mint index allowed 
    function prefferedMint(bytes32[] calldata proof, uint256 ticketId) public payable {
        if(msg.value < PREFFERED_PRICE) revert MockKoalas_PaymentNotEnough();
        if (totalSupply() >= SUPPLY_CAP) revert MockKoalas_MaxSupplyReached();
        if (_prefferedMinters.get(ticketId)) revert MockKoalas_TicketAlreadyClaimed();
        bytes32 node = keccak256(
            bytes.concat(
                keccak256(
                    abi.encode(_msgSender(), ticketId)
                )
            )
        );
        // console.log("node");
        // console.logBytes32(node);
        // console.logBytes32(proof[0]);

        if(!MerkleProof.verify(proof, merkleRoot, node)) revert MockKoalas_MerkleProofInvalid();
        _prefferedMinters.set(ticketId);
        _mint(_msgSender(), totalSupply());
    }
    function mint() public payable {
        if (msg.value < PRICE) revert MockKoalas_PaymentNotEnough();
        if (totalSupply() >= SUPPLY_CAP) revert MockKoalas_MaxSupplyReached();
        _mint(msg.sender, totalSupply());
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {
        mint();
    }
}