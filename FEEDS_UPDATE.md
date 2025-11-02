# Sistema de Atualização de Feeds - FeedDeck

Este documento descreve as correções implementadas para os problemas de atualização manual e automática de feeds no FeedDeck.

## Problemas Corrigidos

### 1. Atualização Manual de Feeds
**Problema**: O botão de refresh apenas recarregava items já existentes no banco de dados, sem buscar novos feeds.

**Solução**:
- Criada nova edge function `refresh-column-v1` que força o fetch de novos feeds
- Adicionado método `refreshColumn()` no `AppRepository`
- Adicionado método `refreshFeeds()` no `ItemsRepository`
- Botão de refresh agora chama `refreshFeeds()` em vez de `reload()`

### 2. Atualização Automática de Feeds
**Problema**: Sistema de scheduler/worker não estava configurado para rodar.

**Solução**:
- Criado `docker-compose.yml` com serviços: Redis, Scheduler e Worker
- Configurado sistema de filas com Redis
- Scheduler roda a cada 15 minutos
- Worker processa feeds continuamente

## Arquitetura

```
┌─────────────────────────────────────────┐
│  ATUALIZAÇÃO MANUAL (Via App)           │
├─────────────────────────────────────────┤
│ 1. Usuário clica botão refresh          │
│ 2. refreshFeeds() → refreshColumn()     │
│ 3. Edge Function refresh-column-v1      │
│ 4. getFeed() para cada source           │
│ 5. Upsert em Supabase                   │
│ 6. Reload de items no app               │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  ATUALIZAÇÃO AUTOMÁTICA (Via Docker)    │
├─────────────────────────────────────────┤
│ Scheduler (a cada 15 min):              │
│ 1. Busca usuários ativos                │
│ 2. Busca sources não atualizados (1h)   │
│ 3. Enfileira em Redis                   │
│                                          │
│ Worker (contínuo):                       │
│ 1. Lê job do Redis                      │
│ 2. getFeed() para o source              │
│ 3. Upsert em Supabase                   │
└─────────────────────────────────────────┘
```

## Como Usar

### Atualização Manual

No aplicativo, clique no botão de refresh (ícone de seta circular) no cabeçalho da coluna. Isso irá:
1. Buscar novos feeds de todas as fontes da coluna
2. Salvar novos items no banco de dados
3. Recarregar e exibir os items atualizados

### Atualização Automática

#### Pré-requisitos
- Docker e Docker Compose instalados
- Arquivo `.env` configurado (copie de `.env.example`)

#### Configuração

1. Copie o arquivo de exemplo de variáveis de ambiente:
```bash
cp .env.example .env
```

2. Edite o arquivo `.env` e configure:
```env
FEEDDECK_SUPABASE_URL=https://seu-projeto.supabase.co
FEEDDECK_SUPABASE_SERVICE_ROLE_KEY=sua-chave-service-role
REDIS_PASSWORD=senha-segura-aqui
```

3. Inicie os serviços:
```bash
docker-compose up -d
```

4. Verifique se os serviços estão rodando:
```bash
docker-compose ps
```

Você deve ver 3 serviços rodando:
- `feeddeck-redis` - Banco Redis para fila de jobs
- `feeddeck-scheduler` - Agendador que enfileira feeds
- `feeddeck-worker` - Worker que processa feeds (2 instâncias)

#### Gerenciamento

**Ver logs do scheduler:**
```bash
docker-compose logs -f scheduler
```

**Ver logs do worker:**
```bash
docker-compose logs -f worker
```

**Parar serviços:**
```bash
docker-compose down
```

**Reiniciar serviços:**
```bash
docker-compose restart
```

**Escalar workers (aumentar performance):**
```bash
docker-compose up -d --scale worker=4
```

## Configurações

### Intervalos de Atualização

**Scheduler**: Roda a cada 15 minutos
**Sources**: Atualizados se não foram atualizados há mais de 1 hora
**Reddit (Free Tier)**: Apenas 1x por 24h (limite de rate)

Para alterar esses intervalos, edite:
- [supabase/functions/_cmd/scheduler/scheduler.ts](supabase/functions/_cmd/scheduler/scheduler.ts#L52)

### Workers

Por padrão, 2 workers rodam simultaneamente. Para ajustar:
- Edite `docker-compose.yml`, seção `worker.deploy.replicas`
- Ou use: `docker-compose up -d --scale worker=N`

## Deploy da Edge Function

Para fazer deploy da nova edge function:

```bash
supabase functions deploy refresh-column-v1
```

## Troubleshooting

### Edge function não encontrada
```bash
supabase functions deploy refresh-column-v1
```

### Scheduler/Worker não conectam ao Supabase
- Verifique se `FEEDDECK_SUPABASE_URL` está correto
- Verifique se `FEEDDECK_SUPABASE_SERVICE_ROLE_KEY` é válido

### Redis connection refused
- Certifique-se que o Redis está rodando: `docker-compose ps`
- Verifique a senha no `.env`

### Feeds não atualizam
- Verifique logs: `docker-compose logs scheduler worker`
- Verifique se há sources elegíveis (última atualização > 1h)
- Para free tier, Reddit precisa 24h entre atualizações

## Arquivos Modificados/Criados

### Novos Arquivos
- `supabase/functions/refresh-column-v1/index.ts` - Edge function para refresh manual
- `docker-compose.yml` - Configuração Docker para scheduler/worker
- `.env.example` - Exemplo de variáveis de ambiente
- `FEEDS_UPDATE.md` - Este documento

### Arquivos Modificados
- `app/lib/repositories/app_repository.dart` - Adicionado `refreshColumn()`
- `app/lib/repositories/items_repository.dart` - Adicionado `refreshFeeds()`
- `app/lib/widgets/column/header/column_layout_header.dart` - Botão usa `refreshFeeds()`

## Limitações

- Atualização manual pode demorar alguns segundos dependendo do número de sources
- Free tier tem limitações de frequência para Reddit (24h)
- Sources do tipo "nitter" foram depreciados e não são mais atualizados

## Próximos Passos Recomendados

1. **Monitoramento**: Adicionar logs e métricas para acompanhar performance
2. **Rate Limiting**: Implementar controle mais granular de rate limits
3. **Retry Logic**: Adicionar retry automático para feeds que falharem
4. **Cache**: Implementar cache inteligente para reduzir chamadas a APIs externas
5. **Notificações**: Alertar usuário quando refresh manual falhar
