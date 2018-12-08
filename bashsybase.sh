#!/bin/bash
docker stop sybase
docker rm sybase
#IMAGE_NAME=datagrip/sybase
IMAGE_NAME=sybase
docker volume create --driver local \
    --opt type=xfs \
    --opt device=/dev/xvdg \
    sybase-data
#docker volume create sybase-data
docker run --rm -ti -p 5000:5000 \
	-v $(pwd):/opt/dados \
	-v sybase-data:/opt/sybase/data/ \
	-v /dump:/dump \
	--entrypoint "bash" \
	$IMAGE_NAME
