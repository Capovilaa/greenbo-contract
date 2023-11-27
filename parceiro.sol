// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract Parceiro {
    // Ideia inicial é de criar o contato com campos dos dados e realizar a leitura depois com funções
    address idParceiro;
    address immutable carteira;
    address[] private senders; // Quem manda
    address[] private funders; // Quem recebe

    int256 private saldoCreditoCarbono = 0;

    uint256 idGravacao = 0;
    uint256 immutable i_fator = 426;

    // Para mapear históricos das leituras e transações
    mapping(uint256 => uint256) private historicoPlanCombMovel; // planejamento combustão móvel
    mapping(uint256 => uint256) private historicoCombMovel; // combustão móvel

    mapping(uint256 => uint256) private historicoPlanCombEstac; // planejamento combustão estacionária
    mapping(uint256 => uint256) private historicoCombEstac; // combustão estacionária

    mapping(uint256 => uint256) private historicoPlanejamentoEnergia;
    mapping(uint256 => uint256) private historicoConsumoEnergia;

    mapping(uint256 => uint256) private historicoConsumoCO2; // recebe o cálculo da soma de todos os consumos

    mapping(uint256 => int256) private historicoSalcoCC;

    mapping(uint256 => uint256) private historicoTransacoes;

    mapping(uint256 => bytes32) private historicoHash;

    // Struct com as informações necessárias para serem armazenadas
    struct Transacoes {
        uint256 idGravado;
        uint256 planCombMovel;
        uint256 combMovel;
        uint256 planCombEstac;
        uint256 combEstac;
        uint256 planConsumoEnergia;
        uint256 consumoEnergia;
        uint256 mes;
    }

    Transacoes[] private transacoes;

    // Construtor para salvar a carteira
    constructor() {
        carteira = msg.sender;
    }

    // Função que vai gravar os dados do parceiro na Blockchain
    function gravarDados(
        uint256 _planCombMovel,
        uint256 _combMovel,
        uint256 _planCombEstac,
        uint256 _combEstac,
        uint256 _planConsEnergia,
        uint256 _consumoEnergia,
        uint256 _mes
    ) public {
        // Cria um objeto para armazenar as informações vindas por parâmetro
        Transacoes memory novaTransacao = Transacoes(
            idGravacao,
            _planCombMovel,
            _combMovel,
            _planCombEstac,
            _combEstac,
            _planConsEnergia,
            _consumoEnergia,
            _mes
        );
        transacoes.push(novaTransacao);

        // Armazena nos mappings para acessos futuros
        historicoPlanCombMovel[idGravacao] = _planCombMovel;
        historicoCombMovel[idGravacao] = _combMovel;

        historicoPlanCombEstac[idGravacao] = _planCombEstac;
        historicoCombEstac[idGravacao] = _combEstac;

        historicoPlanejamentoEnergia[idGravacao] = _planConsEnergia;
        historicoConsumoEnergia[idGravacao] = _consumoEnergia;

        uint256 teste = calcularCO2Energia(_consumoEnergia);

        historicoConsumoCO2[idGravacao] = _combEstac + _combMovel + teste;

        // Após cada leitura, atualizar o saldo do crédito de carbono
        // O saldo está sendo calculado pelo planejamento - consumo
        alteraCreditoCarbono(_planConsEnergia + _planCombMovel + _planCombEstac, _combEstac + _combMovel + _consumoEnergia);
    }

    // Função para calcular co2 pelo consumo de energia
    function calcularCO2Energia(uint256 _consumoEnergia)
        private
        pure
        returns (uint256)
    {
        return _consumoEnergia * i_fator;
    }

    // Função para calcular crédito de carbono dele (planejamento - emissão) * i_fator
    function alteraCreditoCarbono(uint256 _plan, uint256 _consumo) private {
        if (idGravacao != 0) {
            int256 calculo = (int256(_plan) - int256(_consumo));            
            saldoCreditoCarbono += calculo;
        }
        historicoSalcoCC[idGravacao] = saldoCreditoCarbono;

        // idGravacao é a sentinela que controla o índice
        idGravacao++;
    }

    // Função para adicionar fundos ao contrato (créditos de carbono)
    function adicionaFundos() public payable {
        funders.push(msg.sender);
        historicoTransacoes[idGravacao] = msg.value;
    }

    receive() external payable {
        adicionaFundos();
    }

    // Função que envia creditos de carbono
    function enviaCredito(int256 _qnt) public restricted {
        require(
            _qnt <= saldoCreditoCarbono,
            "Saldo de creditos de carbono insuficiente"
        );
        saldoCreditoCarbono -= _qnt;
    }

    // ------- GETS ------- //

    // Função que retorna histórico de plan comb movel
    function getHistPlanCombMovel() public view returns (uint256[] memory) {
        uint256[] memory retorno = new uint256[](idGravacao);
        for (uint256 i = 0; i < idGravacao; i++) {
            retorno[i] = historicoPlanCombMovel[i];
        }
        return retorno;
    }

    // Função que retorna histórico de comb movel
    function getHistCombMovel() public view returns (uint256[] memory) {
        uint256[] memory retorno = new uint256[](idGravacao);
        for (uint256 i = 0; i < idGravacao; i++) {
            retorno[i] = historicoCombMovel[i];
        }
        return retorno;
    }

    // Função que retorna histórico de plan comb estac
    function getHistPlanCombEstac() public view returns (uint256[] memory) {
        uint256[] memory retorno = new uint256[](idGravacao);
        for (uint256 i = 0; i < idGravacao; i++) {
            retorno[i] = historicoPlanCombEstac[i];
        }
        return retorno;
    }

    // Função que retorna histórico de comb estac
    function getHistCombEstac() public view returns (uint256[] memory) {
        uint256[] memory retorno = new uint256[](idGravacao);
        for (uint256 i = 0; i < idGravacao; i++) {
            retorno[i] = historicoCombEstac[i];
        }
        return retorno;
    }

    // Função para retornar histórico de consumo de energia por parâmetro
    function getHistPlanConsumoEnergia()
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory retorno = new uint256[](idGravacao);
        for (uint256 i = 0; i < idGravacao; i++) {
            retorno[i] = historicoPlanejamentoEnergia[i];
        }
        return retorno;
    }

    // Função para retornar histórico de consumo do planejamento de energia por parâmetro
    function getHistConsumoEnergia() public view returns (uint256[] memory) {
        uint256[] memory retorno = new uint256[](idGravacao);
        for (uint256 i = 0; i < idGravacao; i++) {
            retorno[i] = historicoConsumoEnergia[i];
        }
        return retorno;
    }

    // Função para retornar histórico de saldos de crédito de carbono por parâmetro
    function getHistSaldoCC() public view returns (int256[] memory) {
        int256[] memory retorno = new int256[](idGravacao);
        for (uint256 i = 0; i < idGravacao; i++) {
            retorno[i] = historicoSalcoCC[i];
        }
        return retorno;
    }

    // Função para retornar histórico de transações
    function getHistTransacoes() public view returns (uint256[] memory) {
        uint256[] memory retorno = new uint256[](idGravacao);
        for (uint256 i = 0; i < idGravacao; i++) {
            retorno[i] = historicoTransacoes[i];
        }
        return retorno;
    }

    // Função para retornar histórico de consumo de CO2 por parâmetro
    function getHistConsumoCO2() public view returns (uint256[] memory) {
        uint256[] memory retorno = new uint256[](idGravacao);
        for (uint256 i = 0; i < idGravacao; i++) {
            retorno[i] = historicoConsumoCO2[i];
        }
        return retorno;
    }

    // Função para retornar o saldo do contrato
    function getSaldo() public view returns (uint256) {
        return address(this).balance;
    }

    // Função para retornar o saldo do contrato
    function getSaldoCreditoCarbono() public view returns (int256) {
        return saldoCreditoCarbono;
    }

    modifier restricted() {
        require(msg.sender == carteira);
        _;
    }
}
