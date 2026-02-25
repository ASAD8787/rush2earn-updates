// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract RushToken is ERC20, Ownable {
    constructor(address initialOwner, uint256 initialSupply) ERC20("Rush", "RUSH") Ownable(initialOwner) {
        require(initialOwner != address(0), "owner=0");
        require(initialSupply > 0, "supply=0");
        _mint(initialOwner, initialSupply);
    }
}
