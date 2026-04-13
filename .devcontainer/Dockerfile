ARG VARIANT=9.0-bookworm-slim
FROM mcr.microsoft.com/dotnet/sdk:${VARIANT}
ENV PATH $PATH:/home/vscode/.dotnet:/home/vscode/.dotnet/tools

# clear this environment variable so xml docs from NuGet packages are unpackaged. The default dotnet/sdk image sets it to 'skip'.
# see https://github.com/dotnet/dotnet-docker/issues/2790
ENV NUGET_XMLDOC_MODE=

# Install PowerShell 7.5.5
RUN if [ "$(dpkg --print-architecture)" = "amd64" ]; then \
        apt-get update && \
        apt-get install -y wget && \
        POWERSHELL_FILE_NAME="powershell_7.5.5-1.deb_amd64.deb" && \
        wget https://github.com/PowerShell/PowerShell/releases/download/v7.5.5/${POWERSHELL_FILE_NAME} && \
        dpkg -i ${POWERSHELL_FILE_NAME} && \
        apt-get install -f && \
        rm ${POWERSHELL_FILE_NAME} ; \
    fi

RUN if [ "$(dpkg --print-architecture)" = "arm64" ]; then \
        apt-get update && \
        apt-get install -y curl tar && \
        POWERSHELL_FILE_PATH="/opt/microsoft/powershell/7" && \
        curl -L -o /tmp/powershell.tar.gz https://github.com/PowerShell/PowerShell/releases/download/v7.5.5/powershell-7.5.5-linux-arm64.tar.gz && \
        mkdir -p ${POWERSHELL_FILE_PATH} && \
        tar zxf /tmp/powershell.tar.gz -C ${POWERSHELL_FILE_PATH} && \
        chmod +x ${POWERSHELL_FILE_PATH}/pwsh && \
        ln -snf ${POWERSHELL_FILE_PATH}/pwsh /usr/bin/pwsh && \
        rm /tmp/powershell.tar.gz ; \
    fi
