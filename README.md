# atividade-entrega-2.
# Entrega 2 — Modelo Lógico, Implementação SQL e Apresentação Final

### Modelagem de um sistema de gestão de informações para uma oficina mecânica (Scopino Auto Club)

---

## 1. Relatório Técnico Final

### Integrantes

| Nome completo do aluno | RGM | Usuário do GitHub |
| :---- | :---- | :---- |
| Ryan Nunes | [47391171] | [usuario_ryan] |
| Matheus Bosnic | [47646454] | [usuario_matheus] |
Rafael Tavares oliveira | 48224499
&nbsp;

### 1.1 Revisão do Modelo Conceitual

#### Caracterização da Organização

- **Nome e natureza da organização:** Scopino Auto Club, empresa do setor automotivo (CNPJ/CNAE 45.20-0-01) voltada à manutenção preventiva e corretiva de veículos automotores[cite: 1].
- **Contexto e porte:** Empresa de pequeno a médio porte, com atendimento médio de cerca de **35 a 50 veículos por semana** (aproximadamente 150 a 200 ordens de serviço por mês). Conta com uma equipa fixa de **6 mecânicos/atendentes**, além do proprietário/gestor. O catálogo possui mais de **800 itens e peças em stock** e um histórico cadastral com mais de **1.200 clientes**[cite: 1].
- **Problemas e necessidades identificados:**
  - **P1 — Ruptura e falta de controlo de stock de peças:** Peças essenciais faltam durante a execução dos serviços por falta de controlo centralizado entre a Ordem de Serviço (OS) e a baixa em stock[cite: 1].
  - **P2 — Histórico descentralizado e perda de garantia/rastreabilidade:** Dificuldade em consultar rapidamente o histórico de manutenções de um veículo específico e peças trocadas anteriormente[cite: 1].
  - **P3 — Falta de visibilidade do volume de faturação real por serviço/mecânico:** Inexistência de relatórios detalhados que mostrem quais os serviços que geram maior margem e o desempenho individual da equipa técnica[cite: 1].
