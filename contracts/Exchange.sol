//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * Permite agregar liquidez de ether y token
 * Permite comprar ether - token
 * Tecnicamente es una pool de 2 activos
 * // todo: pensar funcionalidad para obtener el precio
 */
contract Exchange is ERC20 {
    address public tokenAddress;

    constructor(address _token) ERC20("LP Token", "LP") {
        require(_token != address(0), "Invalid address");
        tokenAddress = _token;
    }

    /**
     * - Transfiere desde el usuario al contrato Exchange
     * la cantidad _tokenAmount de tokenAddress.
     * - Para agregar liquidity se debe enviar : Ether y Token
     * - Se necesita pre aprobar la transacción
     * - LPtokens: voy a recibir x lptokens proporcional a la cantidad
     *             myLPTokens = totalLPTokens * (ethDeposited / ethReserve)
     * de ether depositado
     */
    function addLiquidity(uint256 _tokenAmount)
        public
        payable
        returns (uint256)
    {
        uint256 tokenReserve = getReserve();
        uint256 mintLPTokens;
        if (totalSupply() == 0) {
            mintLPTokens = address(this).balance;
        } else {
            uint256 ethReserve = address(this).balance - msg.value;
            uint256 correctTokenAmount = (msg.value * tokenReserve) /
                ethReserve;
            require(_tokenAmount >= correctTokenAmount, "No enough tokens");
            mintLPTokens = totalSupply() * (msg.value / ethReserve);
        }
        IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _tokenAmount
        );
        _mint(msg.sender, mintLPTokens);

        return mintLPTokens;
    }

    /**
     * - Devuelve el ether y el token que le corresponde proporcionalmente a
     * lo que quiero sacar
     * -  _amount es la cantidad de LPTokens
     * - transfiere el ether y token correspondiente al sender
     * - quema los tokens que el sender manda
     */
    function removeLiquidity(uint256 _amount)
        public
        returns (uint256, uint256)
    {
        require(_amount > 0, "Invalid amount");

        uint256 ethAmount = (address(this).balance * _amount) / totalSupply();
        uint256 tokenAmount = (getReserve() * _amount) / totalSupply();

        _burn(msg.sender, _amount);

        payable(msg.sender).transfer(ethAmount);
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);

        return (ethAmount, tokenAmount);
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
        // uint256 outputAmount = (inputAmount * outputReserve) /
        //     (inputReserve + inputAmount);

        uint256 fee = 99; // todo: poder cambiar con governance
        uint256 inputAmountWithFee = inputAmount * fee;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;

        return (numerator / denominator);
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

    /**
     * Función para vender ether y comprar tokens
     */
    function ethToTokenSwap(uint256 _minTokens) public payable {
        uint256 tokenReserve = getReserve();
        uint256 tokensBought = _getAmount(
            msg.value,
            address(this).balance - msg.value, // importante hacer la resta
            tokenReserve
        );
        require(tokensBought >= _minTokens, "Not enough tokens to sell");
        IERC20(tokenAddress).transfer(msg.sender, tokensBought);
    }

    /**
     * Función para vender token y comprar ether
     * Se necesita pre aprobar
     */
    function tokenToEthSwap(uint256 _tokensSold, uint256 _minEth) public {
        uint256 tokenReserve = getReserve();
        uint256 etherBought = _getAmount(
            _tokensSold,
            tokenReserve,
            address(this).balance
        );
        require(etherBought >= _minEth, "Not enough ether to sell");
        IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _tokensSold
        );
        payable(msg.sender).transfer(etherBought);
    }
}
