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

## Docker Tag


To tag the latest stabele build you can use `docker tag <repo/image> <repo/image:version>`:

```
docker tag smart48/smt-workspace smart48/smt-workspace:1.0
```

You will on listing then see the newly added version:

```
docker images |grep smt-workspace
smart48/smt-workspace          1.0          aaeffd791159   5 minutes ago   931MB
smart48/smt-workspace          latest       aaeffd791159   5 minutes ago   931MB
```
## Test

You can test the build image using:

```
docker run --name smt-workspace -d smart48/smt-workspace:latest
```

and enter using

```
docker exec -it smt-workspace bash
```

## Docker Push

And then to push the built image you run:

```
docker image push smart48/smt-workspace
```

if you did tag the image - and for production it is better to work with versioned images - you run the following:

```
docker image push smart48/smt-workspace:1.0
```