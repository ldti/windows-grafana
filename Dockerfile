# escape=`
ARG WindowsServerCoreVersion
ARG GRAFANA_VERSION
ARG GRAFANA_SHA256

FROM mcr.microsoft.com/windows/servercore:$WindowsServerCoreVersion AS installer
ARG GRAFANA_VERSION=$GRAFANA_VERSION
ARG GRAFANA_SHA256=$GRAFANA_SHA256
ARG WindowsServerCoreVersion=$WindowsServerCoreVersion
ENV GRAFANA_VERSION $GRAFANA_VERSION
ENV GRAFANA_SHA256 $GRAFANA_SHA256
ENV POWERSHELL_VERSION 6.1.3
ENV POWERSHELL_SHA256 AA01A6F11C76BBD3786E274DD65F2C85FF28C08B2D778A5FC26127DFEC5E67B3

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
RUN [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 ; `
	New-Item -ItemType Directory -Force -Path C:\webdownload | Out-Null; `
    Invoke-WebRequest $('https://dl.grafana.com/oss/release/grafana-{0}.windows-amd64.zip' -f $env:GRAFANA_VERSION) -OutFile 'C:\webdownload\grafana.zip' -UseBasicParsing; `
	if ((Get-FileHash C:\webdownload\grafana.zip -Algorithm sha256).Hash -ne $env:GRAFANA_SHA256) { Write-Error 'GRAFANA SHA256 mismatch';exit 1 } `
    Invoke-WebRequest $('https://github.com/PowerShell/PowerShell/releases/download/v{0}/PowerShell-{0}-win-x64.zip' -f $env:POWERSHELL_VERSION) -OutFile 'C:\webdownload\powershellCore.zip' -UseBasicParsing; `
	if ((Get-FileHash C:\webdownload\powershellCore.zip -Algorithm sha256).Hash -ne $env:POWERSHELL_SHA256) { Write-Error 'Powershell SHA256 mismatch';exit 1 } `	
	Expand-Archive C:\webdownload\grafana.zip -DestinationPath C:\grafana; `
	Expand-Archive C:\webdownload\powershellCore.zip -DestinationPath C:\PowerShell;

FROM mcr.microsoft.com/windows/nanoserver:$WindowsServerCoreVersion AS base
ARG GRAFANA_VERSION=$GRAFANA_VERSION
ARG WindowsServerCoreVersion=$WindowsServerCoreVersion
COPY --from=installer ["C:/PowerShell/", "C:/Program Files/PowerShell"]
COPY --from=installer ["C:/grafana/grafana-${GRAFANA_VERSION}/", "C:/Program Files/Grafana"]
# In order to set system PATH, ContainerAdministrator must be used
USER ContainerAdministrator 
RUN setx /M PATH "%PATH%%ProgramFiles%\PowerShell;"
USER ContainerUser

EXPOSE 3000
WORKDIR "Program Files/Grafana"
ENTRYPOINT [ "bin\\grafana-server.exe" ]
HEALTHCHECK --interval=5m `
 CMD pwsh -NoLogo -NonInteractive -NoProfile -Command `
    try { `
     if (((Invoke-RestMethod -Method Get -UseBasicParsing -Uri http://localhost:3000/api/health).database) -eq 'ok') { exit 0 } `
     else { exit 1 }; `
    } catch { exit 1 }
LABEL grafana.version="$GRAFANA_VERSION" `
grafana.license="https://github.com/grafana/grafana/blob/master/LICENSE.md" `
windows.version="$WindowsServerCoreVersion"