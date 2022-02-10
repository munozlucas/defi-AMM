//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Exchange.sol";

/**
 * Contrato para crear los diferentes exchanges dinamicamente
 * Tiene el registro de todos los exchanges
 */
contract Registry {
    // mapeo de token al exchange
    mapping(address => address) public tokenToExchange;

    event NewExchange(address indexed token, address indexed exchange);

    function getExchange(address _tokenAddress) public view returns (address) {
        return tokenToExchange[_tokenAddress];
    }

    function createExchange(address _tokenAddress) public returns (address) {
        require(_tokenAddress != address(0), "Invalid token address");
        require(
            tokenToExchange[_tokenAddress] == address(0),
            "Exchange already exists"
        );

        Exchange exchange = new Exchange(_tokenAddress);
        tokenToExchange[_tokenAddress] = address(exchange);
        
        emit NewExchange(_tokenAddress, address(exchange));

        return address(exchange);
    }
}
