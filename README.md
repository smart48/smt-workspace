# Workspace

Based on Laradock Workspace

- PHP 7.4
- composer
- ssh


## SSH

Keys needed to access Workspace from the terminal. Not sure why we would need to copy the private key yet. Also, if we want this image to stay public we cannot built with private keys.

## Crontabs

Could be added like in original but now we use crontab job. There is also PHP Worker with supervisord.

## Docker Build

To build for our own Smart48 Docker Hub repository we use

```
docker build . -t smart48/smt-workspace
```

This will build with the tag using our organization's name and name for the image.

## Test

You can test the build image using:

```
docker run --name smt-workspace -d smart48/smt-workspace:latest
```

## Docker Push

And then to push the built image you run:

```
docker image push smart48/smt-workspace
```