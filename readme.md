# My blog

[![Build status](https://ci.appveyor.com/api/projects/status/f92nv0mkd85rxkjp/branch/master?svg=true)](https://ci.appveyor.com/project/vbfox/blog/branch/master)
[![CircleCI](https://circleci.com/gh/vbfox/blog/tree/master.svg?style=svg)](https://circleci.com/gh/vbfox/blog/tree/master)

Uses [Jekyll](https://jekyllrb.com) to generate [blog.vbfox.net](https://blog.vbfox.net).

## Building locally

* Install ruby 2.5
* `gem install bundler`
* `bundle`
* `dev.cmd`

## Building in Docker

Build and run (Will be accessible on [http://127.0.0.1:8080](http://127.0.0.1:8080))

```sh
docker build . -t vbfox/blog
docker run --name vbfox-blog -it --rm -p 127.0.0.1:8080:80 vbfox/blog
# Ctrl+C to kill the container

# To build with future & drafts
docker build . --build-arg DRAFTS=yes --build-arg FUTURE=yes -t vbfox/blog:drafts
```

# Uploading to the server

```sh
./build.cmd Upload
# Enter password for blog_upload
```