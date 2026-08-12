# Azeroth Core on Containerd

Azeroth Core with Playerbots running on rootless containerd

Adopted from [docker installation](https://github.com/mod-playerbots/mod-playerbots/wiki/Installation-Guide#docker-installation)

## Build 

### Clone the repositories:

```
git clone https://github.com/mod-playerbots/azerothcore-wotlk.git --branch=Playerbot
cd azerothcore-wotlk/modules
git clone https://github.com/mod-playerbots/mod-playerbots.git --branch=master
cd ..
```

Copy this `docker-compose.override.yaml` into your cloned `azerothcore-wotlk/`

### File permissions

Create `.env`:

```
DOCKER_USER_ID=1000
DOCKER_GROUP_ID=1000
```

Then set ownership on container volume dir `./env/`

`sudo chown -$ 100999:100999 ./env/`

### Build

`nerdctl compose build`


## Deploy


1. Start the DB first, wait, then bring up the rest:

    `nerdctl compose up -d ac-database`

2. Run db-import as a one-shot before the servers:

    `nerdctl compose run --rm ac-db-import`

3. Start auth server

    `nerdctl compose up -d ac-authserver`

4. Run worldserver Interactively (account creation / admin console)

    `nerdctl compose run --rm ac-worldserver`

5. Run worldserver detached

    `nerdctl compose up -d worldserver`

  > It show a mysql connection error on first start up, check to see if container has restarted after
  a few seconds

## Config and Chat commands

[recommended-config](https://github.com/mod-playerbots/mod-playerbots/wiki/Playerbot-Configuration#recommended-config)

[chat commands](https://github.com/mod-playerbots/mod-playerbots/wiki/Playerbot-Commands)


