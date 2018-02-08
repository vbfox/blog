setlocal

echo "HI"
for /f "usebackq" %%i in (`git rev-parse --short HEAD`) do set GIT_HASH=%%i

echo X=%GIT_HASH%

rem docker build . -t vbfox/blog
rem docker build . --build-arg DRAFTS=yes --build-arg FUTURE=yes -t vbfox/blog:drafts

rem docker push vbfox/blog

rem kubectl apply -f k8s.yaml
rem kubectl apply -f k8s-drafts.yaml