// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract Parceiro {
    // Ideia inicial é de criar o contato com campos dos dados e realizar a leitura depois com funções    
    address idParceiro;
    address immutable carteira;
    address[] private senders; // Quem manda
    address[] private funders; // Quem recebe

    int256 private saldoCreditoCarbono;

    uint256 idGravacao = 0;
    uint256 fator = 2;

    // Para mapear históricos das leituras e transações
    mapping (uint256 => uint256) private historicoConsumoEnergia;
    mapping (uint256 => uint256) private historicoConsumoCO2;   
    mapping (uint256 => int256) private historicoSalcoCC;   
    mapping (address => uint256) private historicoTransacoes;
    mapping (uint256 => bytes32) private historicoHash; // ?
    mapping (uint256 => uint256) private historicoPlanejamento;

    // Struct com as informações necessárias para serem armazenadas  
    struct Transacoes {   
        uint256 idGravado;     
        uint256 consumoCO2;
        uint256 planejamentoConsumoMes;        
        uint256 consumoEnergia;
        uint256 mes;
    }

    Transacoes[] private transacoes;    

    // Construtor para salvar a carteira
    constructor(){
        carteira = msg.sender;
    }

    // Função que vai gravar os dados do parceiro na Blockchain
    function gravarDados(uint256 _consumoCO2, uint256 _planejamentoConsumoMes, uint256 _consumoEnergia, uint256 _mes) public {
        
        // Cria um objeto para armazenar as informações vindas por parâmetro
        Transacoes memory novaTransacao = Transacoes(idGravacao, _consumoCO2, _planejamentoConsumoMes, _consumoEnergia, _mes);
        transacoes.push(novaTransacao);

        // Armazena nos mappings para acessos futuros
        historicoConsumoEnergia[idGravacao] = _consumoEnergia;
        historicoConsumoCO2[idGravacao] = _consumoEnergia;  
        historicoPlanejamento[idGravacao] = _planejamentoConsumoMes;

        // Após cada leitura, atualizar o saldo do crédito de carbono
        alteraCreditoCarbono(_consumoEnergia, _planejamentoConsumoMes);    
    }

    // Função para calcular crédito de carbono dele (planejamento - emissão) * fator
    function alteraCreditoCarbono (uint256 _consumo, uint256 _previsao) private  {
        int256 calculo = (int256(_previsao) - int256(_consumo)) * int256(fator);                
        saldoCreditoCarbono += calculo;        
        historicoSalcoCC[idGravacao] = saldoCreditoCarbono;

        // idGravacao é a sentinela que controla o índice
        idGravacao++;
    }
    

    // Função para adicionar fundos ao contrato (créditos de carbono)
    function adicionaFundos() public payable {
        funders.push(msg.sender);
        historicoTransacoes[msg.sender] = msg.value;
    }
    
    receive() external payable {
        adicionaFundos();
    }

    // ------- GETS ------- //

    // Função para ler os dados pelo índice
    function getLeiturasDados(uint i) public view returns (uint256, uint256) {
        require(i < transacoes.length, "Indice invalido");
        Transacoes memory novaTransacao = transacoes[i];
        return (novaTransacao.consumoCO2, novaTransacao.planejamentoConsumoMes);
    }
    
    // Função para retornar o saldo do crédito de carbono atual
    function getSaldoCC() public view returns(int256){
        return saldoCreditoCarbono;
    }

    // Função para retornar histórico de saldos de crédito de carbono por parâmetro    
    function getHistSaldoCC() public  view returns (int256[] memory){
        int256[] memory retorno = new int256[](idGravacao);
        for(uint i = 0; i < idGravacao; i++ ){
            retorno[i] = historicoSalcoCC[i];
        }
        return retorno;
    }   


    // Função para retornar histórico de consumo de CO2 por parâmetro
    function getHistConsumoCO2() public view returns(uint256[] memory){
        uint256[] memory retorno = new uint256[](idGravacao);
        for(uint i = 0; i < idGravacao; i++ ){
            retorno[i] = historicoConsumoCO2[i];
        }
        return retorno;
    }

    // Função para retornar histórico de consumo de energia por parâmetro
    function getHistConsumoEnergia() public view returns(uint256[] memory){
        uint256[] memory retorno = new uint256[](idGravacao);
        for(uint i = 0; i < idGravacao; i++ ){
            retorno[i] = historicoConsumoEnergia[i];
        }
        return retorno;
    }

    // Função para retornar o saldo do contrato
    function getSaldo() public view returns (uint){
        return address(this).balance;
    }
}