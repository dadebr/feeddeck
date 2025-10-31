# ==============================================================================
# FeedDeck - Gerador de Chaves de Criptografia
# ==============================================================================
# Este script gera as chaves FEEDDECK_ENCRYPTION_KEY e FEEDDECK_ENCRYPTION_IV
# necessárias para o FeedDeck funcionar corretamente.
#
# USAGE:
#   .\generate-keys.ps1
#
# As chaves geradas serão exibidas no console e salvas em keys.txt
# ==============================================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FeedDeck - Gerador de Chaves" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Função para gerar string aleatória
function Generate-RandomString {
    param (
        [int]$Length = 32
    )

    $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    $random = New-Object System.Random
    $result = ""

    for ($i = 0; $i -lt $Length; $i++) {
        $result += $chars[$random.Next(0, $chars.Length)]
    }

    return $result
}

# Gerar chaves
Write-Host "Gerando chaves de criptografia..." -ForegroundColor Yellow
Write-Host ""

$encryptionKey = Generate-RandomString -Length 32
$encryptionIV = Generate-RandomString -Length 32

# Exibir chaves
Write-Host "CHAVES GERADAS COM SUCESSO!" -ForegroundColor Green
Write-Host ""
Write-Host "Copie estas chaves para o arquivo .env.cloud:" -ForegroundColor Cyan
Write-Host ""
Write-Host "FEEDDECK_ENCRYPTION_KEY=$encryptionKey" -ForegroundColor White
Write-Host "FEEDDECK_ENCRYPTION_IV=$encryptionIV" -ForegroundColor White
Write-Host ""

# Salvar em arquivo
$outputFile = "keys.txt"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$content = @"
========================================
FeedDeck - Chaves de Criptografia
Geradas em: $timestamp
========================================

IMPORTANTE: Mantenha estas chaves em segredo!
Estas chaves são usadas para criptografar tokens e dados sensíveis.

FEEDDECK_ENCRYPTION_KEY=$encryptionKey
FEEDDECK_ENCRYPTION_IV=$encryptionIV

========================================
PRÓXIMOS PASSOS:
========================================

1. Copie as chaves acima para o arquivo supabase/.env.cloud

2. Configure os secrets no Supabase:
   supabase secrets set --env-file supabase/.env.cloud

3. Configure as variáveis de ambiente no Vercel:
   - SUPABASE_URL
   - SUPABASE_ANON_KEY
   - SUPABASE_SITE_URL

4. Faça deploy no Vercel:
   vercel --prod

========================================
"@

$content | Out-File -FilePath $outputFile -Encoding UTF8

Write-Host "Chaves também foram salvas em: $outputFile" -ForegroundColor Yellow
Write-Host ""
Write-Host "ATENÇÃO: Mantenha este arquivo em local seguro!" -ForegroundColor Red
Write-Host "Não compartilhe estas chaves publicamente!" -ForegroundColor Red
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
