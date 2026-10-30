-- ============================================================
-- SCRIPT COMPLETO DE BANCO DE DADOS - SCOPINO AUTO CLUB
-- Sistema de Gestão de Oficina Mecânica
-- SGBD: MySQL 8.0+
-- ============================================================

CREATE DATABASE IF NOT EXISTS scopino_db
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE scopino_db;

-- ------------------------------------------------------------
-- 1. ESTRUTURA DDL (CRIAÇÃO DE TABELAS E RESTRIÇÕES)
-- ------------------------------------------------------------

-- Tabela: CLIENTE
CREATE TABLE CLIENTE (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cpf_cnpj VARCHAR(20) UNIQUE NOT NULL,
    telefone VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    endereco VARCHAR(150),
    data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Tabela: VEICULO
CREATE TABLE VEICULO (
    id_veiculo INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    placa VARCHAR(10) UNIQUE NOT NULL,
    marca VARCHAR(50) NOT NULL,
    modelo VARCHAR(50) NOT NULL,
    ano INT NOT NULL,
    cor VARCHAR(30),
    km_atual INT DEFAULT 0,
    FOREIGN KEY (id_cliente) REFERENCES CLIENTE(id_cliente) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Tabela: MECANICO
CREATE TABLE MECANICO (
    id_mecanico INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    especialidade VARCHAR(50) NOT NULL,
    telefone VARCHAR(20) NOT NULL,
    ativo BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB;

-- Tabela: SERVICO (Catálogo de Serviços)
CREATE TABLE SERVICO (
    id_servico INT AUTO_INCREMENT PRIMARY KEY,
    descricao VARCHAR(100) NOT NULL,
    preco_base DECIMAL(10,2) NOT NULL CHECK (preco_base >= 0)
) ENGINE=InnoDB;

-- Tabela: PECA (Estoque de Peças)
CREATE TABLE PECA (
    id_peca INT AUTO_INCREMENT PRIMARY KEY,
    descricao VARCHAR(100) NOT NULL,
    valor_unitario DECIMAL(10,2) NOT NULL CHECK (valor_unitario >= 0),
    estoque INT NOT NULL DEFAULT 0 CHECK (estoque >= 0)
) ENGINE=InnoDB;

-- Tabela: ORDEM_SERVICO
CREATE TABLE ORDEM_SERVICO (
    id_os INT AUTO_INCREMENT PRIMARY KEY,
    id_veiculo INT NOT NULL,
    id_mecanico INT NOT NULL,
    data_abertura DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_conclusao DATETIME,
    status VARCHAR(20) NOT NULL DEFAULT 'Aberta' CHECK (status IN ('Aberta', 'Em Andamento', 'Aguardando Peça', 'Concluída', 'Cancelada')),
    observacoes TEXT,
    valor_total DECIMAL(10,2) DEFAULT 0.00 CHECK (valor_total >= 0),
    FOREIGN KEY (id_veiculo) REFERENCES VEICULO(id_veiculo) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_mecanico) REFERENCES MECANICO(id_mecanico) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Tabela Associativa N:N -> OS_SERVICO
CREATE TABLE OS_SERVICO (
    id_os INT NOT NULL,
    id_servico INT NOT NULL,
    quantidade INT NOT NULL DEFAULT 1 CHECK (quantidade > 0),
    valor_praticado DECIMAL(10,2) NOT NULL CHECK (valor_praticado >= 0),
    PRIMARY KEY (id_os, id_servico),
    FOREIGN KEY (id_os) REFERENCES ORDEM_SERVICO(id_os) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_servico) REFERENCES SERVICO(id_servico) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Tabela Associativa N:N -> OS_PECA
CREATE TABLE OS_PECA (
    id_os INT NOT NULL,
    id_peca INT NOT NULL,
    quantidade INT NOT NULL DEFAULT 1 CHECK (quantidade > 0),
    valor_praticado DECIMAL(10,2) NOT NULL CHECK (valor_praticado >= 0),
    PRIMARY KEY (id_os, id_peca),
    FOREIGN KEY (id_os) REFERENCES ORDEM_SERVICO(id_os) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_peca) REFERENCES PECA(id_peca) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 2. CARGA DE DADOS (DML)
-- ------------------------------------------------------------

INSERT INTO CLIENTE (nome, cpf_cnpj, telefone, email, endereco) VALUES
('Carlos Eduardo Silva', '111.222.333-44', '(11) 98888-1111', 'carlos.silva@email.com', 'Rua Domingos de Morais, 120 - São Paulo/SP'),
('Ana Maria Souza', '222.333.444-55', '(11) 97777-2222', 'ana.souza@email.com', 'Av. Celso Garcia, 450 - São Paulo/SP'),
('Roberto Machado', '333.444.555-66', '(11) 96666-3333', 'roberto.m@email.com', 'Rua Herwis, 88 - São Paulo/SP'),
('Fernanda Oliveira', '444.555.666-77', '(11) 95555-4444', 'fernanda.o@email.com', 'Rua Santa Eudóxia, 508 - São Paulo/SP');

INSERT INTO VEICULO (id_cliente, placa, marca, modelo, ano, cor, km_atual) VALUES
(1, 'ABC-1234', 'Volkswagen', 'Gol 1.0', 2018, 'Prata', 75000),
(2, 'XYZ-9876', 'Chevrolet', 'Onix 1.4', 2020, 'Preto', 45000),
(3, 'MNO-5566', 'Ford', 'Ka 1.5', 2019, 'Branco', 62000),
(4, 'JKL-3344', 'Fiat', 'Argo 1.3', 2021, 'Vermelho', 32000);

INSERT INTO MECANICO (nome, especialidade, telefone) VALUES
('João Pedro Ramos', 'Suspensão e Freios', '(11) 94444-5555'),
('Lucas Scopino', 'Injeção Eletrônica e Motor', '(11) 93333-6666'),
('Marcos Vinícius', 'Manutenção Preventiva', '(11) 92222-7777');

INSERT INTO SERVICO (descricao, preco_base) VALUES
('Troca de Óleo e Filtro', 150.00),
('Alinhamento e Balanceamento', 120.00),
('Revisão do Sistema de Freios', 200.00),
('Limpeza de Bicos Injetores', 250.00),
('Troca da Correia Dentada', 350.00);

INSERT INTO PECA (descricao, valor_unitario, estoque) VALUES
('Filtro de Óleo', 45.00, 50),
('Óleo Sintético 5W30 (Litro)', 42.00, 120),
('Jogo de Pastilhas de Freio', 180.00, 20),
('Disco de Freio Dianteiro (Par)', 320.00, 15),
('Correia Dentada', 110.00, 10),
('Tensor da Correia', 130.00, 12);

-- Inserção de Ordens de Serviço
INSERT INTO ORDEM_SERVICO (id_veiculo, id_mecanico, status, observacoes, valor_total) VALUES
(1, 1, 'Concluída', 'Troca de óleo e revisão de freios concluídas com sucesso.', 576.00),
(2, 2, 'Em Andamento', 'Veículo apresentando falhas na aceleração.', 370.00),
(3, 3, 'Aberta', 'Revisão geral pré-viagem.', 0.00);

-- Vínculo de Serviços executados na OS
INSERT INTO OS_SERVICO (id_os, id_servico, quantidade, valor_praticado) VALUES
(1, 1, 1, 150.00),
(1, 3, 1, 200.00),
(2, 4, 1, 250.00);

-- Vínculo de Peças aplicadas na OS
INSERT INTO OS_PECA (id_os, id_peca, quantidade, valor_praticado) VALUES
(1, 1, 1, 46.00),
(1, 2, 4, 45.00),
(2, 5, 1, 120.00);

-- ------------------------------------------------------------
-- 3. CONSULTAS GERENCIAIS E AUDITORIA
-- ------------------------------------------------------------

-- G01: Extrato detalhado de Ordens de Serviço
SELECT 
    os.id_os,
    c.nome AS cliente,
    v.modelo,
    v.placa,
    m.nome AS mecanico_responsavel,
    os.status,
    os.valor_total,
    os.data_abertura
FROM ORDEM_SERVICO os
INNER JOIN VEICULO v ON os.id_veiculo = v.id_veiculo
INNER JOIN CLIENTE c ON v.id_cliente = c.id_cliente
INNER JOIN MECANICO m ON os.id_mecanico = m.id_mecanico
ORDER BY os.data_abertura DESC;

-- G02: Faturamento Total e Quantidade de Atendimentos por Mecânico
SELECT 
    m.nome AS mecanico,
    COUNT(os.id_os) AS total_os,
    COALESCE(SUM(os.valor_total), 0) AS faturamento_gerado
FROM MECANICO m
LEFT JOIN ORDEM_SERVICO os ON m.id_mecanico = os.id_mecanico
GROUP BY m.id_mecanico, m.nome;

-- A01: Auditoria - Verificar Ordens de Serviço sem peças e sem serviços vinculados
SELECT id_os, status, data_abertura 
FROM ORDEM_SERVICO 
WHERE id_os NOT IN (SELECT DISTINCT id_os FROM OS_SERVICO)
  AND id_os NOT IN (SELECT DISTINCT id_os FROM OS_PECA);