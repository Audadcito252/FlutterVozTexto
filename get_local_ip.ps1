# Script para obtener tu IP local
# Ejecuta: .\get_local_ip.ps1

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "  OBTENIENDO IP LOCAL" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Obtener todas las IPs IPv4
$ips = Get-NetIPAddress -AddressFamily IPv4 | 
    Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.*" } |
    Select-Object IPAddress, InterfaceAlias

if ($ips.Count -eq 0) {
    Write-Host "❌ No se encontraron IPs locales" -ForegroundColor Red
    Write-Host ""
    Write-Host "Verifica tu conexión de red" -ForegroundColor Yellow
    exit
}

Write-Host "📡 IPs encontradas:" -ForegroundColor Green
Write-Host ""

foreach ($ip in $ips) {
    Write-Host "  Interface: $($ip.InterfaceAlias)" -ForegroundColor Yellow
    Write-Host "  IP: $($ip.IPAddress)" -ForegroundColor White
    Write-Host "  URL para Flutter: http://$($ip.IPAddress):8000" -ForegroundColor Cyan
    Write-Host ""
}

# Obtener la IP principal (usualmente la WiFi o Ethernet)
$mainIp = $ips | Where-Object { $_.InterfaceAlias -like "*Wi-Fi*" -or $_.InterfaceAlias -like "*Ethernet*" } | Select-Object -First 1

if ($mainIp) {
    Write-Host "==================================" -ForegroundColor Cyan
    Write-Host "✅ IP RECOMENDADA PARA USAR:" -ForegroundColor Green
    Write-Host "   $($mainIp.IPAddress)" -ForegroundColor White
    Write-Host ""
    Write-Host "📝 Configura en lib/services/api_service.dart:" -ForegroundColor Yellow
    Write-Host "   static const String baseUrl = 'http://$($mainIp.IPAddress):8000';" -ForegroundColor White
    Write-Host "==================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Copiar al portapapeles si es posible
    try {
        "http://$($mainIp.IPAddress):8000" | Set-Clipboard
        Write-Host "📋 URL copiada al portapapeles!" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  No se pudo copiar al portapapeles" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  Usa la IP de tu interfaz de red principal" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔍 Para verificar que el backend sea accesible:" -ForegroundColor Yellow
Write-Host "   curl http://$($mainIp.IPAddress):8000/health" -ForegroundColor White
Write-Host ""
