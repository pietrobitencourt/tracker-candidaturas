-- =============================================================
-- Tracker de Candidaturas de Estágio
-- Script de criação do banco de dados (MySQL 8.0)
-- Author: Piêtro Bitencourt Nunes
-- Created: 18 Oct 2026
-- =============================================================

CREATE DATABASE IF NOT EXISTS tracker_candidaturas
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE tracker_candidaturas;

-- Empresa: organização que oferece as vagas
CREATE TABLE IF NOT EXISTS empresa (
  id_empresa INT NOT NULL AUTO_INCREMENT,
  nome VARCHAR(100) NOT NULL,
  site VARCHAR(255),

  PRIMARY KEY (id_empresa),
  CONSTRAINT uq_empresa_nome UNIQUE (nome)
);

-- Plataforma: onde a vaga foi encontrada (LinkedIn, CIEE, indicação...)
CREATE TABLE IF NOT EXISTS plataforma (
  id_plataforma INT NOT NULL AUTO_INCREMENT,
  nome VARCHAR(100) NOT NULL,
  site VARCHAR(255),
  tem_conta BOOLEAN NOT NULL DEFAULT FALSE,

  PRIMARY KEY (id_plataforma),
  CONSTRAINT uq_plataforma_nome UNIQUE (nome)
);

-- Vaga: pertence a uma empresa e foi encontrada em uma plataforma
CREATE TABLE IF NOT EXISTS vaga (
  id_vaga INT NOT NULL AUTO_INCREMENT,
  cargo VARCHAR(150) NOT NULL,
  link VARCHAR(500),
  modalidade ENUM('remoto', 'presencial', 'hibrido') NOT NULL,
  jornada ENUM('integral', 'meio_periodo') NOT NULL,
  bolsa DECIMAL(10,2),
  id_empresa INT NOT NULL,
  id_plataforma INT NOT NULL,

  PRIMARY KEY (id_vaga),
  CONSTRAINT uq_vaga_link UNIQUE (link),
  CONSTRAINT fk_vaga_empresa FOREIGN KEY (id_empresa)
    REFERENCES empresa (id_empresa) ON DELETE RESTRICT,
  CONSTRAINT fk_vaga_plataforma FOREIGN KEY (id_plataforma)
    REFERENCES plataforma (id_plataforma) ON DELETE RESTRICT
);

-- Candidatura: no máximo uma por vaga
CREATE TABLE IF NOT EXISTS candidatura (
  id_candidatura INT NOT NULL AUTO_INCREMENT,
  data_inscricao DATE NOT NULL,
  desfecho ENUM(
    'em_andamento', 'aprovado', 'reprovado', 'desisti',
    'sem_resposta', 'classificado', 'lista_espera', 'banco_talentos'
  ) NOT NULL DEFAULT 'em_andamento',
  curriculo_enviado VARCHAR(100) NOT NULL,
  anotacoes TEXT,
  id_vaga INT NOT NULL,

  PRIMARY KEY (id_candidatura),
  CONSTRAINT uq_candidatura_id_vaga UNIQUE (id_vaga),
  CONSTRAINT fk_candidatura_vaga FOREIGN KEY (id_vaga)
    REFERENCES vaga (id_vaga) ON DELETE RESTRICT
);

-- Etapa: passos de uma candidatura (inscrição, prova, entrevista...)
CREATE TABLE IF NOT EXISTS etapa (
  id_etapa INT NOT NULL AUTO_INCREMENT,
  tipo VARCHAR(50) NOT NULL,
  data DATETIME NOT NULL,
  data_limite DATETIME,
  situacao ENUM('pendente', 'concluida', 'cancelada') NOT NULL DEFAULT 'pendente',
  resultado ENUM('aprovado', 'reprovado'),
  id_candidatura INT NOT NULL,

  PRIMARY KEY (id_etapa),
  CONSTRAINT fk_etapa_candidatura FOREIGN KEY (id_candidatura)
    REFERENCES candidatura (id_candidatura) ON DELETE CASCADE
);

-- Contato: recrutadores de uma candidatura (guardar só o necessário)
CREATE TABLE IF NOT EXISTS contato (
  id_contato INT NOT NULL AUTO_INCREMENT,
  nome VARCHAR(100) NOT NULL,
  meio_contato VARCHAR(255) NOT NULL,
  id_candidatura INT NOT NULL,

  PRIMARY KEY (id_contato),
  CONSTRAINT fk_contato_candidatura FOREIGN KEY (id_candidatura)
    REFERENCES candidatura (id_candidatura) ON DELETE CASCADE
);