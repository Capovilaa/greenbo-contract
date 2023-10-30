// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract GreenCarbon {
    string public projeto = "Green Carbon";
    uint256 idAuxiliar = 0;
    mapping (uint256 => address) private historicoSenders;

    // Função que recebe dinheiro
    function recebeCreditoCarbono() public payable {        
        historicoSenders[idAuxiliar] = msg.sender; 
        idAuxiliar++;       
    }

    receive() external payable {
        recebeCreditoCarbono();
    }

    // Função que retorna quanto de saldo o contrato possui
    function getSaldo() public view returns (uint256) {
        return address(this).balance;
    }

    // Função que retorna uma lista com o histórico de senders
    function getHistSenders() public view returns (address[] memory) {
        address[] memory retorno = new address[](idAuxiliar);
        for (uint256 i = 0; i < idAuxiliar; i++) {
            retorno[i] = historicoSenders[i];
        }
        return retorno;
    }
}