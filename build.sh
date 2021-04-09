set -e

REPO=hooklife/ocatane

function build_and_push(){
    ARGS="--build-arg SW_VERSION=v${SWOOLE_VERSION} --build-arg VERSION=${VERSION}"
	docker build ${ARGS} -t ${REPO}:8.0-swoole-${SWOOLE_VERSION}-${VERSION} --target main .
	docker build ${ARGS} -t ${REPO}:8.0-swoole-${SWOOLE_VERSION}-${VERSION}-dev --target dev .

    docker push ${REPO}:8.0-swoole-${SWOOLE_VERSION}-${VERSION}
    docker push ${REPO}:8.0-swoole-${SWOOLE_VERSION}-${VERSION}-dev
}

export SWOOLE_VERSION=4.6.4
export VERSION=0.0.1
build_and_push
