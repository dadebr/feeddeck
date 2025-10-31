# FeedDeck - Instalação no Windows

Guia específico para configurar todas as ferramentas necessárias no Windows.

## 📦 Ferramentas Necessárias

### 1. Node.js (Obrigatório)

**Verificar se já está instalado:**
```powershell
node --version
```

**Se não estiver instalado:**
- Download: https://nodejs.org/
- Escolha a versão LTS
- Instale e reinicie o terminal

---

### 2. Supabase CLI (Obrigatório)

**❌ NÃO USAR:** `npm install -g supabase` (não funciona mais)

**✅ Use UMA das opções abaixo:**

#### Opção A: Scoop (Recomendado - Mais Fácil)

**1. Instalar o Scoop (se não tiver):**
```powershell
# Abrir PowerShell como Administrador
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
```

**2. Instalar Supabase CLI:**
```powershell
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase
```

**3. Verificar:**
```powershell
supabase --version
```

---

#### Opção B: Chocolatey

**1. Verificar se tem Chocolatey:**
```powershell
choco --version
```

**2. Se não tiver, instalar Chocolatey:**
```powershell
# Abrir PowerShell como Administrador
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

**3. Instalar Supabase CLI:**
```powershell
choco install supabase
```

**4. Verificar:**
```powershell
supabase --version
```

---

#### Opção C: Winget (Windows 10/11)

**Winget já vem instalado no Windows 10 (build 1809+) e Windows 11**

```powershell
winget install Supabase.supabase-cli
```

**Verificar:**
```powershell
supabase --version
```

---

#### Opção D: Via NPX (Sem Instalar)

Se nenhuma opção acima funcionar, use `npx`:

```bash
# Substituir todos os comandos supabase por npx supabase
npx supabase login
npx supabase link --project-ref SEU_REF
npx supabase db push
```

---

### 3. Flutter SDK (Necessário apenas para build local)

**Verificar se já está instalado:**
```powershell
flutter --version
```

**Se não estiver instalado:**
1. Download: https://docs.flutter.dev/get-started/install/windows
2. Extrair para `C:\src\flutter`
3. Adicionar ao PATH:
   - Painel de Controle → Sistema → Configurações Avançadas
   - Variáveis de Ambiente → Path → Editar
   - Adicionar: `C:\src\flutter\bin`
4. Reiniciar terminal
5. Executar: `flutter doctor`

**Nota:** Se for fazer deploy apenas no Vercel, o Flutter não precisa estar instalado localmente (Vercel faz o build na cloud).

---

### 4. Git (Obrigatório)

**Verificar se já está instalado:**
```powershell
git --version
```

**Se não estiver instalado:**
- Download: https://git-scm.com/download/win
- Instale com configurações padrão

---

## 🚀 Comandos Iniciais

Após instalar as ferramentas, execute:

### 1. Fazer Login no Supabase

```powershell
supabase login
```

Isso abrirá o navegador para autenticação.

### 2. Navegar até o projeto

```powershell
cd c:\Users\luize\OneDrive\Desenvolvimento\feeddeck
```

### 3. Gerar chaves de criptografia

```powershell
.\generate-keys.ps1
```

### 4. Configurar variáveis de ambiente

```powershell
cd supabase
cp .env.cloud.example .env.cloud
notepad .env.cloud  # Edite com suas credenciais
```

### 5. Linkar projeto Supabase

```powershell
supabase link --project-ref SEU_PROJECT_REF
```

### 6. Aplicar migrações

```powershell
supabase db push
```

---

## 🔧 Troubleshooting Windows

### Erro: "Execution Policy"

```powershell
# Executar PowerShell como Administrador
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Erro: "comando não reconhecido"

Após instalar qualquer ferramenta:
1. Feche todos os terminais abertos
2. Abra um novo terminal
3. Tente novamente

### Erro: PATH não atualizado

1. Painel de Controle → Sistema → Configurações Avançadas
2. Variáveis de Ambiente
3. Verifique se o caminho da ferramenta está no PATH
4. Reinicie o computador

### Permissões Negadas

Execute o PowerShell como **Administrador**:
- Clique direito no ícone do PowerShell
- "Executar como Administrador"

---

## 📚 Resumo de Instalação Rápida

Para instalar tudo de uma vez (usando Scoop):

```powershell
# 1. Instalar Scoop
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression

# 2. Instalar Git
scoop install git

# 3. Instalar Node.js
scoop install nodejs-lts

# 4. Instalar Supabase CLI
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase

# 5. Verificar instalações
node --version
git --version
supabase --version
```

---

## 🎯 Próximos Passos

Após instalar tudo, siga o guia:
- **Rápido:** [QUICKSTART.md](QUICKSTART.md)
- **Completo:** [DEPLOY_CLOUD.md](DEPLOY_CLOUD.md)

---

## ❓ Ajuda

- **Scoop:** https://scoop.sh/
- **Chocolatey:** https://chocolatey.org/
- **Supabase CLI:** https://github.com/supabase/cli
- **Flutter Windows:** https://docs.flutter.dev/get-started/install/windows
