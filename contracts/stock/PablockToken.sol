// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PablockToken is ERC20 {
    address contractOwner;
    uint256 maxSupply;
    uint256 MAX_ALLOWANCE = 2 ^ (256 - 1);

    modifier byOwner(){
        require(contractOwner == msg.sender, "Not allowed");
        _;
    }
            
    constructor (uint256 _maxSupply)  ERC20("PablockToken", "PTK") {
        contractOwner = msg.sender;
        maxSupply = _maxSupply;
    }

    function requestToken(address to, uint256 mintQuantity) public byOwner {
        require(
            maxSupply >= totalSupply() + mintQuantity,
            "Would exceed max supply"
        );
        _mint(to, mintQuantity);
    }

    function changeOwner(address _newOwner) public byOwner {
        contractOwner = _newOwner;
    }

     function changeMaxSupply(uint256 _maxSupply) public byOwner {
        maxSupply = _maxSupply;
    }


    function unlimitedApprove() external {
        _approve(msg.sender, address(this), MAX_ALLOWANCE);
    }

    function receiveAndBurn(uint256 amount, address addr) public {
        _burn(addr, amount);
    }
}