# My blog

[![Build status](https://ci.appveyor.com/api/projects/status/f92nv0mkd85rxkjp/branch/master?svg=true)](https://ci.appveyor.com/project/vbfox/blog/branch/master)
[![CircleCI](https://circleci.com/gh/vbfox/blog/tree/master.svg?style=svg)](https://circleci.com/gh/vbfox/blog/tree/master)

Uses [Jekyll](https://jekyllrb.com) to generate [blog.vbfox.net](https://blog.vbfox.net).

## Building locally

* Install ruby
* `bundle`
* `dev.cmd`

## Building in Docker

Build and run (Will be accessible on [http://127.0.0.1:8080](http://127.0.0.1:8080))

```bash
docker build . -t vbfox/blog
docker run --name vbfox-blog -it --rm -p 127.0.0.1:8080:80 vbfox/blog
# Ctrl+C to kill the container

# To build with future & drafts
docker build . --build-arg DRAFTS=yes --build-arg FUTURE=yes -t vbfox/blog:drafts
```

## Running in Kubernetes

```bash
# Push all images
docker push vbfox/blog

# On first run do a create & Wait for IP to appear
kubectl create -f k8s.yaml --save-config
kubectl get service vbfox-blog --watch

# Same for drafts
kubectl create -f k8s-drafts.yaml --save-config
kubectl get service vbfox-blog-drafts --watch

# Later settings changes can be simply applied
kubectl apply -f k8s.yaml
kubectl apply -f k8s-drafts.yaml
```
