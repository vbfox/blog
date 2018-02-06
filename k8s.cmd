docker build . -t vbfox/blog
docker build . --build-arg DRAFTS=yes --build-arg FUTURE=yes -t vbfox/blog:drafts

docker push vbfox/blog

kubectl apply -f k8s.yaml
kubectl apply -f k8s-drafts.yaml