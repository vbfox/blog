FROM ruby:2.7.8-bullseye AS base

# Install .NET CLI dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libc6 \
        libgcc1 \
        libgssapi-krb5-2 \
        liblttng-ust0 \
        libstdc++6 \
        zlib1g \
    && rm -rf /var/lib/apt/lists/*

# Install .NET Core SDK
ENV DOTNET_SDK_VERSION=9.0.201

RUN curl -SL --output dotnet.tar.gz https://dotnetcli.blob.core.windows.net/dotnet/Sdk/$DOTNET_SDK_VERSION/dotnet-sdk-$DOTNET_SDK_VERSION-linux-x64.tar.gz \
    && dotnet_sha512='93a8084ef38da810c3c96504c20ea2020a6b755b73a19f7acc6cd73a8b62ace0adda14452d11e6458f73dc7d58ffad22fcd151f111d2320cb23a10fd54dcb772' \
    && echo "dotnet.tar.gz" | sha512sum - \
    && echo "$dotnet_sha512 dotnet.tar.gz" | sha512sum -c - \
    && mkdir -p /usr/share/dotnet \
    && tar -zxf dotnet.tar.gz -C /usr/share/dotnet \
    && rm dotnet.tar.gz \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet

# Configure web servers to bind to port 80 when present
ENV ASPNETCORE_URLS=http://+:80 \
    # Enable detection of running in a container
    DOTNET_RUNNING_IN_CONTAINER=true \
    # Enable correct mode for dotnet watch (only mode supported in a container)
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    # Skip extraction of XML docs - generally not useful within an image/container - helps performance
    NUGET_XMLDOC_MODE=skip

# Trigger first run experience by running arbitrary cmd to populate local package cache
RUN dotnet help

# Install Bundler 2 (Image come with v1)
RUN gem install bundler -v 2.4.22

WORKDIR /build

# Initialize bundle (gem) packages
COPY Gemfile Gemfile.lock ./
RUN bundle

# Initialize nuget packages
COPY build/global.json build/build.fsproj ./build/
RUN cd build && dotnet restore build.fsproj

FROM base AS builder

ARG DRAFTS
ARG FUTURE

COPY . ./
RUN ./build.sh

FROM nginx AS server
WORKDIR /site
COPY --from=builder /build/_site /usr/share/nginx/html
