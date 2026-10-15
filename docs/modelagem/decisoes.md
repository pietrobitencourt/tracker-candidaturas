# Modelagem de dados: Tracker de Candidaturas

## Etapa 2: Modelo conceitual (MER/DER)

![Modelo conceitual](modelo-conceitual.png)

### Entidades

Empresa, Plataforma, Vaga, Candidatura, Etapa e Contato.

Removidas na revisão: **Processo** (é o mesmo que Candidatura) e **Eventos** (é o mesmo que Etapa).

### Atributos

O identificador de cada entidade é o `id_...`.

| Entidade | Atributos |
|---|---|
| Empresa | `id_empresa`, `nome`, `site` (opcional) |
| Plataforma | `id_plataforma`, `nome`, `site` (opcional), `tem_conta` (V2: `usuario_ou_email`) |
| Vaga | `id_vaga`, `cargo`, `link` (opcional), `modalidade`, `jornada`, `bolsa` (opcional) |
| Candidatura | `id_candidatura`, `data_inscricao`, `desfecho`, `curriculo_enviado`, `anotacoes` (opcional) |
| Etapa | `id_etapa`, `tipo`, `data`, `data_limite` (opcional), `situacao`, `resultado` (opcional) |
| Contato | `id_contato`, `nome`, `meio_contato` (e-mail ou telefone) |

### Domínios

| Atributo | Valores permitidos |
|---|---|
| `desfecho` | em andamento (valor inicial), aprovado, reprovado, desisti, sem resposta, classificado, lista de espera, banco de talentos |
| `situacao` | pendente, concluída, cancelada |
| `resultado` | aprovado, reprovado (vazio até sair a resposta) |

### Etapa atual (atributo derivado, não guardado)

- É a etapa pendente de menor data; se não houver pendente, a última concluída.
- Etapa atrasada = pendente com data limite já passada (também deduzida).

### Relacionamentos

Convenção: **leitura cruzada (look across)**. O número ao lado de uma entidade diz quantas dela se ligam a uma ocorrência da outra.

| Entidade | Relacionamento | Entidade | Leitura |
|---|---|---|---|
| Empresa (1,1) | oferece | Vaga (0,N) | uma empresa tem várias vagas; cada vaga é de uma empresa |
| Plataforma (1,1) | divulga | Vaga (0,N) | uma plataforma divulga várias vagas; cada vaga foi achada em uma plataforma |
| Vaga (1,1) | recebe | Candidatura (0,1) | uma vaga tem no máximo uma candidatura; cada candidatura é de uma vaga |
| Candidatura (1,1) | passa por | Etapa (1,N) | uma candidatura tem várias etapas; cada etapa é de uma candidatura |
| Candidatura (1,1) | tem | Contato (0,N) | uma candidatura tem zero ou mais contatos; cada contato é de uma candidatura |

### Decisões e justificativas

- **Etapa é entidade:** várias por candidatura, cada uma com dados próprios.
- **Etapa atual é derivada:** guardar um marcador permitiria duas etapas "atuais" por erro.
- **Desfecho é atributo da Candidatura:** um único valor por processo.
- **Currículo é atributo simples:** um valor por candidatura, sem dados próprios.
- **Contato é entidade:** uma candidatura pode ter mais de um recrutador.
- **Empresa é entidade:** várias vagas por empresa, evita nomes duplicados e permite filtrar.
- **Vaga é separada de Candidatura:** vagas salvas sem inscrição (V2) e inscrição única por vaga.
- **Plataforma liga na Vaga:** é onde a vaga foi encontrada; "onde me inscrevi" vem pela Vaga.
- **`tem_conta` na Plataforma basta:** um usuário e uma conta por plataforma, sem entidade Conta.
- **Vaga sem plataforma** (indicação, site da empresa): cadastrar "Indicação" e "Site da empresa" como plataformas, mantendo o (1,1).

---

## Etapa 3: Modelo lógico

![Modelo lógico](modelo-logico.png)

O diagrama foi feito no BRModelo. As chaves primárias aparecem com a chave preta, as chaves estrangeiras com a chave verde (e as setas entre as tabelas) e os valores únicos com o **U** azul. As restrições de chave estrangeira (`FOREIGN KEY`) são criadas no script SQL (`database/schema.sql`).

### Notação do esquema textual

| Símbolo | Significado |
|---|---|
| <ins>x</ins> | chave primária (PK) |
| `#x` | chave estrangeira (FK), com a referência logo abaixo da tabela |
| `[x]` | atributo opcional (aceita vazio) |
| `{U}` | valor único (não pode repetir entre linhas) |

