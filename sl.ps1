# Requiere privilegios de administrador para acceder a información de IIS
Import-Module WebAdministration

Write-Host "===== INFORMACIÓN DEL SISTEMA =====" -ForegroundColor Cyan

# RAM
$ram = Get-CimInstance Win32_OperatingSystem
$ramTotal = [math]::Round($ram.TotalVisibleMemorySize / 1MB, 2)
$ramLibre = [math]::Round($ram.FreePhysicalMemory / 1MB, 2)
Write-Host "`n[ RAM ]"
Write-Host "Total: $ramTotal GB"
Write-Host "Libre: $ramLibre GB"

# CPU
$cpu = Get-CimInstance Win32_Processor
Write-Host "`n[ PROCESADOR ]"
foreach ($c in $cpu) {
    Write-Host "Nombre: $($c.Name)"
    Write-Host "Núcleos: $($c.NumberOfCores)"
    Write-Host "Hilos: $($c.NumberOfLogicalProcessors)"
    Write-Host "Velocidad: $($c.MaxClockSpeed) MHz"
}

# Discos
$discos = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
Write-Host "`n[ DISCOS DUROS ]"
foreach ($d in $discos) {
    $total = [math]::Round($d.Size / 1GB, 2)
    $libre = [math]::Round($d.FreeSpace / 1GB, 2)
    Write-Host "$($d.DeviceID): Total: $total GB - Libre: $libre GB - Sistema de Archivos: $($d.FileSystem)"
}

# Información IIS
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

Write-Host "`n===== INFORME COMPLETO FINALIZADO =====" -ForegroundColor Green
