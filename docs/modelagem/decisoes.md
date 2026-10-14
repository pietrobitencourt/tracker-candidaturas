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

## Etapa 3: Modelo lógico (esquema relacional textual)

### Notação

| Símbolo | Significado |
|---|---|
| <ins>x</ins> | chave primária (PK) |
| `#x` | chave estrangeira (FK), com a referência logo abaixo da tabela |
| `[x]` | atributo opcional (aceita vazio) |
| `{U}` | valor único (não pode repetir entre linhas) |

### Esquema

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