-- =============================================================
-- Tracker de Candidaturas de Estágio
-- Testes das regras do banco (dados fictícios, tudo desfeito no final)
-- Como usar: execute UM comando por vez (Ctrl+Enter) e compare o
-- resultado com a linha "Esperado". O teste 1 é um bloco: selecione
-- todas as linhas dele e use Ctrl+Shift+Enter.
-- Todos os comandos devem rodar na MESMA aba (mesma sessão).
-- =============================================================

USE tracker_candidaturas;
START TRANSACTION;

-- TESTE 1: inserir dados válidos nas seis tabelas
-- (também prova que site, bolsa, data_limite e resultado são opcionais,
--  e prepara os valores padrão para o teste 2)
-- Esperado: sucesso em todos os comandos
INSERT INTO empresa (nome) VALUES ('Empresa Teste');
SET @empresa = LAST_INSERT_ID();

INSERT INTO plataforma (nome) VALUES ('Plataforma Teste');
SET @plataforma = LAST_INSERT_ID();

INSERT INTO vaga (cargo, link, modalidade, jornada, bolsa, id_empresa, id_plataforma)
VALUES ('Estagiário de Dados', 'https://exemplo.test/vaga/1', 'remoto', 'meio_periodo', 1500.00, @empresa, @plataforma);
SET @vaga = LAST_INSERT_ID();

INSERT INTO candidatura (data_inscricao, curriculo_enviado, id_vaga)
VALUES ('2026-10-18', 'curriculo_teste_v1', @vaga);
SET @candidatura = LAST_INSERT_ID();

INSERT INTO etapa (tipo, data, id_candidatura)
VALUES ('inscricao', '2026-10-18 10:00:00', @candidatura);

INSERT INTO contato (nome, meio_contato, id_candidatura)
VALUES ('Recrutador Teste', 'recrutador@exemplo.test', @candidatura);

-- TESTE 2: valores padrão (os inserts do teste 1 não informaram esses campos)
-- Esperado: tem_conta = 0, desfecho = em_andamento, situacao = pendente
SELECT tem_conta FROM plataforma WHERE id_plataforma = @plataforma;
SELECT desfecho FROM candidatura WHERE id_candidatura = @candidatura;
SELECT situacao FROM etapa WHERE id_candidatura = @candidatura;

-- TESTE 3: segunda candidatura na mesma vaga
-- Esperado: ERRO 1062 (valor duplicado, chave uq_candidatura_id_vaga)
INSERT INTO candidatura (data_inscricao, curriculo_enviado, id_vaga)
VALUES ('2026-10-19', 'curriculo_teste_v2', @vaga);

-- TESTE 4: valor fora da lista do ENUM
-- Esperado: ERRO 1265 (dado truncado na coluna desfecho)
UPDATE candidatura SET desfecho = 'talvez' WHERE id_candidatura = @candidatura;

-- TESTE 5: vaga com empresa inexistente
-- Esperado: ERRO 1452 (falha de chave estrangeira, fk_vaga_empresa)
INSERT INTO vaga (cargo, modalidade, jornada, id_empresa, id_plataforma)
VALUES ('Vaga Inválida', 'remoto', 'integral', 999999, @plataforma);

-- TESTE 6: duas vagas sem link
-- Esperado: sucesso nas duas (NULL não conta como repetido)
INSERT INTO vaga (cargo, modalidade, jornada, id_empresa, id_plataforma)
VALUES ('Vaga sem link 1', 'presencial', 'integral', @empresa, @plataforma);

INSERT INTO vaga (cargo, modalidade, jornada, id_empresa, id_plataforma)
VALUES ('Vaga sem link 2', 'hibrido', 'meio_periodo', @empresa, @plataforma);

-- TESTE 7: duas vagas com o mesmo link
-- Esperado: ERRO 1062 (valor duplicado, chave uq_vaga_link)
INSERT INTO vaga (cargo, link, modalidade, jornada, id_empresa, id_plataforma)
VALUES ('Vaga link repetido', 'https://exemplo.test/vaga/1', 'remoto', 'integral', @empresa, @plataforma);

-- TESTE 8: empresa com nome igual, mudando só maiúsculas e acento
-- Esperado: ERRO 1062 (a collation utf8mb4_0900_ai_ci ignora a diferença)
INSERT INTO empresa (nome) VALUES ('EMPRESA TÉSTE');

-- TESTE 9: vaga sem cargo (coluna obrigatória)
-- Esperado: ERRO 1048 (coluna cargo não pode ser nula)
INSERT INTO vaga (cargo, modalidade, jornada, id_empresa, id_plataforma)
VALUES (NULL, 'remoto', 'integral', @empresa, @plataforma);

-- TESTE 10: apagar uma empresa que tem vagas
-- Esperado: ERRO 1451 (bloqueado por ON DELETE RESTRICT, fk_vaga_empresa)
DELETE FROM empresa WHERE id_empresa = @empresa;

-- TESTE 11: apagar uma vaga que tem candidatura
-- Esperado: ERRO 1451 (bloqueado por ON DELETE RESTRICT, fk_candidatura_vaga)
DELETE FROM vaga WHERE id_vaga = @vaga;

-- TESTE 12: apagar uma candidatura que tem etapa e contato (por último,
-- porque este teste apaga a candidatura usada nos testes anteriores)
-- Esperado: antes = 1 etapa e 1 contato; o DELETE funciona; depois = 0 e 0
SELECT
  (SELECT COUNT(*) FROM etapa WHERE id_candidatura = @candidatura) AS etapas,
  (SELECT COUNT(*) FROM contato WHERE id_candidatura = @candidatura) AS contatos;

DELETE FROM candidatura WHERE id_candidatura = @candidatura;

SELECT
  (SELECT COUNT(*) FROM etapa WHERE id_candidatura = @candidatura) AS etapas,
  (SELECT COUNT(*) FROM contato WHERE id_candidatura = @candidatura) AS contatos;

-- Desfaz TUDO o que foi inserido nos testes
ROLLBACK;

-- TESTE 13: conferir que nada ficou no banco
-- Esperado: 0 em todas as contagens
SELECT
  (SELECT COUNT(*) FROM empresa) AS empresas,
  (SELECT COUNT(*) FROM vaga) AS vagas,
  (SELECT COUNT(*) FROM candidatura) AS candidaturas;