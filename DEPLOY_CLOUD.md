# FeedDeck - Deploy na Cloud (Vercel + Supabase)

Guia completo para fazer deploy do FeedDeck na cloud usando **Vercel** (frontend) e **Supabase Cloud** (backend).

## Arquitetura

```
┌─────────────────────────────────────┐
│         Vercel (Frontend)           │
│   https://seu-feeddeck.vercel.app   │
│         Flutter Web Build           │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│      Supabase Cloud (Backend)       │
│   - PostgreSQL Database             │
│   - Authentication (GoTrue)         │
│   - Storage (S3)                    │
│   - Edge Functions (Deno)           │
│   - Realtime                        │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│       Upstash Redis (Queue)         │
│   Scheduler/Worker para feeds       │
└─────────────────────────────────────┘
```

## Pré-requisitos

- Conta GitHub (gratuita)
- Conta Supabase (gratuita) - https://supabase.com
- Conta Vercel (gratuita) - https://vercel.com
- Conta Upstash (gratuita) - https://upstash.com
- YouTube API Key (opcional mas recomendado) - https://console.cloud.google.com
- Node.js instalado localmente (para Supabase CLI)

## Tempo Total Estimado

**1-1.5 horas** para primeira instalação

## Custo

**$0** - Todos os serviços têm planos gratuitos generosos para uso pessoal

---

## Passo 1: Setup Supabase Cloud (15 minutos)

### 1.1. Criar Projeto

1. Acesse https://supabase.com e crie uma conta
2. Clique em "New Project"
3. Preencha:
   - **Name:** feeddeck (ou nome de sua preferência)
   - **Database Password:** Crie uma senha forte e anote
   - **Region:** Escolha a região mais próxima de você
4. Aguarde a criação do projeto (~2 minutos)

### 1.2. Anotar Credenciais

No dashboard do projeto, vá em **Settings → API**:

- **Project URL:** `https://abcdefgh.supabase.co`
- **anon public key:** `eyJhbGc...` (chave longa)
- **service_role key:** `eyJhbGc...` (chave longa - SECRETA!)

⚠️ **IMPORTANTE:** Salve essas credenciais em local seguro!

### 1.3. Instalar Supabase CLI

**Escolha UMA das opções abaixo para Windows:**

#### Opção A: Scoop (Recomendado)
```powershell
# Se não tiver o Scoop, instale primeiro:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression

# Instalar Supabase CLI:
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase
```

#### Opção B: Chocolatey
```powershell
choco install supabase
```

#### Opção C: Winget (Windows 10/11)
```powershell
winget install Supabase.supabase-cli
```

#### Opção D: Via NPX (sem instalar globalmente)
```bash
# Use npx antes de cada comando
npx supabase login
npx supabase link --project-ref SEU_REF
npx supabase db push
```

**Verificar instalação:**
```bash
supabase --version
```

### 1.4. Fazer Login e Linkar Projeto

```bash
# Login
supabase login

# Navegue até a pasta do projeto
cd c:\Users\luize\OneDrive\Desenvolvimento\feeddeck

# Linkar projeto (obtenha o ref em Settings → General → Reference ID)
supabase link --project-ref SEU_PROJECT_REF
```

### 1.5. Aplicar Migrações do Banco

```bash
# Aplicar todas as migrações
supabase db push
```

Você verá algo como:
```
Applying migration 20231001000000_create_profiles.sql...
Applying migration 20231002000000_create_decks.sql...
...
All migrations applied successfully!
```

### 1.6. Configurar Tabela Settings

Acesse o **SQL Editor** no dashboard e execute:

```sql
INSERT INTO settings (key, value) VALUES
('supabase_api_url', 'https://SEU_PROJECT_REF.supabase.co'),
('supabase_service_role_key', 'SEU_SERVICE_ROLE_KEY');
```

Substitua pelos valores reais do seu projeto.

---

## Passo 2: Setup Redis (Upstash) (5 minutos)

### 2.1. Criar Conta e Database

1. Acesse https://upstash.com e crie uma conta
2. Clique em "Create Database"
3. Escolha:
   - **Type:** Redis
   - **Name:** feeddeck-redis
   - **Region:** Mesma do Supabase (se possível)
   - **Plan:** Free (10,000 comandos/dia)
