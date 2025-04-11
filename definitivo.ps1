# Script de PowerShell SOLO DE LECTURA - No modifica archivos ni configuraciones
# Requiere privilegios de administrador para acceder a IIS y WMI

Import-Module WebAdministration

Write-Host "`n===== INFORMACIÓN DEL SISTEMA =====" -ForegroundColor Cyan

# RAM
$ram = Get-WmiObject Win32_OperatingSystem
$ramTotal = [math]::Round($ram.TotalVisibleMemorySize / 1MB, 2)
$ramLibre = [math]::Round($ram.FreePhysicalMemory / 1MB, 2)
Write-Host "`n[ RAM ]"
Write-Host "Total: $ramTotal GB"
Write-Host "Libre: $ramLibre GB"

# CPU
$cpu = Get-WmiObject Win32_Processor
Write-Host "`n[ PROCESADOR ]"
foreach ($c in $cpu) {
    Write-Host "Nombre: $($c.Name)"
    Write-Host "Núcleos: $($c.NumberOfCores)"
    Write-Host "Hilos: $($c.NumberOfLogicalProcessors)"
    Write-Host "Velocidad: $($c.MaxClockSpeed) MHz"
}

# Discos
$discos = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
Write-Host "`n[ DISCOS DUROS ]"
foreach ($d in $discos) {
    $total = [math]::Round($d.Size / 1GB, 2)
    $libre = [math]::Round($d.FreeSpace / 1GB, 2)
    Write-Host "$($d.DeviceID): Total: $total GB - Libre: $libre GB - Sistema de Archivos: $($d.FileSystem)"
}

# IIS: Pools, Apps, Sitios
Write-Host "`n===== IIS: POOLS, APLICACIONES Y SITIOS =====" -ForegroundColor Cyan

# Application Pools
$appPools = Get-ChildItem IIS:\AppPools
Write-Host "`n[ APPLICATION POOLS ]"
foreach ($pool in $appPools) {
    Write-Host "Nombre: $($pool.Name) - Estado: $($pool.State)"
}

# Sitios Web y Aplicaciones
$sites = Get-ChildItem IIS:\Sites
Write-Host "`n[ SITIOS WEB Y APLICACIONES ]"
foreach ($site in $sites) {
    Write-Host "`nSitio: $($site.Name)"
    Write-Host "  Estado: $($site.State)"
    Write-Host "  Bindings:"
    foreach ($binding in $site.Bindings.Collection) {
        Write-Host "    - $($binding.Protocol)://$($binding.BindingInformation)"
    }

    Write-Host "  Aplicaciones:"
    $apps = Get-WebApplication -Site $site.Name
    foreach ($app in $apps) {
        Write-Host "    - Ruta: $($app.Path)"
        Write-Host "      Pool de Aplicación: $($app.ApplicationPool)"
        Write-Host "      Ruta Física: $($app.PhysicalPath)"
    }
}

# Búsqueda de directorios 'log' o 'logs' (en cualquier combinación de mayúsculas/minúsculas) en E:\
Write-Host "`n===== BÚSQUEDA DE DIRECTORIOS 'log' Y 'logs' EN E:\ =====" -ForegroundColor Cyan

if (Test-Path "E:\") {
    try {
        $logsDirs = Get-ChildItem -Path "E:\" -Recurse -Directory -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -match '^(?i)logs?$' }  # log o logs, case-insensitive
        
        if ($logsDirs.Count -gt 0) {
            foreach ($dir in $logsDirs) {
                Write-Host "Directorio encontrado: $($dir.FullName)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "No se encontraron directorios llamados 'log' o 'logs' en E:\" -ForegroundColor Gray
        }
    } catch {
        Write-Host "Error al buscar en E:\ $_" -ForegroundColor Red
    }
} else {
    Write-Host "La unidad E:\ no está disponible." -ForegroundColor Red
}

# Mostrar todos los servicios de Windows
Write-Host "`n===== SERVICIOS DE WINDOWS =====" -ForegroundColor Cyan
try {
    $servicios = Get-Service | Sort-Object Status, DisplayName
    foreach ($s in $servicios) {
        Write-Host "$($s.Status) - $($s.DisplayName) ($($s.Name))"
    }
} catch {
    Write-Host "Error al obtener los servicios: $_" -ForegroundColor Red
}

Write-Host "`n===== INFORME COMPLETO FINALIZADO =====" -ForegroundColor Green
