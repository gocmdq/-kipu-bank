// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/// @title KipuBank - Banco descentralizado simple
/// @author GOC 
/// @notice Cada usuario tiene su bóveda personal de ETH.
contract KipuBank {

    /*//////////////////////////////////////////////////////////////
                                ERRORES
    //////////////////////////////////////////////////////////////*/
    error KipuBank_DepositosLimiteReachazado();
    error KipuBank_LimiteRetirosExcedidos(uint256 requested, uint256 limit);
    error KipuBank_SaldoInsuficiente(uint256 requested, uint256 available);

    /*//////////////////////////////////////////////////////////////
                                EVENTOS
    //////////////////////////////////////////////////////////////*/
    event Depo(address indexed user, uint256 amount);
    event Reti(address indexed user, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                           VARIABLES DE ESTADO
    //////////////////////////////////////////////////////////////*/
/// @notice bóveda personal de cada usuario
    mapping(address => uint256) private s_boveda;

    /// @notice límite global de depósitos
    //  bankCap
    uint256 public immutable i_LimiteDepositos;

    /// @notice límite de retiro por transacción
    uint256 public immutable i_LimiteRetirosXTransaccion;

    /// @notice total de depósitos acumulados
    uint256 public s_TotalDepositosAcumulados;

    uint256 private s_TotalDepositosRealizados;
    uint256 private s_TotalRetirosRealizados; 
   

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(uint256 _LimiteDepositos, uint256 _LimiteRetirosXTransaccion) {
        i_LimiteDepositos = _LimiteDepositos;
        i_LimiteRetirosXTransaccion = _LimiteRetirosXTransaccion;
    }

    /*//////////////////////////////////////////////////////////////
                               FUNCIONES
    //////////////////////////////////////////////////////////////*/

    //@notice Permite depositar ETH en tu bóveda
    function depositar() external payable {

        //uint256  u_EtherDepositado = msg.value * 1000000000000000000;
        
        if (s_TotalDepositosAcumulados + msg.value > i_LimiteDepositos) {
            revert KipuBank_DepositosLimiteReachazado();
        }
        

        s_boveda[msg.sender] += msg.value;
        s_TotalDepositosAcumulados += msg.value;
        s_TotalDepositosRealizados++;

        emit Depo(msg.sender, msg.value);
    }
    /// @notice Devuelve el saldo en bóveda de un usuario
    /// @param _user Dirección del usuario
    /// @return  saldo en wei
    function ObtenerSaldo(address _user) external view returns ( uint256) {
        return s_boveda[_user];
    }
    
    /// @notice Devuelve la cantidad rde retiros realizados x el SC
    function ObtenerCantidadRetiros() external view returns (uint256) {
        return s_TotalRetirosRealizados;
    }
 
     /// @notice Devuelve la cantidad rde depositos realizados x el SC
    function ObtenerCantidadDepositos() external view returns (uint256) {
        return s_TotalDepositosRealizados;
    }

    /// @notice calcula la cantidad de Operaciones
    function CalculaCantidadOperaciones() private view returns (uint256){

        return s_TotalDepositosRealizados + s_TotalRetirosRealizados;
    }

    /// @notice Devuelve la cantidad Operaciones realizados x el SC
    function ObtenerCantidadOperacionesRealizadas() public view returns (uint256){
        return CalculaCantidadOperaciones();
    }    

    /// @notice Retira ether del depodito y lo retorna a la cuenta que invoca
    /// @param _cantidad cantidad de ether en wei a retirar de la boveda de la cuenta 
    function Retirar(uint256 _cantidad) external {
        
        if (_cantidad > i_LimiteRetirosXTransaccion) {
            revert KipuBank_LimiteRetirosExcedidos(_cantidad, i_LimiteRetirosXTransaccion);
        }
        if (_cantidad > s_boveda[msg.sender]) {
            revert KipuBank_SaldoInsuficiente(_cantidad, s_boveda[msg.sender]);
        }
       
        // Resto el retiro al saldo en la boveda
        s_boveda[msg.sender] -= _cantidad;
        
        //resto al Total de 
        s_TotalDepositosAcumulados -= _cantidad;

        s_TotalRetirosRealizados++;

        (bool ok, ) = msg.sender.call{value: _cantidad}("");
        // esto consume mas gas; mejor mensaje de error
        //reemplazar x error
        require(ok, "Falla Traferencia");

        emit Reti(msg.sender, _cantidad);
    }

}
