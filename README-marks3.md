# planka no marks3

Este arquivo complementa o runtime real do **Planka** presente neste diretório.

## Papel deste módulo no marks3

- nome canônico do ecosystem: `planka`
- runtime real: `ghcr.io/plankanban/planka`
- função arquitetural: planejador central visual do marks3
- primeira integração prevista: consumo e navegação operacional via módulo `map`

## Desenho adotado

O diretório mantém o clone upstream do Planka e recebe apenas uma camada mínima de operação do marks3:

- `service.sh`: wrapper operacional com foco em `docker compose`
- `.env.example`: variáveis mínimas do marks
- `docker-compose.marks3.yml`: compose dedicado do marks3 para publicação controlada
- `planka.service`: referência para systemd usando o wrapper

Esse desenho preserva o código upstream e evita mexer no compose original além do estritamente necessário para publicação local no ecosystem.

O arquivo `docker-compose.override.yml` do upstream/local pode continuar existindo, mas o runtime do marks3 passa a usar explicitamente `docker-compose.marks3.yml` como stack operacional própria, evitando efeitos colaterais de merge automático e publicação acidental da porta `3000`.

## Papel do Planka como planejador central visual

No marks3, o Planka entra como o quadro visual central para:

- organizar iniciativas, épicos, tarefas e estados operacionais;
- concentrar visão de fluxo para automações e operadores humanos;
- servir como ponto de convergência entre planejamento visual e execução assistida.

## Integração prática via Map

Nesta fase prática, a integração continua intencionalmente simples e externa ao core:

- o `map` referencia o MarksPlan/Planka como superfície visual principal de planejamento;
- links, contexto operacional e navegação entre módulos podem apontar para o Planka;
- sem acoplamento profundo com código de negócio do runtime upstream nesta etapa;
- um bridge externo em `bridge/` pode transformar eventos/ações pragmáticas do Planka em chamadas para a API de integração do `map`.

Isso permite padronizar o módulo no ecosystem agora e deixar integrações mais profundas para fases futuras.

### Decisão arquitetural desta fase prática

Para preservar ao máximo o upstream do Planka, a integração foi implementada fora do core:

- `bridge/planka_map_bridge.py`: CLI Python simples para falar com os endpoints do `map`;
- `bridge/planka_map_receiver.py`: receptor HTTP opcional e leve para eventos externos;
- `bridge/README.md`: documentação operacional da fase 1.

Esse desenho reduz atrito, facilita remoção/evolução futura e evita alterações pesadas em `server/` ou no frontend upstream.

### Mapeamento conceitual adotado

- `board` do Planka → `project` no Map
- `labels` do card no MarksPlan/Planka → `modules` no Map
- `card` do Planka → `task` no Map
- `list` do Planka → contexto de entrada/status/backlog

Regra pragmática desta fase:

- `project_slug`: explícito quando possível; se ausente, derivado do nome do board;
- `module_slug`: explícito quando possível; se ausente, derivado do primeiro label do card;
- `BackLogs`: lista padrão de entrada para tarefas criadas por integração/API;
- `task.title`: título do card;
- `task.description`: descrição do card;
- `status`, `priority` e `assignee`: enviados explicitamente ou normalizados pragmaticamente pelo bridge.

Em outras palavras:

- projetos nascem no MarksPlan;
- módulos do Map são identificados como rótulos no MarksPlan;
- o Map é mapa mental/espelho semântico, não editor principal.

### Endpoints do Map cobertos pelo bridge

- `POST /api/map/v1/integration/bootstrap`
- `POST /api/map/v1/integration/task/upsert`
- `POST /api/map/v1/integration/session/start`
- `POST /api/map/v1/integration/session/progress`
- `POST /api/map/v1/integration/session/end`

### Configuração do bridge

No diretório `bridge/`, copie `.env.example` para `.env` e configure:

- `MAP_URL`: URL base do módulo `map`;
- `MAP_SESSION_COOKIE`: caminho preferencial de autenticação fase 1;
- `MAP_API_KEY` / `MAP_AUTH_BEARER`: fallback para cenários com chave técnica;
- `PLANKA_MAP_ACTOR` e `PLANKA_MAP_HOST`: identidade lógica da integração;
- `PLANKA_MAP_DEFAULT_INBOX_LIST=BackLogs`: lista padrão de entrada;
- `PLANKA_MAP_RECEIVER_SECRET`: segredo simples do receiver local.

### Uso inicial recomendado

Exemplos:

```bash
cd /www/wwwroot/marks.ia.br/marks/ecosystem/systems/planka/bridge

python3 planka_map_bridge.py bootstrap --project-slug ecosystem-marks --module-slug map

python3 planka_map_bridge.py upsert \
  --board-name "Marks Plan" \
  --list-name "BackLogs" \
  --label-names "planka,map" \
  --card-title "Integrar Planka ao Map"
```

Para detalhes completos, consultar `bridge/README.md`.

### Receiver operacional local

O diretório `bridge/` agora também inclui:

- `planka_map_receiver.py`: receiver HTTP com `POST /planka/events` e `GET /health`;
- `service.sh`: wrapper mínimo para operar o receiver como serviço local no marks3.

Fluxo recomendado:

```bash
cd /www/wwwroot/marks.ia.br/marks/ecosystem/systems/planka/bridge
cp .env.example .env
./service.sh start
./service.sh health
```

## Operação recomendada

Fluxo local do marks3:

1. copiar `.env.example` para `.env` se necessário;
2. ajustar `BASE_URL` e `SECRET_KEY`;
3. subir com `./service.sh start`;
4. validar com `./service.sh status` e `./service.sh health`.

Porta padrão do marks3 neste wrapper: `20321`.

## Estratégia de portas adotada

O compose upstream publica `3000:1337`. Como `ports` em múltiplos arquivos Compose tende a ser combinado, um simples override acabava expondo simultaneamente `3000` e `20321`.

Para evitar isso sem destruir o upstream, o marks3 passa a operar com um arquivo dedicado (`docker-compose.marks3.yml`) chamado explicitamente pelo `service.sh`, sem compor o serviço operacional a partir do compose upstream. Assim, o upstream permanece preservado no repositório e a publicação desejada permanece somente em `20321`.

## Observações

- este preparo não altera o código de negócio do Planka;
- o uso atual mantém Postgres via compose upstream;
- para produção pública, ainda será necessário endurecer segredos, URL final, proxy reverso e persistência operacional.
