# Planka ↔ Map Bridge (fase prática)

Camada pragmática e externa ao core do Planka para operar integrações entre `Map` e `MarksPlan/Planka` com o menor acoplamento forte possível.

## Objetivo da fase prática

- preservar o upstream do Planka;
- evitar mexer no `server/` do Planka;
- oferecer um utilitário claro e executável do lado marks;
- preparar um receptor leve opcional para ingestão de eventos externos ou automações futuras;
- refletir a regra canônica do usuário: o MarksPlan é a superfície principal de edição e o Map é espelho semântico/mental, não editor principal.

## Fluxos disponíveis

### 1) Planka → Map

Fluxo já existente para espelhamento de boards/cards/labels do Planka para o Map.

Arquivos:

- `planka_map_bridge.py`
- `planka_map_receiver.py`

### 2) Map → Planka (importador direto por API)

Fluxo novo, pragmático e de baixo acoplamento para importar conteúdo canônico do Map para o MarksPlan/Planka.

Arquivo:

- `map_to_planka_importer.py`

Regras canônicas aplicadas neste importador:

- cada `project` do Map vira um `Project` no MarksPlan/Planka
- dentro de cada `Project` existe um board padrão fixo: `Execução`
- `labels = modules`
- `cards = tasks`
- tudo entra inicialmente em `BackLogs`

Capacidades mínimas implementadas:

1. autenticação no Planka via API direta;
2. descoberta/criação de um `Project` no Planka para cada projeto do Map;
3. criação/localização do board padrão `Execução` em cada projeto importado;
4. criação/localização da lista `BackLogs` e listas mínimas canônicas opcionais;
5. criação/localização de labels por módulo;
6. criação de cards com metadados mínimos de origem na descrição;
7. associação da label principal do módulo ao card;
8. idempotência mínima por `MapTaskId` na descrição do card.

## Endpoints usados pelo importador Map → Planka

### Map

- `GET /api/map/v1/projects`
- `GET /api/map/v1/projects/{project_slug}/tasks`

Observação:

- os caminhos acima são configuráveis por ambiente via `MAP_PROJECTS_ENDPOINT` e `MAP_TASKS_ENDPOINT_TEMPLATE`, para manter o importador pragmático caso a API real do Map use variantes.

### Planka

- `POST /api/access-tokens`
- `GET /api/projects`
- `POST /api/projects`
- `GET /api/projects/{projectId}/boards`
- `POST /api/projects/{projectId}/boards`
- `GET /api/boards/{boardId}`
- `POST /api/boards/{boardId}/lists`
- `POST /api/boards/{boardId}/labels`
- `POST /api/lists/{listId}/cards`
- `POST /api/cards/{cardId}/labels`

## Mapeamento adotado

- `board` do Planka → `project` no Map
- `labels` do card no Planka/MarksPlan → `modules` no Map
- `card` do Planka → `task` no Map
- `list` do Planka → contexto operacional de entrada/status/backlog

### Regras pragmáticas

- `project_slug`: resolve nesta ordem: `--project-slug` explícito → alias/config por ambiente (`PLANKA_MAP_PROJECT_SLUG_MAP_JSON` ou `PLANKA_MAP_PROJECT_SLUG_MAP`) → fallback por slugificação do `board_name`.
- `module_slug`: preferencialmente definido explicitamente; se ausente, deriva do primeiro rótulo (`label`) recebido.
- `module_labels`: lista de módulos lógicos vindos das labels do card; o primeiro item é usado como módulo principal quando o Map exigir um único `module_slug`.
- `task.title`: vem do título do card.
- `task.description`: vem da descrição do card quando disponível.
- `BackLogs`: lista padrão de entrada para tarefas novas criadas por integração/API quando nenhum contexto melhor for informado.
- `task.status`: vem do evento/status explícito ou é inferido pragmaticamente a partir da lista/evento.
- `task.priority`: aceita valores pragmáticos (`low`, `medium`, `high`, `urgent`) com normalização simples.
- `task.assignee`: usa responsável explícito ou concatena `member_names` recebidos do MarksPlan.

## Endpoints do Map usados

- `POST /api/map/v1/integration/bootstrap`
- `POST /api/map/v1/integration/task/upsert`
- `POST /api/map/v1/integration/session/start`
- `POST /api/map/v1/integration/session/progress`
- `POST /api/map/v1/integration/session/end`

