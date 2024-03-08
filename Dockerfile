#########################################################################
# This docker image is based on the felixklauke paper-docker repository #
# https://github.com/felixklauke/paper-docker                           #
#########################################################################

###########################
### Running environment ###
###########################
FROM debian:buster-slim as build

###################################
### Maintained by Oliwier Fijas ###
### Contact: naviodev@gmail.com ###
###################################
LABEL maintainer="Oliwier Fijas <naviodev@gmail.com>"

ARG version=17.0.10.7-1
# In addition to installing the Amazon corretto, we also install
# fontconfig. The folks who manage the docker hub's
# official image library have found that font management
# is a common usecase, and painpoint, and have
# recommended that Java images include font support.
#
# See:
#  https://github.com/docker-library/official-images/blob/master/test/tests/java-uimanager-font/container.java

RUN set -eux \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    curl ca-certificates gnupg software-properties-common fontconfig java-common \
    && curl -fL https://apt.corretto.aws/corretto.key | apt-key add - \
    && add-apt-repository 'deb https://apt.corretto.aws stable main' \
    && mkdir -p /usr/share/man/man1 || true \
    && apt-get update \
    && apt-get install -y java-17-amazon-corretto-jdk=1:$version \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    curl gnupg software-properties-common

ENV LANG C.UTF-8
ENV JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto

ARG MINECRAFT_BUILD_USER=minecraft-build
ENV MINECRAFT_BUILD_PATH=/opt/minecraft

#########################
### Working directory ###
#########################
WORKDIR ${MINECRAFT_BUILD_PATH}

############################
### Download pandaspigot ###
############################
ARG PANDA_DOWNLOAD_URL="https://nightly.link/hpfxd/PandaSpigot/workflows/build/master/Server%20JAR.zip"

RUN apt-get update && apt-get install -y unzip curl \
    && curl -L ${PANDA_DOWNLOAD_URL} -o server.zip \
    && unzip server.zip '*.jar' \
    && mv *.jar paper.jar \
    && rm server.zip

############
### User ###
############
RUN adduser ${MINECRAFT_BUILD_USER} --shell /bin/bash --system && \
    chown ${MINECRAFT_BUILD_USER} ${MINECRAFT_BUILD_PATH} -R

USER ${MINECRAFT_BUILD_USER}

############################################
### Run paperclip and obtain patched jar ###
############################################
RUN java -jar ${MINECRAFT_BUILD_PATH}/paper.jar; exit 0

# Copy built jar
RUN mv ${MINECRAFT_BUILD_PATH}/cache/patched*.jar ${MINECRAFT_BUILD_PATH}/paper.jar

###########################
### Running environment ###
###########################
FROM debian:buster-slim as runtime

ARG version=17.0.10.7-1
# In addition to installing the Amazon corretto, we also install
# fontconfig. The folks who manage the docker hub's
# official image library have found that font management
# is a common usecase, and painpoint, and have
# recommended that Java images include font support.
#
# See:
#  https://github.com/docker-library/official-images/blob/master/test/tests/java-uimanager-font/container.java

RUN set -eux \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    curl ca-certificates gnupg software-properties-common fontconfig java-common \
    && curl -fL https://apt.corretto.aws/corretto.key | apt-key add - \
    && add-apt-repository 'deb https://apt.corretto.aws stable main' \
    && mkdir -p /usr/share/man/man1 || true \
    && apt-get update \
    && apt-get install -y java-17-amazon-corretto-jdk=1:$version \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    curl gnupg software-properties-common

ENV LANG C.UTF-8
ENV JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto

ARG MINECRAFT_BUILD_USER=minecraft-build
ENV MINECRAFT_BUILD_PATH=/opt/minecraft

##########################
### Environment & ARGS ###
##########################
ENV MINECRAFT_PATH=/opt/minecraft
ENV SERVER_PATH=${MINECRAFT_PATH}/server
ENV DATA_PATH=${MINECRAFT_PATH}/data
ENV LOGS_PATH=${MINECRAFT_PATH}/logs
ENV CONFIG_PATH=${MINECRAFT_PATH}/config
ENV WORLDS_PATH=${MINECRAFT_PATH}/worlds
ENV PLUGINS_PATH=${MINECRAFT_PATH}/plugins
ENV PROPERTIES_LOCATION=${CONFIG_PATH}/server.properties
ENV JAVA_HEAP_SIZE=4G
ENV JAVA_ARGS="-server -Dcom.mojang.eula.agree=true"
ENV SPIGOT_ARGS="--nojline"
ENV PAPER_ARGS=""

#########################
### Working directory ###
#########################
WORKDIR ${SERVER_PATH}

###########################################
### Obtain runable jar from build stage ###
###########################################
COPY --from=build /opt/minecraft/paper.jar ${SERVER_PATH}/

######################
### Obtain scripts ###
######################
ADD scripts/docker-entrypoint.sh ./docker-entrypoint.sh
RUN chmod +x ./docker-entrypoint.sh

############
### User ###
############
RUN addgroup minecraft && \
    adduser minecraft --shell /bin/bash --ingroup minecraft --home ${MINECRAFT_PATH} --system && \
    mkdir ${LOGS_PATH} ${DATA_PATH} ${WORLDS_PATH} ${PLUGINS_PATH} ${CONFIG_PATH} && \
    chown -R minecraft:minecraft ${MINECRAFT_PATH}

USER minecraft

#########################
### Setup environment ###
#########################
# Create symlink for plugin volume as hotfix for some plugins who hard code their directories
RUN ln -s $PLUGINS_PATH $SERVER_PATH/plugins && \
    # Create symlink for persistent data
    ln -s $DATA_PATH/banned-ips.json $SERVER_PATH/banned-ips.json && \
    ln -s $DATA_PATH/banned-players.json $SERVER_PATH/banned-players.json && \
    ln -s $DATA_PATH/help.yml $SERVER_PATH/help.yml && \
    ln -s $DATA_PATH/ops.json $SERVER_PATH/ops.json && \
    ln -s $DATA_PATH/permissions.yml $SERVER_PATH/permissions.yml && \
    ln -s $DATA_PATH/whitelist.json $SERVER_PATH/whitelist.json && \
    # Create symlink for logs
    ln -s $LOGS_PATH $SERVER_PATH/logs

###############
### Volumes ###
###############
VOLUME "${CONFIG_PATH}"
VOLUME "${WORLDS_PATH}"
VOLUME "${PLUGINS_PATH}"
VOLUME "${DATA_PATH}"
VOLUME "${LOGS_PATH}"

#############################
### Expose minecraft port ###
#############################
EXPOSE 25565

######################################
### Entrypoint is the start script ###
######################################
ENTRYPOINT [ "./docker-entrypoint.sh" ]

# Run Command
CMD [ "serve" ]
