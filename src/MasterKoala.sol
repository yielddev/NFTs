// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Ownable2Step} from "@openzeppelin/contracts@v5.0.1/access/Ownable2Step.sol";
import {Ownable} from "@openzeppelin/contracts@v5.0.1/access/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts@v5.0.1/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts@v5.0.1/token/ERC20/ERC20.sol";
import {KoalaPoints} from "./KoalaPoints.sol";
error MasterKoala_NotTokenOwner();
error MasterKoala_NotStaked();
contract MasterKoala is Ownable2Step{
    address public immutable koalaPoints;
    address public immutable koalaNFT;
    uint256 public immutable POINTS_POOL = 100_000 ether;
    uint256 public immutable POINTS_PER_BLOCK = 1_000 ether;
    uint256 public accRewardPerShare;
    uint256 public lastRewardBlock;
    struct DepositInfo {
        uint256 startingReward;
        address user;
    }
    mapping (uint256 => DepositInfo) public userStaked;
    constructor(address _admin, address _koalaNFT, address _koalaPoints) Ownable(_admin) {
        koalaNFT = _koalaNFT;
        koalaPoints = _koalaPoints;
    }

    function stake(uint256 tokenId) public {
        updatePool();
        userStaked[tokenId] = DepositInfo({
            startingReward: accRewardPerShare,
            user: msg.sender
        });
        IERC721(koalaNFT).transferFrom(msg.sender, address(this), tokenId);
    }

    function withdraw(uint256 tokenId) public {
    if (IERC721(koalaNFT).ownerOf(tokenId) != address(this)) revert MasterKoala_NotStaked();
    if (userStaked[tokenId].user != msg.sender) revert MasterKoala_NotTokenOwner();
        updatePool();
        payoutReward(tokenId);
        delete userStaked[tokenId];
        IERC721(koalaNFT).safeTransferFrom(address(this), msg.sender, tokenId);
    } 

    function payoutReward(uint256 tokenId) internal {
        uint256 reward = (accRewardPerShare - userStaked[tokenId].startingReward);
        IERC20(koalaPoints).transfer(userStaked[tokenId].user, reward);
    }

    function updatePool() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }
        uint256 stakedSupply = IERC721(koalaNFT).balanceOf(address(this));
        if (stakedSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 rewards = (block.number - lastRewardBlock) * POINTS_PER_BLOCK;
        accRewardPerShare += (rewards / stakedSupply);
        lastRewardBlock = block.number;
    }

}