## Arquivos

- `planka_map_bridge.py`: CLI principal do bridge
- `planka_map_receiver.py`: HTTP receiver opcional para eventos externos
- `map_to_planka_importer.py`: importador direto Map -> Planka
- `.env.example`: variáveis mínimas de configuração

## Configuração

```bash
cd /www/wwwroot/marks.ia.br/marks/ecosystem/systems/planka/bridge
cp .env.example .env
```

Variáveis principais:

- `MAP_URL`: URL base do Map, ex. `http://127.0.0.1:20320`
- `PLANKA_URL`: URL base do Planka, ex. `http://127.0.0.1:3000`
- `MAP_SESSION_COOKIE`: cookie de sessão do Map para autenticação fase 1
- `MAP_API_KEY`: fallback opcional
- `MAP_AUTH_BEARER`: fallback opcional para `Authorization: Bearer`
- `PLANKA_EMAIL` / `PLANKA_PASSWORD`: credenciais da API do Planka
- `PLANKA_TOKEN`: token já emitido pelo Planka, se preferir evitar login por senha
- `PLANKA_MAP_ACTOR`: ator lógico enviado ao Map
- `PLANKA_MAP_HOST`: host lógico para início/progresso/fim de sessão
- `PLANKA_MAP_DEFAULT_INBOX_LIST`: lista canônica padrão de entrada, ex. `BackLogs`
- `PLANKA_MAP_DEFAULT_MODULE`: fallback de módulo quando o card não trouxer labels
- `PLANKA_IMPORT_BOARD_NAME`: nome fixo do board padrão dentro de cada project importado
- `PLANKA_IMPORT_CONTAINER_BACKGROUND`: background do project container criado no Planka
- `PLANKA_IMPORT_CREATE_MINIMAL_LISTS`: se `1`, cria `BackLogs`, `To Do`, `Doing`, `Review`, `Blocked`, `Done`
- `MAP_PROJECTS_ENDPOINT`: endpoint de listagem de projetos do Map
- `MAP_TASKS_ENDPOINT_TEMPLATE`: template do endpoint de tasks do projeto no Map
- `PLANKA_MAP_PROJECT_SLUG_MAP_JSON`: objeto JSON com aliases de `board_name -> project_slug`
- `PLANKA_MAP_PROJECT_SLUG_MAP`: alternativa simples por pares `nome=slug`
- `PLANKA_MAP_MODULE_SLUG_MAP_JSON`: aliases opcionais de `label -> module_slug` para casar labels humanas com módulos reais do Map
- `PLANKA_MAP_MODULE_SLUG_MAP`: alternativa simples por pares `label=module_slug`
- `PLANKA_MAP_RECEIVER_SECRET_HEADER`: nome do header de autenticação do receiver
- `PLANKA_MAP_RECEIVER_SECRET`: segredo simples do receiver

### Alias de projeto por ambiente

Para produção mínima, a bridge agora aceita um mapeamento explícito e confiável de board para projeto do Map.

Opção preferencial, em JSON:

```bash
PLANKA_MAP_PROJECT_SLUG_MAP_JSON={"Marks Plan":"ecosystem-marks"}
```

Opção alternativa, em pares simples:

```bash
PLANKA_MAP_PROJECT_SLUG_MAP="Marks Plan=ecosystem-marks;Board Secundário=outro-projeto"
```

Detalhes do resolvedor:

- tenta casar primeiro pelo nome exato do board;
- tenta também variações normalizadas em minúsculas;
- aceita como chave tanto o nome humano (`Marks Plan`) quanto o slug do board (`marks-plan`);
- se nada casar, faz fallback para `slugify(board_name)`.

## Autenticação

Fase 1, em ordem de preferência:

1. `MAP_SESSION_COOKIE`
2. `MAP_API_KEY`
3. `MAP_AUTH_BEARER`

Observação importante:

- o estado atual do `map` protege a API principalmente por sessão autenticada;
- por isso o caminho mais direto nesta fase é reutilizar o cookie de sessão do operador/serviço;
- quando a autenticação do `map` evoluir para credenciais técnicas mais explícitas, o bridge já suporta envio por header.

## Fluxo canônico refletido pela bridge