### Esquema relacional textual

**Empresa** (<ins>id_empresa</ins>, nome {U}, [site])

**Plataforma** (<ins>id_plataforma</ins>, nome {U}, [site], tem_conta)

**Vaga** (<ins>id_vaga</ins>, cargo, [link] {U}, modalidade, jornada, [bolsa], #id_empresa, #id_plataforma)

- `#id_empresa` referencia Empresa (`id_empresa`)
- `#id_plataforma` referencia Plataforma (`id_plataforma`)

**Candidatura** (<ins>id_candidatura</ins>, data_inscricao, desfecho, curriculo_enviado, [anotacoes], #id_vaga {U})

- `#id_vaga` referencia Vaga (`id_vaga`)

**Etapa** (<ins>id_etapa</ins>, tipo, data, [data_limite], situacao, [resultado], #id_candidatura)

- `#id_candidatura` referencia Candidatura (`id_candidatura`)

**Contato** (<ins>id_contato</ins>, nome, meio_contato, #id_candidatura)

- `#id_candidatura` referencia Candidatura (`id_candidatura`)

### Valores únicos

`Empresa.nome`, `Plataforma.nome`, `Vaga.link` e `Candidatura.id_vaga`.

### Regras que o banco não garante sozinho (ficam no backend)

- Toda candidatura nasce com a etapa "inscrição" (mínimo de 1 etapa).

### Decisões

- **A FK entre Vaga e Candidatura fica em Candidatura:** nunca é vazia, e o `{U}` garante no máximo uma candidatura por vaga.
- **Script SQL escrito à mão:** o BRModelo gera código a partir do diagrama, mas o script do projeto é escrito manualmente, para controlar cada restrição.

### Tipos das colunas (MySQL)

| Tabela | Coluna | Tipo | Obrigatória | Extras |
|---|---|---|---|---|
| Empresa | id_empresa | INT | sim | PK, auto incremento |
| Empresa | nome | VARCHAR(100) | sim | único |
| Empresa | site | VARCHAR(255) | não | |
| Plataforma | id_plataforma | INT | sim | PK, auto incremento |
| Plataforma | nome | VARCHAR(100) | sim | único |
| Plataforma | site | VARCHAR(255) | não | |
| Plataforma | tem_conta | BOOLEAN | sim | padrão: falso |
| Vaga | id_vaga | INT | sim | PK, auto incremento |
| Vaga | cargo | VARCHAR(150) | sim | |
| Vaga | link | VARCHAR(500) | não | único |
| Vaga | modalidade | ENUM('remoto','presencial','hibrido') | sim | |
| Vaga | jornada | ENUM('integral','meio_periodo') | sim | |
| Vaga | bolsa | DECIMAL(10,2) | não | |
| Vaga | id_empresa | INT | sim | FK → Empresa |
| Vaga | id_plataforma | INT | sim | FK → Plataforma |
| Candidatura | id_candidatura | INT | sim | PK, auto incremento |
| Candidatura | data_inscricao | DATE | sim | |
| Candidatura | desfecho | ENUM('em_andamento','aprovado','reprovado','desisti','sem_resposta','classificado','lista_espera','banco_talentos') | sim | padrão: em_andamento |
| Candidatura | curriculo_enviado | VARCHAR(100) | sim | |
| Candidatura | anotacoes | TEXT | não | |
| Candidatura | id_vaga | INT | sim | FK → Vaga, único |
| Etapa | id_etapa | INT | sim | PK, auto incremento |
| Etapa | tipo | VARCHAR(50) | sim | texto livre (a lista de tipos cresce) |
| Etapa | data | DATETIME | sim | |
| Etapa | data_limite | DATETIME | não | |
| Etapa | situacao | ENUM('pendente','concluida','cancelada') | sim | padrão: pendente |
| Etapa | resultado | ENUM('aprovado','reprovado') | não | |
| Etapa | id_candidatura | INT | sim | FK → Candidatura |
| Contato | id_contato | INT | sim | PK, auto incremento |
| Contato | nome | VARCHAR(100) | sim | |
| Contato | meio_contato | VARCHAR(255) | sim | |
| Contato | id_candidatura | INT | sim | FK → Candidatura |

Domínios impostos com ENUM. Os valores ficam sem acento nem espaço
(`em_andamento`, `lista_espera`), e o texto bonito é montado no frontend.

O diagrama do BRModelo não exibe se uma coluna é obrigatória. A coluna **Obrigatória** desta tabela é a referência, e as regras de `NOT NULL` são definidas no script SQL.