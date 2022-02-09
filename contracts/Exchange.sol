//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * Permite agregar liquidez de ether y token
 * Permite comprar ether - token
 * Tecnicamente es una pool de 2 activos
 * // todo: pensar funcionalidad para obtener el precio
 */
contract Exchange {
    address public tokenAddress;

    constructor(address _token) {
        require(_token != address(0), "Invalid address");
        tokenAddress = _token;
    }

    /**
     * - Transfiere desde el usuario al contrato Exchange
     * la cantidad _tokenAmount de tokenAddress.
     * - Para agregar liquidity se debe enviar : Ether y Token
     * - Se necesita pre aprobar la transacción
     */
    function addLiquidity(uint256 _tokenAmount) public payable {
        IERC20 token = IERC20(tokenAddress);

        token.transferFrom(msg.sender, address(this), _tokenAmount);
    }

    /**
     * Obtiene el balance de tokenAddress del exchange
     */
    function getReserve() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    /**
     * La funcion me dice que a determinado input de un activo y determinada
     * reserva cuanto activo me llevo de lo que estoy intercambiando.
     * Ejemplo:
     *         - si ingreso ether (inputAmount) recibo LucasCoin (outputAmount)
     *         - inputReserve = reserva de ether
     *         - outputReserve = reserva de LucasCoin
     * Bonding Curve = X * Y = K
     * Devuelve cuantos tokens debo recibir
     * X = inputReserve
     * Y = outputReserve
     * (X + dX) * (Y - dY) = K
     * dY = Y - dX ....... investigar mas...
     */
    function _getAmount(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) private pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "No Reserves");
        uint256 outputAmount = (inputAmount * outputReserve) /
            (inputReserve + inputAmount);
        return (outputAmount);
    }

    /**
     * Pongo ether, cuantos LucasCoin voy a recibir
     * Funcion de consulta
     */
    function getTokenAmount(uint256 _ethSold) public view returns (uint256) {
        require(_ethSold > 0, "Invalid ether amount");
        uint256 tokenReserve = getReserve();
        return _getAmount(_ethSold, address(this).balance, tokenReserve);
    }

    /**
     * Pongo LucasCoin, cuantos ether voy a recibir
     * Funcion de consulta
     */
    function getEthAmount(uint256 _tokenSold) public view returns (uint256) {
        require(_tokenSold > 0, "Invalid token amount");
        uint256 tokenReserve = getReserve();
        return _getAmount(_tokenSold, tokenReserve, address(this).balance);
    }
}
