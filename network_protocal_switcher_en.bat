@echo off
net session >nul 2>&1 || (echo Please Run as Admin & pause & exit)
cd /d "%~dp0"
setlocal enabledelayedexpansion

:ADAPTER_PICK
cls
echo ============================================
echo           Network Protocol Tool
echo ============================================
echo  Active Adapters:
echo --------------------------------------------
powershell -Command "Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | Select-Object Name, Status"
echo --------------------------------------------
echo.
set /p adapter=Enter Adapter Name: 

powershell -Command "Get-NetAdapterBinding -Name '%adapter%'" >nul 2>&1 || (echo Error: Invalid Name & timeout /t 3 >nul & goto ADAPTER_PICK)

:MENU
cls
for /f %%a in ('powershell -Command "(Get-NetAdapterBinding -Name '%adapter%' -ComponentID ms_tcpip).Enabled"') do set v4=%%a
for /f %%b in ('powershell -Command "(Get-NetAdapterBinding -Name '%adapter%' -ComponentID ms_tcpip6).Enabled"') do set v6=%%b

echo Target: %adapter%  Mode: v4=%v4% v6=%v6%
echo ============================================
echo  1. Dual Stack (v4+v6 Auto)
echo  2. IPv4 Only (Disable v6)
echo  3. IPv6 Only (Disable v4 + DNS)
echo  4. Reset Stack
echo  5. Reselect Adapter
echo  6. Exit
echo ============================================
set /p choice=Select (1-6): 

if "%choice%"=="1" goto DUAL
if "%choice%"=="2" goto V4ONLY
if "%choice%"=="3" goto V6ONLY
if "%choice%"=="4" goto RESET
if "%choice%"=="5" goto ADAPTER_PICK
if "%choice%"=="6" exit
goto MENU

:DUAL
powershell -Command "Enable-NetAdapterBinding -Name '%adapter%' -ComponentID ms_tcpip";"Enable-NetAdapterBinding -Name '%adapter%' -ComponentID ms_tcpip6"
netsh interface ipv4 set address "%adapter%" dhcp
netsh interface ipv4 set dns "%adapter%" dhcp
netsh interface ipv6 set address "%adapter%" dhcp
netsh interface ipv6 set dns "%adapter%" dhcp
goto SUCCESS

:V4ONLY
powershell -Command "Enable-NetAdapterBinding -Name '%adapter%' -ComponentID ms_tcpip";"Disable-NetAdapterBinding -Name '%adapter%' -ComponentID ms_tcpip6"
goto SUCCESS

:V6ONLY
set "def_dns=2a01:4f8:c2c:123f::1"
set /p u_dns=DNS (Enter for %def_dns%): 
if "!u_dns!"=="" set "u_dns=%def_dns%"
powershell -Command "Disable-NetAdapterBinding -Name '%adapter%' -ComponentID ms_tcpip";"Enable-NetAdapterBinding -Name '%adapter%' -ComponentID ms_tcpip6"
netsh interface ipv6 set address "%adapter%" dhcp
netsh interface ipv6 set dns "%adapter%" static !u_dns! primary
goto SUCCESS

:RESET
netsh int ip reset & netsh int ipv6 reset & ipconfig /flushdns
goto SUCCESS

:SUCCESS
echo Done. Returning to menu...
timeout /t 5 >nul
goto MENU