4. Clique em "Create"

### 2.2. Anotar Credenciais

Na página do database, copie:

- **Endpoint:** `us1-your-redis.upstash.io`
- **Port:** `6379`
- **Password:** `AaBbCc...`

---

## Passo 3: Gerar Chaves de Criptografia (2 minutos)

### 3.1. Executar Script PowerShell

```powershell
# Na raiz do projeto
.\generate-keys.ps1
```

### 3.2. Copiar Chaves Geradas

O script gerará duas chaves e salvará em `keys.txt`:

```
FEEDDECK_ENCRYPTION_KEY=AbCd1234...
FEEDDECK_ENCRYPTION_IV=XyZ9876...
```

⚠️ **GUARDE ESTAS CHAVES COM SEGURANÇA!**

---

## Passo 4: Configurar Variáveis de Ambiente (10 minutos)

### 4.1. Criar Arquivo .env.cloud

```bash
cd supabase
cp .env.cloud.example .env.cloud
```

### 4.2. Editar .env.cloud

Abra `supabase/.env.cloud` e preencha todos os valores:

```env
# Supabase (do Passo 1.2)
FEEDDECK_SUPABASE_URL=https://SEU_PROJECT_REF.supabase.co
FEEDDECK_SUPABASE_ANON_KEY=sua-anon-key
FEEDDECK_SUPABASE_SERVICE_ROLE_KEY=sua-service-role-key
FEEDDECK_SUPABASE_SITE_URL=https://seu-feeddeck.vercel.app  # Ajustar depois

# Redis Upstash (do Passo 2.2)
FEEDDECK_REDIS_HOSTNAME=seu-redis.upstash.io
FEEDDECK_REDIS_PORT=6379
FEEDDECK_REDIS_USERNAME=
FEEDDECK_REDIS_PASSWORD=seu-redis-password

# Criptografia (do Passo 3.2)
FEEDDECK_ENCRYPTION_KEY=sua-encryption-key
FEEDDECK_ENCRYPTION_IV=seu-encryption-iv

# YouTube API (recomendado)
FEEDDECK_SOURCE_YOUTUBE_API_KEY=sua-youtube-api-key

# Nitter (opcional - para Twitter/X feeds)
FEEDDECK_SOURCE_NITTER_INSTANCE=https://nitter.net
FEEDDECK_SOURCE_NITTER_BASIC_AUTH=

# Logging
FEEDDECK_LOG_LEVEL=info
```

### 4.3. Configurar Secrets no Supabase

```bash
# Ainda na pasta supabase/
supabase secrets set --env-file .env.cloud
```

Você verá:
```
Setting secret FEEDDECK_SUPABASE_URL...
Setting secret FEEDDECK_REDIS_HOSTNAME...
...
All secrets set successfully!
```

---

## Passo 5: Deploy Edge Functions (15 minutos)

### 5.1. Deploy das Funções

Execute os seguintes comandos na pasta raiz:

```bash
cd supabase

# Funções principais (com autenticação)
supabase functions deploy add-or-update-source-v1
supabase functions deploy add-source-v1
supabase functions deploy delete-user-v1
supabase functions deploy generate-magic-link-v1
supabase functions deploy profile-v1
supabase functions deploy profile-v2

# Funções públicas (sem autenticação)
supabase functions deploy image-proxy-v1 --no-verify-jwt
supabase functions deploy revenuecat-webhooks-v1 --no-verify-jwt
supabase functions deploy stripe-webhooks-v1 --no-verify-jwt

# Opcional: Funções de pagamento (apenas se usar Stripe)
# supabase functions deploy stripe-create-billing-portal-link-v1
# supabase functions deploy stripe-create-checkout-session-v1
```

Cada deploy leva ~10-20 segundos.

### 5.2. Configurar Scheduler (Cron Job)

#### Opção A: Via pg_cron (Recomendado)

No **SQL Editor** do Supabase:

```sql
-- Habilitar extensão pg_cron
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Agendar scheduler para rodar a cada 5 minutos
SELECT cron.schedule(
  'feeddeck-scheduler',
  '*/5 * * * *',
  $$
  SELECT net.http_post(
    url := 'https://SEU_PROJECT_REF.supabase.co/functions/v1/_cmd/scheduler',
    headers := '{"Authorization": "Bearer SEU_SERVICE_ROLE_KEY", "Content-Type": "application/json"}'::jsonb,
    body := '{}'::jsonb
  ) AS request_id;
  $$
);
```

