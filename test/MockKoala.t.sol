// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {MockKoalas} from "../src/MockKoalas.sol";
import {console} from "forge-std/console.sol";
import {MerkleProof} from "@openzeppelin/contracts@v5.0.1/utils/cryptography/MerkleProof.sol";  

contract MockKoalasTest is Test {
    using MerkleProof for bytes32[];
    MockKoalas public nft;
    address public OwnerWallet;
    address public preferredUser;
    address public standardUser;
    bytes32 public merkleRoot = 0x753f143036d476a0f15fc797bf9a3c229085709e0cb677176d1fba66fbafb461;
    error MockKoalas_TicketAlreadyClaimed();
    function setUp() public {
        OwnerWallet = address(69);
        preferredUser = address(420);
        standardUser = address(666);

        vm.deal(preferredUser, 5 ether);
        vm.deal(standardUser, 5 ether);
        vm.prank(OwnerWallet);
        nft = new MockKoalas(0x753f143036d476a0f15fc797bf9a3c229085709e0cb677176d1fba66fbafb461);
        // console.log(preferredUser);
    }

    function test_mint_for_discount() public {
        vm.startPrank(preferredUser);
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = bytes32(0x6f98e13f3232e83666c2a5b9deb152698d886b1d8ed56d6702c7dc1faf56232e);
        nft.prefferedMint{ value:0.5 ether }(proof, 0);
        assertEq(nft.balanceOf(preferredUser), 1);
        vm.stopPrank();
    }
    function test_mint_for_discount_reuse_fails() public {
        test_mint_for_discount();
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = bytes32(0x6f98e13f3232e83666c2a5b9deb152698d886b1d8ed56d6702c7dc1faf56232e);
        vm.expectRevert(
            abi.encodeWithSelector(MockKoalas_TicketAlreadyClaimed.selector)
        );
        nft.prefferedMint{ value:0.5 ether }(proof, 0); 
    }
    function test_mint_discount_second_allocation() public {
        vm.startPrank(preferredUser);
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = bytes32(0xdf248fb2594c2d2f88aa5844f799495ca629e3433619adc344edb43c6cda09ff);
        nft.prefferedMint{ value:0.5 ether }(proof, 1);
        assertEq(nft.balanceOf(preferredUser), 1);
        vm.stopPrank();
    }

    function test_merkle_proof() public {
        vm.startPrank(preferredUser);
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = bytes32(0x6f98e13f3232e83666c2a5b9deb152698d886b1d8ed56d6702c7dc1faf56232e);
        bytes32 leaf = keccak256(
            bytes.concat(
                keccak256(
                    abi.encode(preferredUser, uint256(0))
                )
            )
        );
        //console.logBytes32(leaf);
        assertEq(MerkleProof.verify(proof, merkleRoot, leaf), true);
    }
     
    function test_mint() public {
       vm.startPrank(standardUser);
       nft.mint{ value: 1 ether }();
       assertEq(nft.balanceOf(standardUser), 1);

    }

    function test_owner_withdraw() public {
        test_mint_for_discount();
        vm.startPrank(OwnerWallet);
        nft.withdraw();
        assertEq(address(nft).balance, 0);
        assertEq(address(OwnerWallet).balance, 0.5 ether);
    }

}