FROM ruby:2.5.5-stretch AS builder

# Install Mono
ENV MONO_VERSION 5.4.1.7
RUN apt-get update \
  && apt-get install -y gnupg \
  && APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
RUN echo "deb http://download.mono-project.com/repo/debian stretch/snapshots/$MONO_VERSION main" > /etc/apt/sources.list.d/mono-official.list \
  && apt-get update \
  && apt-get install -y mono-runtime binutils curl mono-devel ca-certificates-mono fsharp mono-vbnc nuget referenceassemblies-pcl \
  && rm -rf /var/lib/apt/lists/* /tmp/*

# Install Bundler 2 (Image come with v1)
RUN gem install bundler

WORKDIR /build

# Initialize bundle (gem) packages
COPY Gemfile Gemfile.lock ./
RUN bundle

# Initialize paket packages
COPY paket.dependencies paket.lock paket.exe ./
COPY .paket .paket
RUN mono paket.exe restore

ARG DRAFTS
ARG FUTURE

COPY . ./
RUN ./build.sh

FROM nginx
WORKDIR /site
COPY --from=builder /build/_site /usr/share/nginx/html