Substitua `SEU_PROJECT_REF` e `SEU_SERVICE_ROLE_KEY` pelos valores reais.

#### Opção B: Via GitHub Actions (Alternativa)

Crie `.github/workflows/scheduler.yml`:

```yaml
name: FeedDeck Scheduler

on:
  schedule:
    - cron: '*/5 * * * *'  # A cada 5 minutos
  workflow_dispatch:  # Permite execução manual

jobs:
  trigger-scheduler:
    runs-on: ubuntu-latest
    steps:
      - name: Call Scheduler Function
        run: |
          curl -X POST \
            https://SEU_PROJECT_REF.supabase.co/functions/v1/_cmd/scheduler \
            -H "Authorization: Bearer ${{ secrets.SUPABASE_SERVICE_ROLE_KEY }}" \
            -H "Content-Type: application/json"
```

Configure o secret `SUPABASE_SERVICE_ROLE_KEY` no GitHub.

---

## Passo 6: Configurar Autenticação (5 minutos)

No dashboard do Supabase:

### 6.1. URL Configuration

**Authentication → URL Configuration:**

- **Site URL:** `https://seu-feeddeck.vercel.app` (ajustar depois do deploy Vercel)
- **Redirect URLs:** Adicione:
  - `https://seu-feeddeck.vercel.app/**`
  - `https://seu-feeddeck.vercel.app/reset-password`
  - `http://localhost:8080/**` (para testes locais)

### 6.2. Email Provider

**Authentication → Providers → Email:**

- Habilitar "Enable Email provider"
- (Opcional) Configurar SMTP customizado

### 6.3. Email Templates (Opcional)

**Authentication → Email Templates:**

Você pode customizar os templates de confirmação de email, reset de senha, etc.

---

## Passo 7: Deploy no Vercel (15 minutos)

### 7.1. Push para GitHub

Se ainda não fez:

```bash
git add .
git commit -m "Adicionar configuração para deploy cloud"
git push origin main
```

### 7.2. Importar Projeto no Vercel

1. Acesse https://vercel.com e faça login (pode usar conta GitHub)
2. Clique em "Add New..." → "Project"
3. Selecione o repositório do FeedDeck
4. Clique em "Import"

### 7.3. Configurar Build

Na tela de configuração:

- **Framework Preset:** Other
- **Build Command:** (usar do vercel.json automaticamente)
- **Output Directory:** `app/build/web`
- **Install Command:** (usar do vercel.json automaticamente)

### 7.4. Configurar Environment Variables

Clique em "Environment Variables" e adicione:

| Name | Value |
|------|-------|
| `SUPABASE_URL` | `https://SEU_PROJECT_REF.supabase.co` |
| `SUPABASE_ANON_KEY` | `sua-anon-key` |
| `SUPABASE_SITE_URL` | `https://seu-feeddeck.vercel.app` |
| `GOOGLE_CLIENT_ID` | (deixe vazio se não usar OAuth) |

⚠️ **Nota:** Você precisará atualizar `SUPABASE_SITE_URL` após obter a URL final do Vercel.

### 7.5. Deploy

1. Clique em "Deploy"
2. Aguarde o build (~5-10 minutos na primeira vez)
3. Após concluído, anote a URL: `https://seu-feeddeck.vercel.app`

### 7.6. Atualizar URLs

Agora que tem a URL final:

1. **No Supabase:** Vá em Authentication → URL Configuration e atualize o Site URL
2. **No Vercel:** Settings → Environment Variables → Edite `SUPABASE_SITE_URL`
3. **Redeploy:** No Vercel, vá em Deployments → Três pontos → Redeploy

---

## Passo 8: Configurar Domínio Personalizado (Opcional - 10 minutos)

### 8.1. Adicionar Domínio no Vercel

1. No projeto Vercel, vá em **Settings → Domains**
2. Adicione seu domínio (ex: `feeddeck.seudominio.com`)
3. Configure os registros DNS conforme instruções:
   - **CNAME:** `feeddeck` → `cname.vercel-dns.com`
   - Ou **A Record:** `76.76.21.21`

