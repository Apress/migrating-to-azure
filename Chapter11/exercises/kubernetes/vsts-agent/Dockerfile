FROM microsoft/vsts-agent

RUN apt-get update

RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
RUN mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
RUN sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-xenial-prod xenial main" > /etc/apt/sources.list.d/dotnetdev.list'
RUN apt-get install apt-transport-https -y
RUN apt-get update
RUN apt-get install mono-complete nodejs npm dotnet-sdk-2.1.104 -y
# Export the sha256sum for verification.
ENV IMG_SHA256="dad4cec955803d3e8f42b9348c3ae25ee5fca73369364cd4419f77ec1e713040"
# Download and check the sha256sum.
RUN curl -fSL "https://github.com/genuinetools/img/releases/download/v0.4.7/img-linux-amd64" -o "/usr/local/bin/img" \
	&& echo "${IMG_SHA256}  /usr/local/bin/img" | sha256sum -c - \
	&& chmod a+x "/usr/local/bin/img"
RUN echo "img installed!"
