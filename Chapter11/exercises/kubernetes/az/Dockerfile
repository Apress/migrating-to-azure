FROM microsoft/dotnet:2.1-runtime-alpine

RUN apk add --update --no-cache make gettext py-pip python-dev \
openssl openssl-dev libffi-dev zlib zlib-dev gcc g++ libunwind \
lttng-ust libcurl curl-dev curl bash libuuid krb5-libs icu icu-dev libunwind-dev
RUN pip install vsts-cli
RUN pip install azure-cli
# Install powershell core
# Download the powershell '.tar.gz' archive
RUN curl -L -o /tmp/powershell.tar.gz https://github.com/PowerShell/PowerShell/releases/download/v6.0.0/powershell-6.0.0-linux-x64.tar.gz
# Create the target folder where powershell will be placed
RUN mkdir -p /usr/local/pscore
# Expand powershell to the target folder
RUN tar zxf /tmp/powershell.tar.gz -C /usr/local/pscore
# Set execute permissions
RUN chmod +x /usr/local/pscore/pwsh
# Create the symbolic link that points to pwsh
RUN ln -s /usr/local/pscore/pwsh /usr/bin/pwsh

ENTRYPOINT [ "/bin/bash" ]