### 8.2. Aguardar Propagação DNS

- Leva 5-60 minutos
- SSL será configurado automaticamente

### 8.3. Atualizar URLs Novamente

Repita o Passo 7.6 com o novo domínio.

---

## Passo 9: Testes Finais (10 minutos)

### 9.1. Acessar Aplicação

Abra `https://seu-feeddeck.vercel.app` (ou seu domínio)

### 9.2. Criar Conta

1. Clique em "Sign Up"
2. Preencha email e senha
3. Verifique email de confirmação
4. Faça login

### 9.3. Adicionar Feeds de Teste

1. Criar novo deck
2. Adicionar coluna
3. Adicionar fontes:
   - **RSS:** https://blog.golang.org/feed.atom
   - **YouTube:** Cole URL de um canal (ex: https://www.youtube.com/@fireship)
   - **Reddit:** https://www.reddit.com/r/programming

### 9.4. Verificar Scheduler

Aguarde 5-10 minutos e verifique se os items aparecem nos feeds.

### 9.5. Verificar Logs

**No Supabase Dashboard:**

- **Logs → Edge Functions:** Verifique se scheduler e worker estão rodando
- **Logs → Database:** Verifique queries

**No Vercel Dashboard:**

- **Deployments → Logs:** Verifique se o build foi bem sucedido

---

## Manutenção

### Deploy de Atualizações

O Vercel faz deploy automático a cada push no GitHub:

```bash
# Fazer mudanças no código
git add .
git commit -m "Descrição das mudanças"
git push origin main

# Vercel faz deploy automaticamente em ~2-5 minutos
```

### Monitoramento

- **Supabase:** Dashboard → Logs
- **Vercel:** Dashboard → Analytics
- **Upstash:** Dashboard → Metrics

### Backups

Supabase faz backups automáticos diários:

- **Settings → Backups** → Download manual se necessário

### Limites dos Planos Gratuitos

#### Supabase Free Tier:
- 500 MB database storage
- 1 GB file storage
- 2 GB bandwidth/month
- 500,000 edge function invocations/month
- 50,000 monthly active users

#### Vercel Free Tier:
- 100 GB bandwidth/month
- Unlimited builds
- Unlimited sites

#### Upstash Free Tier:
- 10,000 commands/day
- 256 MB storage

Para uso pessoal, esses limites são mais que suficientes!

---

## Troubleshooting

### Build Falha no Vercel

**Erro:** `Flutter not found`

**Solução:** Verifique se o `vercel.json` está correto e se o install command está instalando o Flutter.

---

### Edge Functions não Executam

**Erro:** `Invalid JWT`

**Solução:** Verifique se os secrets foram configurados corretamente:
```bash
supabase secrets list
```

---

### Scheduler não Roda

**Erro:** Feeds não atualizam

**Solução:**
1. Verifique se o cron job foi criado:
   ```sql
   SELECT * FROM cron.job;
   ```
2. Verifique logs no Supabase Dashboard → Logs → Edge Functions

---

### Redis Connection Failed

**Erro:** `Could not connect to Redis`

**Solução:** Verifique as credenciais do Upstash no arquivo `.env.cloud` e reaplique os secrets.

---

## Próximos Passos

1. **Personalizar UI:** Edite `app/lib/` para customizar cores, logos, etc.
2. **Adicionar Analytics:** Configure Google Analytics ou similar
3. **Configurar SMTP:** Para emails transacionais profissionais
4. **Adicionar OAuth:** Configure Google/Apple Sign In
5. **Monetizar:** Configure Stripe para assinaturas (opcional)

---

## Suporte

- **GitHub Issues:** https://github.com/feeddeck/feeddeck/issues
- **Documentação Supabase:** https://supabase.com/docs
- **Documentação Vercel:** https://vercel.com/docs

---

## Recursos

- **Supabase CLI Docs:** https://supabase.com/docs/reference/cli
- **Flutter Web Docs:** https://docs.flutter.dev/deployment/web
- **Upstash Redis Docs:** https://docs.upstash.com/redis

---

**Parabéns! Seu FeedDeck está no ar! 🎉**

Acesse `https://seu-feeddeck.vercel.app` e comece a usar!
