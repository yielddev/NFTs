// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import {ERC20} from "@openzeppelin/contracts@v5.0.1/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts@v5.0.1/access/Ownable.sol";

error KoalaPoints_MaxSupplyReached();
contract KoalaPoints is ERC20, Ownable {
    uint256 public immutable SUPPLY_CAP = 100_000 ether;
    constructor() ERC20("KoalaPoints", "KP") Ownable(msg.sender) {
    }
    // mint
    function mint(address to, uint256 amount) public onlyOwner {
        if (totalSupply() + amount > SUPPLY_CAP) revert KoalaPoints_MaxSupplyReached();
        _mint(to, amount);
    }
}