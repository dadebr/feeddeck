# Configuração de Atualização Automática (sem Docker)

Este guia mostra como configurar a atualização automática de feeds usando apenas Supabase, sem precisar de Docker.

## Opção 1: Usando pg_cron do Supabase (Recomendado)

### Passo 1: Deploy da Edge Function

```bash
supabase functions deploy scheduled-feed-refresh
```

### Passo 2: Configurar variáveis no Supabase

No painel do Supabase, vá em **Database → Settings** e execute:

```sql
-- Configurar URL do projeto
ALTER DATABASE postgres SET app.settings.project_url = 'https://fycrsuukawnixmlmqenp.supabase.co';

-- Configurar service role key (substitua pela sua chave)
ALTER DATABASE postgres SET app.settings.service_role_key = 'sua-service-role-key-aqui';
```

**Importante**: Pegue a service role key em Settings → API → service_role key

### Passo 3: Aplicar a Migration

```bash
supabase db push
```

Isso vai criar um cron job que roda a cada 15 minutos automaticamente.

### Verificar se está funcionando

Execute no SQL Editor do Supabase:

```sql
-- Ver jobs agendados
SELECT * FROM cron.job;

-- Ver histórico de execuções
SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 10;

-- Testar manualmente
SELECT public.trigger_scheduled_feed_refresh();
```

---

## Opção 2: Usando Serviço Externo de Cron (Mais Simples)

Se você não quiser usar pg_cron, pode usar um serviço gratuito de cron como **cron-job.org** ou **EasyCron**.

### Passo 1: Deploy da Edge Function

```bash
supabase functions deploy scheduled-feed-refresh
```

### Passo 2: Obter URL e Token

1. URL da função: `https://fycrsuukawnixmlmqenp.supabase.co/functions/v1/scheduled-feed-refresh`
2. Service Role Key: Settings → API → service_role key

### Passo 3: Configurar no cron-job.org

1. Acesse: https://cron-job.org/en/
2. Crie uma conta grátis
3. Crie um novo cron job:
   - **URL**: `https://fycrsuukawnixmlmqenp.supabase.co/functions/v1/scheduled-feed-refresh?batch=50&max=100`
   - **Schedule**: Every 15 minutes
   - **Request method**: POST
   - **Headers**:
     ```
     Authorization: Bearer sua-service-role-key-aqui
     Content-Type: application/json
     ```

### Outros serviços similares:
- https://easycron.com/ (grátis até 100 jobs/dia)
- https://www.setcronjob.com/ (grátis)
- https://console.cron-job.org/ (grátis)

---

## Opção 3: Usando GitHub Actions (Grátis)

Se seu código está no GitHub, pode usar Actions para rodar o cron.

Crie o arquivo `.github/workflows/refresh-feeds.yml`:

```yaml
name: Refresh Feeds

on:
  schedule:
    # Roda a cada 15 minutos
    - cron: '*/15 * * * *'
  workflow_dispatch: # Permite rodar manualmente

jobs:
  refresh:
    runs-on: ubuntu-latest
    steps:
      - name: Call Supabase Function
        run: |
          curl -X POST \
            -H "Authorization: Bearer ${{ secrets.SUPABASE_SERVICE_ROLE_KEY }}" \
            -H "Content-Type: application/json" \
            "https://fycrsuukawnixmlmqenp.supabase.co/functions/v1/scheduled-feed-refresh?batch=50&max=100"
```

Depois configure o secret no GitHub:
1. Settings → Secrets → New repository secret
2. Nome: `SUPABASE_SERVICE_ROLE_KEY`
3. Valor: Sua service role key

---

## Testar Manualmente

Você pode testar a função manualmente com curl:

```bash
curl -X POST \
  -H "Authorization: Bearer sua-service-role-key" \
  -H "Content-Type: application/json" \
  "https://fycrsuukawnixmlmqenp.supabase.co/functions/v1/scheduled-feed-refresh?batch=50&max=100"
```

Ou direto no navegador/Postman.

---

## Monitoramento

### Ver logs da Edge Function

No painel do Supabase: **Edge Functions → scheduled-feed-refresh → Logs**

### Ver últimas atualizações de sources

```sql
SELECT id, type, title, "updatedAt"
FROM sources
ORDER BY "updatedAt" DESC
LIMIT 20;
```

---

## Parâmetros da Função

A função aceita parâmetros via query string:

- `batch`: Número de perfis a processar (padrão: 50)
- `max`: Número máximo de sources a processar (padrão: 100)

Exemplo:
```
/scheduled-feed-refresh?batch=100&max=200
```

---

## Resumo das Opções

| Opção | Custo | Dificuldade | Recomendação |
|-------|-------|-------------|--------------|
| **cron-job.org** | Grátis | Fácil | ⭐ Melhor para começar |
| **GitHub Actions** | Grátis | Média | ⭐ Boa se já usa GitHub |
| **pg_cron (Supabase)** | Grátis* | Difícil | Requer plano Pro |
| **Docker local** | Grátis | Difícil | Não recomendado para você |

*pg_cron só está disponível no Supabase Pro ($25/mês)

---

## Recomendação Final

Para você que usa Vector + Supabase, recomendo:

1. **Usar cron-job.org** - É grátis, fácil e funciona perfeitamente
2. Configurar para rodar a cada 15 minutos
3. Monitorar pelos logs do Supabase

Quer que eu ajude a configurar uma dessas opções?
