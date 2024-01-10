# from: https://github.com/microsoft/vscode-dev-containers/blob/14b53bf68f467dc6fe1a1a378ba10b9db9e6d318/containers/dotnet/.devcontainer/Dockerfile
# and: https://github.com/microsoft/vscode-dev-containers/blob/main/containers/powershell/.devcontainer/Dockerfile

ARG DOTNET_VARIANT=6.0-bullseye
FROM mcr.microsoft.com/vscode/devcontainers/dotnet:0-${DOTNET_VARIANT}

ARG INSTALL_ZSH="true"
ARG UPGRADE_PACKAGES="true"

# Install needed packages and setup non-root user. Use a separate RUN statement to add your own dependencies.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
COPY library-scripts/*.sh /tmp/library-scripts/
RUN apt-get update \
    && /bin/bash /tmp/library-scripts/common-debian.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" "true" "true" \
    && chsh "${USERNAME}" -s "$(which pwsh)" \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts

# Download the latest stable `nuget.exe` to `/usr/local/bin`
RUN curl -o /usr/local/bin/nuget.exe https://dist.nuget.org/win-x86-commandline/latest/nuget.exe
RUN chmod +x /usr/local/bin/nuget.exe


# [Optional] Uncomment this section to install additional packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>
