FROM ruby:2.5.5-stretch AS builder

# Install .NET CLI dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libc6 \
        libgcc1 \
        libgssapi-krb5-2 \
        libicu57 \
        liblttng-ust0 \
        libssl1.0.2 \
        libstdc++6 \
        zlib1g \
    && rm -rf /var/lib/apt/lists/*

# Install .NET Core SDK
ENV DOTNET_SDK_VERSION 2.2.106

RUN curl -SL --output dotnet.tar.gz https://dotnetcli.blob.core.windows.net/dotnet/Sdk/$DOTNET_SDK_VERSION/dotnet-sdk-$DOTNET_SDK_VERSION-linux-x64.tar.gz \
    && dotnet_sha512='cf1cf0cd909bd622b623a6bb96adba705dd0daa217ea8a791e3c6d932f3ded24d28802609498fac20c15ad587d1dc2cf16c1607af1c7b0cddeba02fbaefedc53' \
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
RUN gem install bundler

WORKDIR /build

# Initialize bundle (gem) packages
COPY Gemfile Gemfile.lock ./
RUN bundle

# Initialize nuget packages
COPY build.fsproj ./
RUN dotnet restore build.fsproj

ARG DRAFTS
ARG FUTURE

COPY . ./
RUN ./build.sh

FROM nginx
WORKDIR /site
COPY --from=builder /build/_site /usr/share/nginx/html