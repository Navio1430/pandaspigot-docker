## General Info
This image works as an extension to https://github.com/itzg/docker-minecraft-server (**itzg/minecraft-server:java17**). Image downloads **pandaspigot-1.8.8** jar from https://github.com/hpfxd/PandaSpigot and then sets it as the **custom engine**.

## Docs
For documentation refer to official **itzg/minecraft-server** image docs: https://docker-minecraft-server.readthedocs.io/en/latest/

## docker-compose.yml
```
version: '3.7'

services:
    minecraft:
        image: naviodev/pandaspigot:latest
        container_name: minecraft
        stdin_open: true
        tty: true
        restart: unless-stopped
        environment:
            EULA: "true"
        ports:
            - 25565:25565
        volumes:
            - pandaspigot:/data

volumes:
    pandaspigot: {}
```