- projetos nascem no MarksPlan (`board -> project`);
- novas tarefas por integração entram sempre em `BackLogs` por padrão;
- módulos do Map são identificados por `labels` no MarksPlan;
- a `list` continua útil, mas apenas como contexto de backlog/status/etapa operacional;
- o Map recebe espelhamento semântico pragmático, sem tentar virar editor principal.

## Correspondência pragmática MarksPlan → Map

### Projeto

- `board_name` / `project_name` → `project_slug` + `project_name`

### Módulo

- `label_names` → `module_labels`
- resolvedor tenta casar labels com módulos reais do projeto via bootstrap leve do Map
- se necessário, aliases por ambiente (`PLANKA_MAP_MODULE_SLUG_MAP_JSON` / `PLANKA_MAP_MODULE_SLUG_MAP`) podem mapear labels humanas para `module_slug` existente
- primeiro match válido vira `module_name`/`module_slug` principal
- sem labels → fallback em `PLANKA_MAP_DEFAULT_MODULE`

### Tarefa

- `card_title` → `task.title`
- `description` → `task.description`

### Status

Normalização pragmática suportada:

- `BackLogs`, `backlog`, `todo`, `open`, `pending`, `triage` → `open`
- `doing`, `working`, `in_progress` → `in_progress`
- `review`, `qa`, `validation` → `review`
- `blocked`, `paused` → `blocked`
- `done`, `completed`, `archived` → `done`

Quando não há status explícito, a bridge tenta inferir pela lista ou pelo tipo de evento do Planka.
O payload enviado ao Map passa a usar apenas status canônicos compatíveis: `open`, `in_progress`, `blocked`, `review`, `done`.

### Prioridade

- `low` / `baixa` → `low`
- `medium` / `media` / `normal` → `medium`
- `high` / `alta` → `high`
- `urgent` / `critical` / `blocker` → `urgent`

### Responsável

- `assignee` explícito é preservado;
- se ausente, `member_names` (CSV) é consolidado em texto simples para o Map;
- se ainda ausente, usa `PLANKA_MAP_DEFAULT_ASSIGNEE`.

## Uso do CLI

## Uso do importador Map → Planka

### Dry-run seguro

```bash
python3 map_to_planka_importer.py \
  --map-url http://127.0.0.1:20320 \
  --planka-url http://127.0.0.1:3000 \
  --dry-run
```

### Importar todos os projetos do Map

```bash
python3 map_to_planka_importer.py \
  --map-url http://127.0.0.1:20320 \
  --planka-url http://127.0.0.1:3000
```

### Importar apenas projetos específicos

```bash
python3 map_to_planka_importer.py \
  --project-slugs ecosystem-marks,core-platform
```

### Planejar limpeza segura do conteúdo importado

```bash
python3 map_to_planka_importer.py \
  --plan-cleanup \
  --dry-run
```

### Comportamento do importador

- para cada projeto do Map, localiza ou cria um `Project` homônimo no Planka;
- dentro de cada `Project`, localiza ou cria o board fixo `Execução`;
- localiza ou cria `BackLogs`, `To Do`, `Doing`, `Review`, `Blocked` e `Done` se configurado;
- localiza ou cria uma label do board para o módulo principal da task;
- cria card em `BackLogs` com descrição enriquecida com metadados de origem;
- evita duplicação em reruns procurando `MapTaskId:` na descrição dos cards já existentes.

### Metadados mínimos gravados na descrição do card

```text
MapTaskId: 123
project_slug: ecosystem-marks
module_slug: planka
status: open
priority: high
```

## Uso do CLI legado Planka → Map

### 1) Bootstrap

```bash
python3 planka_map_bridge.py bootstrap \
  --project-slug ecosystem-marks \
  --module-slug map
```

### 2) Upsert de task a partir do mapeamento board/labels/card

```bash
python3 planka_map_bridge.py upsert \
  --board-name "Marks Plan" \
  --list-name "BackLogs" \
  --label-names "planka,map" \
  --card-title "Integrar Planka ao Map" \
  --description "Fluxo canônico com labels como módulos" \
  --status in_progress \
  --priority high
```

Exemplo com alias configurado para resolver o projeto correto sem depender de slugify ingênuo:

```bash
PLANKA_MAP_PROJECT_SLUG_MAP_JSON='{"Marks Plan":"ecosystem-marks"}' \
python3 planka_map_bridge.py upsert \
  --board-name "Marks Plan" \
  --list-name "BackLogs" \
  --label-names "planka,map" \
  --card-title "Integrar Planka ao Map" \
  --dry-run
```

