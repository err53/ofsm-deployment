# OpenFactorioServerManager Deployment

Some simple scripts to deploy [OFSM](https://github.com/OpenFactorioServerManager/factorio-server-manager) on [Fly](https://fly.io/).

Mostly based on OFSM's excellent [docker image](https://github.com/OpenFactorioServerManager/factorio-server-manager/tree/develop/docker).

## Prerequisites

- [flyctl](https://fly.io/docs/flyctl/install/)

## Usage

1. Clone this repository
2. Customize the `fly.toml` file to your liking
   (items of interest include `app`, `region`, `FACTORIO_VERSION`, and `[[vm]]` parameters)
3. Run `flyctl launch` in the repository directory

## Features

- [x] Tweaks to `Dockerfile` and `entrypoint.sh` to allow for proper statefulness on Fly
- [x] Automatic starting and stopping of OFSM
- [x] Caching of Factorio server executables
- [ ] Backups
