# Script PowerShell para configurar Windows Server para Ansible con comprobaciones

# **Función para verificar si WinRM está habilitado**

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Is-WinRMEnabled {
    $winrmStatus = winrm get winrm/config/service 2>&1
    return $winrmStatus -notmatch "WinRM service is not running"
}

# **Función para verificar si el listener HTTP existe**
function Is-ListenerConfigured {
    $listener = winrm enumerate winrm/config/listener | Select-String "Transport=HTTP"
    return $listener -ne $null
}

# **Función para verificar la regla del firewall**
function Is-FirewallRuleExists {
    $rule = Get-NetFirewallRule -DisplayName "Permitir WinRM HTTP" -ErrorAction SilentlyContinue
    return $rule -ne $null
}

# **1. Habilitar WinRM si no está habilitado**
Write-Output "Verificando WinRM..."
if (-not (Is-WinRMEnabled)) {
    Write-Output "WinRM no está habilitado. Configurando WinRM..."
    winrm quickconfig -force
} else {
    Write-Output "WinRM ya está habilitado."
}

# **2. Configurar WinRM para permitir conexiones no cifradas y autenticación básica**
Write-Output "Configurando opciones WinRM..."
$winrmConfig = winrm get winrm/config/service
if ($winrmConfig -notmatch "AllowUnencrypted = true") {
    winrm set winrm/config/service '@{AllowUnencrypted="true"}'
    Write-Output "Permitir conexiones no cifradas habilitado."
} else {
    Write-Output "Conexiones no cifradas ya están permitidas."
}

if ($winrmConfig -notmatch "Basic = true") {
    winrm set winrm/config/service/Auth '@{Basic="true"}'
    Write-Output "Autenticación básica habilitada."
} else {
    Write-Output "Autenticación básica ya está habilitada."
}

# **3. Configurar listener HTTP si no existe**
Write-Output "Verificando listener HTTP..."
if (-not (Is-ListenerConfigured)) {
    Write-Output "Listener HTTP no encontrado. Creando listener..."
    winrm create winrm/config/Listener?Address=*+Transport=HTTP
} else {
    Write-Output "Listener HTTP ya existe."
}

# **4. Configurar firewall si no existe la regla**
Write-Output "Configurando firewall..."
if (-not (Is-FirewallRuleExists)) {
    Write-Output "Regla del firewall no encontrada. Creando regla..."
    New-NetFirewallRule -Name "WinRM HTTP" -DisplayName "Permitir WinRM HTTP" `
        -Protocol TCP -LocalPort 5985 -Action Allow -Direction Inbound
} else {
    Write-Output "Regla del firewall ya existe."
}

# **5. Habilitar PowerShell Remoting**
Write-Output "Verificando PowerShell Remoting..."
$psRemoting = Get-PSRemotingConfiguration 2>&1
if ($psRemoting -match "Disabled") {
    Write-Output "PowerShell Remoting deshabilitado. Habilitando..."
    Enable-PSRemoting -Force
} else {
    Write-Output "PowerShell Remoting ya está habilitado."
}

# **6. Configurar ejecución de scripts**
Write-Output "Configurando política de ejecución de scripts..."
$currentPolicy = Get-ExecutionPolicy
if ($currentPolicy -ne "RemoteSigned") {
    Set-ExecutionPolicy RemoteSigned -Force
    Write-Output "Política cambiada a RemoteSigned."
} else {
    Write-Output "Política RemoteSigned ya está configurada."
}

# **7. Verificar configuración WinRM**
Write-Output "Verificando configuración WinRM final..."
winrm quickconfig
winrm enumerate winrm/config/listener

# **8. Comprobar conectividad en el puerto 5985**
Write-Output "Probando conectividad en el puerto 5985..."
Test-NetConnection -ComputerName localhost -Port 5985

Write-Output "Configuración completada. WinRM está listo para Ansible."