- **Escopo do sistema:** O sistema abrange todo o ciclo operacional e financeiro da oficina: cadastro de clientes, veículos, equipa técnica, catálogo de serviços, controlo de peças/stock, emissão e estado de Ordens de Serviço (OS), itens executados, formas de pagamento e acompanhamento de faturação[cite: 1].
- **Justificativa da escolha:** A organização possui processos operacionais bem definidos e dinâmicos, que exigem uma forte integração entre atendimento, execução técnica e stock, constituindo um excelente cenário para a modelagem relacional completa[cite: 1].
- **Evidências da organização:** 
  - **Endereço:** R Herwis, 160 / R Santa Eudóxia, 508 - Vila Ema / Casa Verde - São Paulo/SP[cite: 1].
  - **Google Business Profile:** [Scopino Auto Club no Google Maps](https://maps.google.com)[cite: 1]
  - **Fotografias do local/visita:** Disponíveis na pasta `docs/imagens/` (`foto_oficina1.jpg`, `foto_oficina2.jpg`, `foto_entrevista.jpg`)[cite: 1].
- **Responsável pela organização:** Alberto Scopino (Proprietário/Gestor) — Telefone: (11) 99999-9999[cite: 1].

---

#### Relato da Entrevista

- **Quem:** Alberto Scopino (Proprietário/Gestor). Entrevistadores: Ryan Nunes e Matheus Bosnic[cite: 1].
- **Quando e onde:** Realizada presencialmente no ambiente da oficina (Rua Herwis, 160)[cite: 1].
- **Observação presencial:** Durante a visita, observou-se que o agendamento e o diagnóstico inicial ainda utilizavam anotações físicas em blocos de papel. As peças eram retiradas do armazém sem registo imediato na OS, gerando divergências no inventário no final do mês[cite: 1].
- **Comprovação:** Fotografia da entrevista guardada em `docs/imagens/foto_entrevista.jpg`[cite: 1].
- **O que foi levantado:** O relatório detalhado da entrevista e o mapeamento de campo encontram-se disponíveis em [`levantamento/levantamento.md`](levantamento/levantamento.md)[cite: 1].

---

#### Processos de Negócio

- **Processo 1 — Cadastro de Cliente e Veículo:** Registo dos dados do proprietário e vinculação de um ou mais veículos à sua conta[cite: 1].
- **Processo 2 — Abertura de Ordem de Serviço e Diagnóstico:** Entrada do veículo, registo das queixas e elaboração do diagnóstico pelo mecânico responsável[cite: 1].
- **Processo 3 — Orçamento e Aprovação:** Definição das peças necessárias e serviços; envio do valor total para aprovação do cliente[cite: 1].
- **Processo 4 — Execução e Baixa de Stock:** Realização dos serviços pelo mecânico associado e dedução automática das peças do stock[cite: 1].
- **Processo 5 — Encerramento e Pagamento:** Cálculo do valor total, registo da forma de pagamento (Pix, Cartão, Dinheiro) e finalização da OS[cite: 1].

---

#### Requisitos do Sistema

##### Requisitos Funcionais
- **RF01:** Registar cliente com nome completo, CPF/CNPJ, telefone, e-mail e morada[cite: 1].
- **RF02:** Cadastrar veículo vinculado a um cliente com matrícula (placa), marca, modelo, ano e quilometragem[cite: 1].
- **RF03:** Abrir Ordem de Serviço (OS) vinculada a um veículo, mecânico e data de abertura[cite: 1].
- **RF04:** Associar serviços e peças executadas a uma OS com quantidade e preço praticado[cite: 1].
- **RF05:** Atualizar e controlar o saldo de stock de peças após a inclusão na OS[cite: 1].
- **RF06:** Registar o pagamento de uma OS indicando o valor, a data e a forma de pagamento[cite: 1].
- **RF07:** Consultar o histórico completo de manutenções de um veículo por matrícula[cite: 1].

##### Requisitos Não Funcionais
- **RNF01 (Integridade):** Não permitir a criação de uma OS sem veículo e cliente válidos[cite: 1].
- **RNF02 (Desempenho):** As consultas ao histórico do veículo devem responder em menos de 2 segundos[cite: 1].
- **RNF03 (Segurança):** O acesso aos dados e alterações de stock deve exigir autenticação de utilizador[cite: 1].

---

#### Regras de Negócio

- **RN01:** Um cliente pode possuir um ou mais veículos cadastrados[cite: 1].
- **RN02:** Cada veículo pertence a exatamente um cliente no cadastro[cite: 1].
- **RN03:** Uma OS deve obrigatoriamente estar vinculada a um único veículo[cite: 1].
- **RN04:** Uma OS só pode ser encerrada se houver pelo menos um serviço ou peça associada[cite: 1].
- **RN05:** A baixa de stock de uma peça ocorre apenas após a aprovação/inclusão na OS[cite: 1].
- **RN06:** Uma peça não pode ser adicionada a uma OS se a quantidade requisitada for superior ao saldo em stock[cite: 1].
- **RN07:** O valor total da OS corresponde ao somatório do (preço $\times$ quantidade) de todos os serviços e peças vinculados[cite: 1].

---

#### Revisão do DER Conceitual (Caso A)

Software utilizado: **brModelo**  
Ficheiro de imagem do DER: [`docs/diagramas/DER_conceitual_revisado.png`](docs/diagramas/DER_conceitual_revisado.png)[cite: 1]

| Apontamento da correção da E1 | O que mudou no trabalho | Por quê |
| :---- | :---- | :---- |
| Relacionamento N:N entre OS e PEÇA sem quantidade | Criada entidade associativa `OS_PECA` com atributos `quantidade` e `preco_praticado`. | Permitir saber a quantidade exata de peças utilizadas em cada OS e registar o preço da peça no momento da execução.[cite: 1] |
| Atributos de FK desenhados no DER | Removidas todas as FKs explícitas do modelo conceitual. | As chaves estrangeiras são um detalhe de implementação do Modelo Lógico.[cite: 1] |

---

### 1.2 Conversão do Modelo Conceitual para o Modelo Lógico

1. **Entidades para Tabelas:**
   - `CLIENTE` $\rightarrow$ Tabela `CLIENTE`
   - `VEICULO` $\rightarrow$ Tabela `VEICULO`
   - `MECANICO` $\rightarrow$ Tabela `MECANICO`
   - `ORDEM_SERVICO` $\rightarrow$ Tabela `ORDEM_SERVICO`
   - `SERVICO` $\rightarrow$ Tabela `SERVICO`
   - `PECA` $\rightarrow$ Tabela `PECA`[cite: 1]
2. **Relacionamentos e Chaves:**
   - **CLIENTE - VEICULO (1:N):** Adicionada `id_cliente` em `VEICULO` como FK[cite: 1].
   - **VEICULO - ORDEM_SERVICO (1:N):** Adicionada `id_veiculo` em `ORDEM_SERVICO` como FK[cite: 1].
   - **MECANICO - ORDEM_SERVICO (1:N):** Adicionada `id_mecanico` em `ORDEM_SERVICO` como FK[cite: 1].
   - **ORDEM_SERVICO - SERVICO (N:N):** Mapeado na tabela associativa `OS_SERVICO` (`id_os`, `id_servico`)[cite: 1].
   - **ORDEM_SERVICO - PECA (N:N):** Mapeado na tabela associativa `OS_PECA` (`id_os`, `id_peca`)[cite: 1].

---

### 1.3 Definição de Chaves Primárias e Estrangeiras

- `CLIENTE`: PK (`id_cliente`)[cite: 1]
- `VEICULO`: PK (`id_veiculo`), FK (`id_cliente` $\rightarrow$ `CLIENTE.id_cliente`)[cite: 1]
- `MECANICO`: PK (`id_mecanico`)[cite: 1]
- `ORDEM_SERVICO`: PK (`id_os`), FK (`id_veiculo` $\rightarrow$ `VEICULO.id_veiculo`), FK (`id_mecanico` $\rightarrow$ `MECANICO.id_mecanico`)[cite: 1]
- `SERVICO`: PK (`id_servico`)[cite: 1]
- `PECA`: PK (`id_peca`)[cite: 1]
- `OS_SERVICO`: PK composta (`id_os`, `id_servico`), FK (`id_os`), FK (`id_servico`)[cite: 1]
- `OS_PECA`: PK composta (`id_os`, `id_peca`), FK (`id_os`), FK (`id_peca`)[cite: 1]
- `PAGAMENTO`: PK (`id_pagamento`), FK (`id_os` $\rightarrow$ `ORDEM_SERVICO.id_os`)[cite: 1]

---

### 1.4 Processo de Normalização (1FN, 2FN e 3FN)

- **1FN (Primeira Forma Normal):** Garantido que todos os atributos são atómicos. Telefones múltiplos ou multivalorados foram tratados ou estruturados. Atributos compostos (como a morada) foram decompostos em `logradouro`, `numero`, `bairro`, `cep`, `cidade`[cite: 1].
- **2FN (Segunda Forma Normal):** Eliminadas as dependências parciais. Em tabelas de ligação (`OS_PECA`), atributos como `quantidade` e `preco_praticado` dependem inteiramente da chave primária composta (`id_os` + `id_peca`)[cite: 1].
- **3FN (Terceira Forma Normal):** Eliminadas as dependências transitivas. O preço atual da peça fica registado em `PECA`, mas o valor cobrado na OS é mantido em `OS_PECA` para garantir a imutabilidade do histórico financeiro[cite: 1].

---

### 1.5 Justificativas Técnicas das Decisões

- **Preço Praticado em OS_PECA e OS_SERVICO:** Garante estabilidade histórica. Se o valor do serviço ou da peça mudar no catálogo geral no futuro, o histórico das Ordens de Serviço antigas permanece intacto[cite: 1].
- **Uso de Chaves Primárias Auto-Incrementais (IDs):** Facilita a manutenção, garante melhor desempenho em JOINs e previne gargalos ao alterar dados cadastrais (ex.: alteração de CPF ou matrícula)[cite: 1].
- **Restrições UNIQUE em Matrícula e CPF/CNPJ:** Atendem às regras **RN02** e de validação legal para evitar a duplicidade de cadastros[cite: 1].

---

### 1.6 Proposta de Arquitetura Analítica para BI e IA

- **Informações Estratégicas:** Identificação dos serviços mais lucrativos, tempo médio de permanência dos veículos na oficina, previsão de procura de peças sazonais[cite: 1].
- **KPIs Propostos:**
  - **KPI 01 — Ticket Médio por Ordem de Serviço:** Valor médio gasto pelos clientes por visita[cite: 1].
  - **KPI 02 — Taxa de Peças com Stock Crítico:** Percentagem de peças do catálogo com quantidade atual abaixo do stock mínimo[cite: 1].
  - **KPI 03 — Faturação por Mecânico:** Produtividade e receita gerada por cada profissional técnico[cite: 1].

#### Tabela de Rastreabilidade

| Problema ou KPI | Tabelas envolvidas | Consulta no script SQL |
| :---- | :---- | :---- |
| **P1 — Ruptura de stock de peças** | `PECA` | `G01`[cite: 1] |
| **P2 — Histórico descentralizado do veículo** | `VEICULO`, `ORDEM_SERVICO`, `OS_SERVICO`, `OS_PECA` | `G02`[cite: 1] |
| **P3 — Faturação por mecânico** | `MECANICO`, `ORDEM_SERVICO` | `G03`[cite: 1] |
| **KPI 01 — Ticket médio das OS** | `ORDEM_SERVICO` | `G04`[cite: 1] |
| **KPI 02 — Peças em stock crítico** | `PECA` | `G01`[cite: 1] |

---

## 2. Modelo Lógico Relacional

O Diagrama do Modelo Lógico Relacional foi desenvolvido no software **brModelo** e encontra-se disponível no repositório no caminho:
[`docs/diagramas/modelo_logico.png`](docs/diagramas/modelo_logico.png)[cite: 1]

---

## 3. Script SQL Completo

O script completo de criação das tabelas, inserção da massa de dados, restrições e consultas está localizado em:
[`docs/script.sql`](docs/script.sql)[cite: 1]

---

## 4. Massa de Dados

A massa de dados foi construída mantendo **absolutamente a privacidade** de pessoas reais, utilizando dados fictícios totalmente coerentes com o volume semanal de uma oficina de médio porte[cite: 1].

- **Ficheiro:** [`docs/massa_de_dados.sql`](docs/massa_de_dados.sql) (também incluído no script principal)[cite: 1].
- **Volume:** Contém 20 clientes, 25 veículos, 5 mecânicos, 30 peças, 15 serviços cadastrados, 40 ordens de serviço e respetivos itens e pagamentos[cite: 1].

---

## 5. Repositório GitHub

Estrutura de pastas do repositório:

```text
├── README.md
├── docs/
│   ├── script.sql
│   ├── massa_de_dados.sql
│   ├── dicionario_de_dados.html
│   ├── diagramas/
│   │   ├── DER_conceitual_revisado.png
│   │   └── modelo_logico.png
│   └── imagens/
│       ├── foto_oficina1.jpg
│       ├── foto_oficina2.jpg
│       └── foto_entrevista.jpg
└── levantamento/
    └── levantamento.md
```[cite: 1]

---

## 6. Uso de Inteligência Artificial

| Item | O que registar |
| :---- | :---- |
| **Ferramenta e etapa** | ChatGPT / Gemini na geração da massa de dados fictícia e apoio no modelo de script de consultas SQL[cite: 1]. |
| **Motivação** | Agilizar o preenchimento de nomes fictícios, matrículas válidas e cálculo de agregações complexas em SQL[cite: 1]. |
| **Prompt(s) utilizados** | *"Gere 30 comandos INSERT em SQL para a tabela PECA com nomes reais de autopeças, preços coerentes entre R$ 20 e R$ 800 e quantidades em stock."*[cite: 1] |
| **Resposta recebida** | Script SQL populado com registos plausíveis[cite: 1]. |
| **Fontes consultadas** | Documentação Oficial do MySQL 8.0[cite: 1]. |
| **Trechos corrigidos** | Ajustados os nomes das colunas e FKs que a IA tinha sugerido fora do padrão definido no Modelo Lógico[cite: 1]. |
| **Reflexão crítica** | A IA acelera tarefas repetitivas, mas exige uma revisão rigorosa da sintaxe e dos relacionamentos de chave estrangeira[cite: 1]. |

---

## 7. Apresentação Corporativa Final

Os diapositivos da apresentação do Pitch Corporativo (8 minutos) estão disponíveis na pasta de documentação do grupo:
[`docs/apresentacao_oficina_scopino.pdf`](docs/apresentacao_oficina_scopino.pdf)[cite: 1]
