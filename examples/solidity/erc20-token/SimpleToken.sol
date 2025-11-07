// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SimpleToken
 * @dev Implementation of a basic ERC-20 token with minting capabilities
 */
contract SimpleToken is ERC20, Ownable {
    uint8 private _decimals;
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10**18; // 1 billion tokens

    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);

    /**
     * @dev Constructor that gives msg.sender all of initial supply
     * @param name Token name
     * @param symbol Token symbol
     * @param initialSupply Initial supply of tokens (in whole units)
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) Ownable(msg.sender) {
        _decimals = 18;
        require(initialSupply * 10**_decimals <= MAX_SUPPLY, "Initial supply exceeds max supply");
        _mint(msg.sender, initialSupply * 10**_decimals);
    }

    /**
     * @dev Mints new tokens to a specified address
     * @param to The address that will receive the minted tokens
     * @param amount The amount of tokens to mint (in whole units)
     */
    function mint(address to, uint256 amount) public onlyOwner {
        uint256 mintAmount = amount * 10**_decimals;
        require(totalSupply() + mintAmount <= MAX_SUPPLY, "Would exceed max supply");
        _mint(to, mintAmount);
        emit TokensMinted(to, mintAmount);
    }

    /**
     * @dev Burns tokens from the caller's account
     * @param amount The amount of tokens to burn (in whole units)
     */
    function burn(uint256 amount) public {
        uint256 burnAmount = amount * 10**_decimals;
        _burn(msg.sender, burnAmount);
        emit TokensBurned(msg.sender, burnAmount);
    }

    /**
     * @dev Returns the number of decimals used to get its user representation
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}
