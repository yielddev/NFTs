// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {MockKoalas} from "../src/MockKoalas.sol";
import {MasterKoala} from "../src/MasterKoala.sol";
import {MerkleProof} from "@openzeppelin/contracts@v5.0.1/utils/cryptography/MerkleProof.sol";  
import {KoalaPoints} from '../src/KoalaPoints.sol';
error MasterKoala_NotStaked();
contract MasterKoalaTest is Test {
    MockKoalas public nft;
    MasterKoala public pool;
    KoalaPoints public points;
    address public OwnerWallet;
    address public preferredUser;
    address public standardUser;
    bytes32 public merkleRoot = 0x753f143036d476a0f15fc797bf9a3c229085709e0cb677176d1fba66fbafb461;
    function setUp() public {
        OwnerWallet = address(69);
        preferredUser = address(420);
        standardUser = address(666);
        
        vm.deal(preferredUser, 5 ether);
        vm.deal(standardUser, 5 ether);

        vm.prank(OwnerWallet);

        nft = new MockKoalas(merkleRoot);
        points = new KoalaPoints();
        pool = new MasterKoala(OwnerWallet, address(nft), address(points));
        points.mint(address(pool), 100_000 ether);

        vm.startPrank(preferredUser);
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = bytes32(0x6f98e13f3232e83666c2a5b9deb152698d886b1d8ed56d6702c7dc1faf56232e);
        nft.prefferedMint{ value:0.5 ether }(proof, 0);
        vm.stopPrank();

        vm.startPrank(standardUser);
        nft.mint{ value: 1 ether }();
        assertEq(nft.balanceOf(standardUser), 1);
        vm.stopPrank();

    }

    function test_stake() public {
        vm.startPrank(preferredUser);
        nft.approve(address(pool), 0);
        pool.stake(0);    
        assertEq(nft.balanceOf(address(pool)), 1);
        vm.stopPrank();
    }
    function test_one_stake_gets_all_points() public {
        test_stake();
        vm.roll(block.number + 10);
        vm.startPrank(preferredUser);
        pool.withdraw(0);
        vm.stopPrank();
        assertEq(points.balanceOf(preferredUser), 10_000 ether);
    }
    function test_one_staker_joins_after_10_blocks() public {
        test_stake();
        vm.roll(block.number + 10);
        vm.startPrank(standardUser);
        nft.approve(address(pool), 1);
        pool.stake(1);
        vm.stopPrank();
        vm.roll(block.number + 10);

        // user1 gets 10,000 + 5000
        // user2 gets 5000
        vm.prank(preferredUser);
        pool.withdraw(0);
        assertEq(points.balanceOf(preferredUser), 15_000 ether);
        vm.prank(standardUser);
        pool.withdraw(1);
        assertEq(points.balanceOf(standardUser), 5_000 ether);
    }

    function test_reverts_withdraw_twice() public {
        test_one_stake_gets_all_points();
        vm.roll(block.number + 10);
        vm.prank(preferredUser);
        vm.expectRevert(
            abi.encodeWithSelector(MasterKoala_NotStaked.selector)
        );
        pool.withdraw(0);
    }
    function test_user_stakes_unstakes_restakes() public {
        test_stake();
        vm.roll(block.number + 10);
        vm.startPrank(standardUser);
        nft.approve(address(pool), 1);
        pool.stake(1);
        vm.roll(block.number + 10);

        // remove (+5k)
        pool.withdraw(1);
        assertEq(points.balanceOf(standardUser), 5_000 ether);

        // 10 more blocks pass
        vm.roll(block.number + 10);

        // stake again
        nft.approve(address(pool), 1);
        pool.stake(1);
        vm.roll(block.number + 10);

        // remove again (+5k)
        pool.withdraw(1);
        assertEq(points.balanceOf(standardUser), 10_000 ether);
        vm.stopPrank();

        // remove preffered (+30k)
        vm.startPrank(preferredUser);
        pool.withdraw(0);
        assertEq(points.balanceOf(preferredUser), 30_000 ether);

    }
}