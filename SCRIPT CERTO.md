-- ============================================================
-- SCRIPT COMPLETO DE BANCO DE DADOS - SCOPINO AUTO CLUB
-- SGBD: MySQL 8.0.16+
-- Observação: os dados abaixo são fictícios e ilustrativos.
-- ============================================================

CREATE DATABASE IF NOT EXISTS oficina_scopino;
USE oficina_scopino;

-- ------------------------------------------------------------
-- 1. CRIAÇÃO DAS TABELAS
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS CLIENTE (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cpf_cnpj VARCHAR(20) NOT NULL UNIQUE,
    telefone VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    logradouro VARCHAR(100),
    numero VARCHAR(20),
    bairro VARCHAR(50),
    cidade VARCHAR(50) DEFAULT 'São Paulo',
    cep VARCHAR(10)
);

CREATE TABLE IF NOT EXISTS VEICULO (
    id_veiculo INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    placa VARCHAR(10) NOT NULL UNIQUE,
    marca VARCHAR(50) NOT NULL,
    modelo VARCHAR(50) NOT NULL,
    ano INT NOT NULL,
    quilometragem INT NOT NULL DEFAULT 0 CHECK (quilometragem >= 0),
    CONSTRAINT fk_veiculo_cliente
        FOREIGN KEY (id_cliente) REFERENCES CLIENTE(id_cliente)
        ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS MECANICO (
    id_mecanico INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    especialidade VARCHAR(50),
    telefone VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS PECA (
    id_peca INT AUTO_INCREMENT PRIMARY KEY,
    descricao VARCHAR(100) NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL CHECK (preco_unitario >= 0),
    quantidade_estoque INT NOT NULL DEFAULT 0 CHECK (quantidade_estoque >= 0),
    estoque_minimo INT NOT NULL DEFAULT 5 CHECK (estoque_minimo >= 0)
);

CREATE TABLE IF NOT EXISTS SERVICO (
    id_servico INT AUTO_INCREMENT PRIMARY KEY,
    descricao VARCHAR(100) NOT NULL,
    preco_base DECIMAL(10,2) NOT NULL CHECK (preco_base >= 0)
);

CREATE TABLE IF NOT EXISTS ORDEM_SERVICO (
    id_os INT AUTO_INCREMENT PRIMARY KEY,
    id_veiculo INT NOT NULL,
    id_mecanico INT NOT NULL,
    data_abertura DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_conclusao DATETIME NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Aberta'
        CHECK (status IN ('Aberta', 'Em Andamento', 'Concluída', 'Cancelada')),
    valor_total DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (valor_total >= 0),
    observacoes TEXT,
    CONSTRAINT fk_os_veiculo
        FOREIGN KEY (id_veiculo) REFERENCES VEICULO(id_veiculo),
    CONSTRAINT fk_os_mecanico
        FOREIGN KEY (id_mecanico) REFERENCES MECANICO(id_mecanico)
);

CREATE TABLE IF NOT EXISTS OS_PECA (
    id_os INT NOT NULL,
    id_peca INT NOT NULL,
    quantidade INT NOT NULL CHECK (quantidade > 0),
    preco_praticado DECIMAL(10,2) NOT NULL CHECK (preco_praticado >= 0),
    PRIMARY KEY (id_os, id_peca),
    CONSTRAINT fk_ospeca_os
        FOREIGN KEY (id_os) REFERENCES ORDEM_SERVICO(id_os)
        ON DELETE CASCADE,
    CONSTRAINT fk_ospeca_peca
        FOREIGN KEY (id_peca) REFERENCES PECA(id_peca)
);

CREATE TABLE IF NOT EXISTS OS_SERVICO (
    id_os INT NOT NULL,
    id_servico INT NOT NULL,
    quantidade INT NOT NULL DEFAULT 1 CHECK (quantidade > 0),
    preco_praticado DECIMAL(10,2) NOT NULL CHECK (preco_praticado >= 0),
    PRIMARY KEY (id_os, id_servico),
    CONSTRAINT fk_osservico_os
        FOREIGN KEY (id_os) REFERENCES ORDEM_SERVICO(id_os)
        ON DELETE CASCADE,
    CONSTRAINT fk_osservico_servico
        FOREIGN KEY (id_servico) REFERENCES SERVICO(id_servico)
);

CREATE TABLE IF NOT EXISTS PAGAMENTO (
    id_pagamento INT AUTO_INCREMENT PRIMARY KEY,
    id_os INT NOT NULL,
    data_pagamento DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valor_pago DECIMAL(10,2) NOT NULL CHECK (valor_pago > 0),
    forma_pagamento VARCHAR(30) NOT NULL
        CHECK (forma_pagamento IN (
            'Dinheiro',
            'Cartão de Crédito',
            'Cartão de Débito',
            'Pix'
        )),
    CONSTRAINT fk_pagamento_os
        FOREIGN KEY (id_os) REFERENCES ORDEM_SERVICO(id_os)
);

-- ------------------------------------------------------------
-- 2. TRIGGERS: CONTROLE DE ESTOQUE E RECÁLCULO DE VALORES
-- ------------------------------------------------------------

DELIMITER $$

CREATE TRIGGER trg_os_peca_bi
BEFORE INSERT ON OS_PECA
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(20);
    DECLARE v_estoque INT;

    SELECT status INTO v_status
    FROM ORDEM_SERVICO
    WHERE id_os = NEW.id_os;

    IF v_status IN ('Concluída', 'Cancelada') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
            'Não é permitido adicionar peças a uma OS concluída ou cancelada.';
    END IF;

    SELECT quantidade_estoque INTO v_estoque
    FROM PECA
    WHERE id_peca = NEW.id_peca
    FOR UPDATE;

    IF v_estoque < NEW.quantidade THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
            'Estoque insuficiente para a quantidade solicitada.';
    END IF;
END$$

CREATE TRIGGER trg_os_peca_ai
AFTER INSERT ON OS_PECA
FOR EACH ROW
BEGIN
    UPDATE PECA
    SET quantidade_estoque = quantidade_estoque - NEW.quantidade
    WHERE id_peca = NEW.id_peca;

    UPDATE ORDEM_SERVICO
    SET valor_total =
        COALESCE((
            SELECT SUM(quantidade * preco_praticado)
            FROM OS_SERVICO
            WHERE id_os = NEW.id_os
        ), 0)
        +
        COALESCE((
            SELECT SUM(quantidade * preco_praticado)
            FROM OS_PECA
            WHERE id_os = NEW.id_os
        ), 0)
    WHERE id_os = NEW.id_os;
END$$

CREATE TRIGGER trg_os_peca_bu
BEFORE UPDATE ON OS_PECA
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(20);
    DECLARE v_estoque INT;
    DECLARE v_diferenca INT;

    IF NEW.id_os <> OLD.id_os OR NEW.id_peca <> OLD.id_peca THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
            'Para trocar a peça ou OS, remova o item e inclua novamente.';
    END IF;

    SELECT status INTO v_status
    FROM ORDEM_SERVICO
    WHERE id_os = NEW.id_os;

    IF v_status IN ('Concluída', 'Cancelada') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
            'Não é permitido alterar peças de uma OS concluída ou cancelada.';
    END IF;

    SET v_diferenca = NEW.quantidade - OLD.quantidade;

    IF v_diferenca > 0 THEN
        SELECT quantidade_estoque INTO v_estoque
        FROM PECA
        WHERE id_peca = NEW.id_peca
        FOR UPDATE;

        IF v_estoque < v_diferenca THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT =
                'Estoque insuficiente para aumentar a quantidade da peça.';
        END IF;
    END IF;
END$$

CREATE TRIGGER trg_os_peca_au
AFTER UPDATE ON OS_PECA
FOR EACH ROW
BEGIN
    UPDATE PECA
    SET quantidade_estoque =
        quantidade_estoque - (NEW.quantidade - OLD.quantidade)
    WHERE id_peca = NEW.id_peca;

    UPDATE ORDEM_SERVICO
    SET valor_total =
        COALESCE((
            SELECT SUM(quantidade * preco_praticado)
            FROM OS_SERVICO
            WHERE id_os = NEW.id_os
        ), 0)
        +
        COALESCE((
            SELECT SUM(quantidade * preco_praticado)
            FROM OS_PECA
            WHERE id_os = NEW.id_os
        ), 0)
    WHERE id_os = NEW.id_os;
END$$

CREATE TRIGGER trg_os_peca_ad
AFTER DELETE ON OS_PECA
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(20);

    SELECT status INTO v_status
    FROM ORDEM_SERVICO
    WHERE id_os = OLD.id_os;

    IF v_status <> 'Cancelada' THEN
        UPDATE PECA
        SET quantidade_estoque = quantidade_estoque + OLD.quantidade
        WHERE id_peca = OLD.id_peca;
    END IF;

    UPDATE ORDEM_SERVICO
    SET valor_total =
        COALESCE((
            SELECT SUM(quantidade * preco_praticado)
            FROM OS_SERVICO
            WHERE id_os = OLD.id_os
        ), 0)
        +
        COALESCE((
            SELECT SUM(quantidade * preco_praticado)
            FROM OS_PECA
            WHERE id_os = OLD.id_os
        ), 0)
    WHERE id_os = OLD.id_os;
END$$

CREATE TRIGGER trg_os_servico_bi
BEFORE INSERT ON OS_SERVICO
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(20);

    SELECT status INTO v_status
    FROM ORDEM_SERVICO
    WHERE id_os = NEW.id_os;

    IF v_status IN ('Concluída', 'Cancelada') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
            'Não é permitido adicionar serviços a uma OS concluída ou cancelada.';
    END IF;
END$$

CREATE TRIGGER trg_os_servico_ai
AFTER INSERT ON OS_SERVICO
FOR EACH ROW
BEGIN
    UPDATE ORDEM_SERVICO
    SET valor_total =
        COALESCE((
            SELECT SUM(quantidade * preco_praticado)
            FROM OS_SERVICO
            WHERE id_os = NEW.id_os
        ), 0)
        +
        COALESCE((
            SELECT SUM(quantidade * preco_praticado)
            FROM OS_PECA
            WHERE id_os = NEW.id_os
        ), 0)
    WHERE id_os = NEW.id_os;
END$$

CREATE TRIGGER trg_os_servico_bu
BEFORE UPDATE ON OS_SERVICO
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(20);

    IF NEW.id_os <> OLD.id_os OR NEW.id_servico <> OLD.id_servico THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
            'Para trocar o serviço ou OS, remova o item e inclua novamente.';
    END IF;

    SELECT status INTO v_status
    FROM ORDEM_SERVICO
    WHERE id_os = NEW.id_os;

    IF v_status IN ('Concluída', 'Cancelada') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
            'Não é permitido alterar serviços de uma OS concluída ou cancelada.';
    END IF;
END$$

CREATE TRIGGER trg_os_servico_au
AFTER UPDATE ON OS_SERVICO
FOR EACH ROW
BEGIN
    UPDATE ORDEM_SERVICO
    SET valor_total =
        COALESCE((
            SELECT SUM(quantidade * preco_praticado)
            FROM OS_SERVICO
            WHERE id_os = NEW.id_os
        ), 0)
        +
        COALESCE((
            SELECT SUM(quantidade * preco_praticado)
            FROM OS_PECA
            WHERE id_os = NEW.id_os
        ), 0)
    WHERE id_os = NEW.id_os;
END$$

CREATE TRIGGER trg_os_servico_ad
AFTER DELETE ON OS_SERVICO
FOR EACH ROW
BEGIN
    UPDATE ORDEM_SERVICO
    SET valor_total =
        COALESCE((
            SELECT SUM(quantidade * preco_praticado)
            FROM OS_SERVICO
            WHERE id_os = OLD.id_os
        ), 0)
        +
        COALESCE((
            SELECT SUM(quantidade * preco_praticado)
            FROM OS_PECA
            WHERE id_os = OLD.id_os
        ), 0)
    WHERE id_os = OLD.id_os;
END$$

CREATE TRIGGER trg_os_bu
BEFORE UPDATE ON ORDEM_SERVICO
FOR EACH ROW
BEGIN
    DECLARE v_itens INT DEFAULT 0;
    DECLARE v_pago DECIMAL(10,2) DEFAULT 0.00;

    IF NEW.status = 'Concluída' AND OLD.status <> 'Concluída' THEN

        SELECT
            (SELECT COUNT(*)
             FROM OS_SERVICO
             WHERE id_os = OLD.id_os)
            +
            (SELECT COUNT(*)
             FROM OS_PECA
             WHERE id_os = OLD.id_os)
        INTO v_itens;

        IF v_itens = 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT =
                'Não é possível concluir uma OS sem serviços ou peças.';
        END IF;

        SELECT COALESCE(SUM(valor_pago), 0)
        INTO v_pago
        FROM PAGAMENTO
        WHERE id_os = OLD.id_os;

        IF v_pago < NEW.valor_total THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT =
                'Não é possível concluir a OS: pagamento insuficiente.';
        END IF;

        IF NEW.data_conclusao IS NULL THEN
            SET NEW.data_conclusao = CURRENT_TIMESTAMP;
        END IF;
    END IF;
END$$

DELIMITER ;

-- ------------------------------------------------------------
-- 3. MASSA DE DADOS FICTÍCIA
-- ------------------------------------------------------------

INSERT INTO CLIENTE
(nome, cpf_cnpj, telefone, email, logradouro, numero, bairro, cidade, cep)
VALUES
('Carlos Eduardo Silva', '12345678901', '(11) 98765-4321',
 'carlos@email.com', 'Rua das Flores', '100', 'Vila Ema',
 'São Paulo', '03281-000'),
('Ana Paula Souza', '98765432100', '(11) 91234-5678',
 'ana.souza@email.com', 'Rua Central', '250', 'Vila Ema',
 'São Paulo', '03282-000');

INSERT INTO VEICULO
(id_cliente, placa, marca, modelo, ano, quilometragem)
VALUES
(1, 'ABC1D23', 'Volkswagen', 'Gol 1.6', 2018, 75000),
(2, 'XYZ9K87', 'Chevrolet', 'Onix 1.0', 2020, 42000);

INSERT INTO MECANICO (nome, especialidade, telefone)
VALUES
('Roberto Santos', 'Injeção Eletrônica', '(11) 97777-1111'),
('Marcelo Oliveira', 'Suspensão e Freios', '(11) 97777-2222');

INSERT INTO PECA
(descricao, preco_unitario, quantidade_estoque, estoque_minimo)
VALUES
('Óleo 5W30 Sintético', 45.00, 3, 10),
('Filtro de Óleo', 25.00, 15, 5),
('Pastilha de Freio Dianteira', 120.00, 2, 4);

INSERT INTO SERVICO (descricao, preco_base)
VALUES
('Troca de Óleo e Filtro', 80.00),
('Alinhamento e Balanceamento', 120.00);

INSERT INTO ORDEM_SERVICO (id_veiculo, id_mecanico, status)
VALUES
(1, 1, 'Aberta'),
(2, 2, 'Aberta');

INSERT INTO OS_PECA
(id_os, id_peca, quantidade, preco_praticado)
VALUES
(1, 2, 1, 25.00);

INSERT INTO OS_SERVICO
(id_os, id_servico, quantidade, preco_praticado)
VALUES
(1, 1, 1, 80.00);

INSERT INTO PAGAMENTO (id_os, valor_pago, forma_pagamento)
VALUES
(1, 105.00, 'Pix');

UPDATE ORDEM_SERVICO
SET status = 'Concluída'
WHERE id_os = 1;

UPDATE ORDEM_SERVICO
SET status = 'Em Andamento'
WHERE id_os = 2;

-- ------------------------------------------------------------
-- 4. CONSULTAS GERENCIAIS E DE AUDITORIA
-- ------------------------------------------------------------

-- G01 — Peças abaixo do estoque mínimo
-- Atende: P1 (ruptura de estoque) e KPI 02
SELECT
    id_peca,
    descricao,
    quantidade_estoque,
    estoque_minimo
FROM PECA
WHERE quantidade_estoque < estoque_minimo;

-- G02A — Histórico das ordens de serviço por veículo
-- Atende: P2 (rastreabilidade do histórico)
SELECT
    V.placa,
    V.modelo,
    OS.id_os,
    OS.data_abertura,
    OS.data_conclusao,
    OS.status,
    OS.valor_total
FROM VEICULO V
JOIN ORDEM_SERVICO OS
    ON V.id_veiculo = OS.id_veiculo
WHERE V.placa = 'ABC1D23'
ORDER BY OS.data_abertura DESC;

-- G02B — Serviços do histórico do veículo
-- Atende: P2 (rastreabilidade do histórico)
SELECT
    V.placa,
    OS.id_os,
    S.descricao AS servico,
    OSS.quantidade,
    OSS.preco_praticado,
    (OSS.quantidade * OSS.preco_praticado) AS subtotal
FROM VEICULO V
JOIN ORDEM_SERVICO OS
    ON V.id_veiculo = OS.id_veiculo
JOIN OS_SERVICO OSS
    ON OS.id_os = OSS.id_os
JOIN SERVICO S
    ON OSS.id_servico = S.id_servico
WHERE V.placa = 'ABC1D23'
ORDER BY OS.data_abertura DESC, S.descricao;

-- G02C — Peças do histórico do veículo
-- Atende: P2 (rastreabilidade do histórico)
SELECT
    V.placa,
    OS.id_os,
    P.descricao AS peca,
    OSP.quantidade,
    OSP.preco_praticado,
    (OSP.quantidade * OSP.preco_praticado) AS subtotal
FROM VEICULO V
JOIN ORDEM_SERVICO OS
    ON V.id_veiculo = OS.id_veiculo
JOIN OS_PECA OSP
    ON OS.id_os = OSP.id_os
JOIN PECA P
    ON OSP.id_peca = P.id_peca
WHERE V.placa = 'ABC1D23'
ORDER BY OS.data_abertura DESC, P.descricao;

-- G03 — Faturamento por mecânico, apenas OS concluídas
-- Atende: P3 e KPI 03 (faturamento por mecânico)
SELECT
    M.nome AS mecanico,
    COUNT(OS.id_os) AS total_os_concluidas,
    COALESCE(SUM(OS.valor_total), 0.00) AS faturamento_os_concluidas
FROM MECANICO M
LEFT JOIN ORDEM_SERVICO OS
    ON M.id_mecanico = OS.id_mecanico
    AND OS.status = 'Concluída'
GROUP BY M.id_mecanico, M.nome
ORDER BY faturamento_os_concluidas DESC;

-- G03B — Total recebido por mecânico, nas OS concluídas
-- Atende: P3 e KPI 03 (produtividade financeira por técnico)
SELECT
    M.nome AS mecanico,
    COALESCE(SUM(PG.valor_pago), 0.00) AS total_recebido
FROM MECANICO M
LEFT JOIN ORDEM_SERVICO OS
    ON M.id_mecanico = OS.id_mecanico
    AND OS.status = 'Concluída'
LEFT JOIN PAGAMENTO PG
    ON PG.id_os = OS.id_os
GROUP BY M.id_mecanico, M.nome
ORDER BY total_recebido DESC;

-- G04 — Ticket médio das OS concluídas
-- Atende: KPI 01 (ticket médio por OS)
SELECT
    COALESCE(AVG(valor_total), 0.00) AS ticket_medio_os
FROM ORDEM_SERVICO
WHERE status = 'Concluída';

-- A01 — OS concluídas sem serviços ou peças
-- Verifica: RN04 (OS concluída exige ao menos um serviço ou peça)
SELECT
    OS.id_os,
    OS.status
FROM ORDEM_SERVICO OS
WHERE OS.status = 'Concluída'
AND NOT EXISTS (
    SELECT 1
    FROM OS_SERVICO OSS
    WHERE OSS.id_os = OS.id_os
)
AND NOT EXISTS (
    SELECT 1
    FROM OS_PECA OSP
    WHERE OSP.id_os = OS.id_os
);

-- A02 — Divergência entre total registrado e soma dos itens
-- Verifica: RN07 (valor total é a soma de serviços e peças)
SELECT
    OS.id_os,
    OS.valor_total,
    COALESCE((
        SELECT SUM(quantidade * preco_praticado)
        FROM OS_SERVICO
        WHERE id_os = OS.id_os
    ), 0)
    +
    COALESCE((
        SELECT SUM(quantidade * preco_praticado)
        FROM OS_PECA
        WHERE id_os = OS.id_os
    ), 0) AS total_calculado
FROM ORDEM_SERVICO OS
WHERE OS.valor_total <>
    COALESCE((
        SELECT SUM(quantidade * preco_praticado)
        FROM OS_SERVICO
        WHERE id_os = OS.id_os
    ), 0)
    +
    COALESCE((
        SELECT SUM(quantidade * preco_praticado)
        FROM OS_PECA
        WHERE id_os = OS.id_os
    ), 0);

-- A03 — Pagamentos inferiores ao total da OS
-- Verifica: Regra de pagamento suficiente para conclusão da OS
SELECT
    OS.id_os,
    OS.status,
    OS.valor_total,
    COALESCE((
        SELECT SUM(valor_pago)
        FROM PAGAMENTO
        WHERE id_os = OS.id_os
    ), 0) AS total_pago
FROM ORDEM_SERVICO OS
WHERE COALESCE((
    SELECT SUM(valor_pago)
    FROM PAGAMENTO
    WHERE id_os = OS.id_os
), 0) < OS.valor_total;