### 3) Início de sessão

```bash
python3 planka_map_bridge.py session-start \
  --project-slug marks-plan \
  --module-slug planka \
  --title "Integrar Planka ao Map" \
  --note "Sessão iniciada para implementação da fase 1"
```

### 4) Progresso de sessão

```bash
python3 planka_map_bridge.py session-progress \
  --project-slug marks-plan \
  --module-slug planka \
  --title "Integrar Planka ao Map" \
  --percent 70 \
  --message "Bridge e README implementados" \
  --task-status review \
  --host-state working \
  --note "Executando validação estática"
```

### 5) Encerramento de sessão

```bash
python3 planka_map_bridge.py session-end \
  --project-slug marks-plan \
  --module-slug planka \
  --title "Integrar Planka ao Map" \
  --task-status done \
  --host-state idle \
  --note "Fase 1 concluída"
```

### 6) Transformação genérica de evento

```bash
python3 planka_map_bridge.py from-event \
  --event-name card.updated \
  --board-name "Marks Plan" \
  --list-name "BackLogs" \
  --label-names "planka,map" \
  --card-title "Integrar Planka ao Map" \
  --description "Atualização pragmática do bridge"
```

### 7) Dry run

```bash
python3 planka_map_bridge.py upsert \
  --board-name "Marks Plan" \
  --list-name "Planka" \
  --card-title "Integrar Planka ao Map" \
  --dry-run
```

### 8) Smoke test lógico do resolvedor de projeto

```bash
PLANKA_MAP_PROJECT_SLUG_MAP_JSON='{"Marks Plan":"ecosystem-marks"}' \
python3 planka_map_bridge.py resolve-project --board-name "Marks Plan"
```

Saída esperada:

```json
{
  "ok": true,
  "board_name": "Marks Plan",
  "project_slug": "ecosystem-marks"
}
```

## Receiver opcional

O `planka_map_receiver.py` expõe um endpoint HTTP local para receber eventos externos e encaminhá-los ao CLI.

Subida:

```bash
cp .env.example .env
./service.sh start
```

Endpoint:

- `POST /planka/events`
- `GET /health`

Autenticação simples:

- header padrão: `X-Planka-Bridge-Secret`
- valor: `PLANKA_MAP_RECEIVER_SECRET`

Payload exemplo:

```json
{
  "event_name": "card.updated",
  "board_name": "Marks Plan",
  "list_name": "BackLogs",
  "label_names": "planka,map",
  "member_names": "marcos,markscode",
  "card_title": "Integrar Planka ao Map",
  "description": "Receiver transformando evento em upsert no Map",
  "status": "in_progress",
  "priority": "high",
  "host": "srv-dev-01",
  "actor": "markscode"
}
```

Exemplo de healthcheck:

```bash
./service.sh health
```

Exemplo de envio autenticado:

```bash
curl -X POST http://127.0.0.1:8941/planka/events \
  -H 'Content-Type: application/json' \
  -H 'X-Planka-Bridge-Secret: seu-segredo' \
  -d '{
    "event_name": "card.created",
    "board_name": "Marks Plan",
    "list_name": "BackLogs",
    "label_names": "planka,map",
    "card_title": "Nova tarefa criada por integração"
  }'
```

## Operação local no marks3

Arquivo operacional incluído:

- `service.sh`

Comandos:

```bash
./service.sh start
./service.sh status
./service.sh health
./service.sh logs
./service.sh stop
```

## Limites conhecidos da fase prática

- não há acoplamento nativo com eventos internos do core do Planka;
- o receiver é propositalmente genérico e externo, servindo como ponto de entrada de automações futuras;
- a autenticação do `map` ainda é mais confortável por sessão do que por credencial técnica dedicada;
- não há persistência local de mapeamentos complexos board/card → IDs do Map nesta etapa;
- múltiplas labels são enviadas como contexto, mas o endpoint atual do Map ainda é tratado pragmaticamente com um `module_slug` principal;
- a tradução de eventos continua intencionalmente mínima e baseada em convenção;
- para webhook real do Planka, ainda será necessário um emissor confiável de eventos externos ou uma camada adicional de captura sem alterar pesadamente o upstream.
