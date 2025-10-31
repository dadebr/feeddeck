# FeedDeck - Guia de Início Rápido (Cloud Deploy)

Deploy do FeedDeck na cloud em **5 passos simples**.

## Resumo

- **Tempo:** ~30-60 minutos
- **Custo:** $0 (planos gratuitos)
- **Resultado:** FeedDeck online em `https://seu-feeddeck.vercel.app`

---

## Passo 1: Criar Conta Supabase (5 min)

1. Acesse https://supabase.com
2. Crie um projeto → Escolha região → Anote credenciais
3. Instale CLI (escolha uma opção):
   - **Scoop:** `scoop bucket add supabase https://github.com/supabase/scoop-bucket.git && scoop install supabase`
   - **Chocolatey:** `choco install supabase`
   - **Winget:** `winget install Supabase.supabase-cli`
   - **NPX:** use `npx supabase` em vez de `supabase`
4. Login: `supabase login`
5. Linkar: `supabase link --project-ref SEU_REF`
6. Aplicar banco: `supabase db push`

**Anotar:**
- Project URL: `https://xxx.supabase.co`
- Anon Key
- Service Role Key

---

## Passo 2: Criar Conta Upstash (5 min)

1. Acesse https://upstash.com
2. Crie Redis database → Escolha região
3. Anote credenciais:
   - Hostname
   - Port (6379)
   - Password

---

## Passo 3: Configurar Variáveis (10 min)

### 3.1. Gerar Chaves de Criptografia

```powershell
.\generate-keys.ps1
```

Anote as chaves geradas.

### 3.2. Configurar .env.cloud

```bash
cd supabase
cp .env.cloud.example .env.cloud
# Editar .env.cloud com suas credenciais
```

Preencher:
- Supabase (Passo 1)
- Redis (Passo 2)
- Chaves de criptografia (Passo 3.1)
- YouTube API Key (opcional)

### 3.3. Aplicar Secrets

```bash
supabase secrets set --env-file .env.cloud
```

---

## Passo 4: Deploy Edge Functions (10 min)

```bash
cd supabase

# Deploy funções principais
supabase functions deploy add-or-update-source-v1
supabase functions deploy add-source-v1
supabase functions deploy profile-v1
supabase functions deploy profile-v2
supabase functions deploy image-proxy-v1 --no-verify-jwt
```

### Configurar Scheduler (Cron)

No SQL Editor do Supabase:

```sql
CREATE EXTENSION IF NOT EXISTS pg_cron;

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

---

## Passo 5: Deploy no Vercel (15 min)

### 5.1. Push para GitHub

```bash
git add .
git commit -m "Add cloud deploy config"
git push origin main
```

### 5.2. Importar no Vercel

1. Acesse https://vercel.com
2. Import Project → Selecione repo
3. Configure Environment Variables:

| Variable | Value |
|----------|-------|
| `SUPABASE_URL` | `https://xxx.supabase.co` |
| `SUPABASE_ANON_KEY` | Sua anon key |
| `SUPABASE_SITE_URL` | `https://seu-feeddeck.vercel.app` |

4. Deploy → Aguardar build (~5-10 min)

### 5.3. Atualizar URLs no Supabase

No Supabase → Authentication → URL Configuration:
- Site URL: `https://seu-feeddeck.vercel.app`
- Redirect URLs: `https://seu-feeddeck.vercel.app/**`

---

## Pronto! 🎉

Acesse `https://seu-feeddeck.vercel.app` e crie sua conta!

---

## Próximos Passos (Opcional)

- **Domínio customizado:** Vercel → Settings → Domains
- **Configurar SMTP:** Supabase → Authentication → Email Templates
- **YouTube API:** Google Cloud Console → APIs & Services

---

## Troubleshooting

### Build falha no Vercel?
Verifique se `vercel.json` existe na raiz do projeto.

### Edge Functions não executam?
```bash
supabase secrets list  # Verificar se secrets foram aplicados
```

### Feeds não atualizam?
Verifique se o cron job foi criado:
```sql
SELECT * FROM cron.job;
```

---

## Documentação Completa

Para instruções detalhadas, consulte [DEPLOY_CLOUD.md](DEPLOY_CLOUD.md)

---

## Estrutura de Arquivos Criados

```
feeddeck/
├── vercel.json                    # Configuração Vercel
├── .vercelignore                  # Arquivos a ignorar
├── generate-keys.ps1              # Script gerador de chaves
├── DEPLOY_CLOUD.md                # Documentação completa
├── QUICKSTART.md                  # Este guia
└── supabase/
    └── .env.cloud.example         # Template de variáveis
```

---

## Limites Planos Gratuitos

| Serviço | Limite |
|---------|--------|
| **Supabase** | 500MB DB, 1GB storage, 2GB bandwidth/mês |
| **Vercel** | 100GB bandwidth/mês, builds ilimitados |
| **Upstash** | 10,000 comandos/dia |

Perfeito para uso pessoal! 🚀
