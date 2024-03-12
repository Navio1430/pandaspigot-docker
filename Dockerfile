FROM itzg/minecraft-server:java17 as build

###################################
### Maintained by Oliwier Fijas ###
### Contact: naviodev@gmail.com ###
###################################
LABEL maintainer="Oliwier Fijas <naviodev@gmail.com>"

ARG PANDA_PATH=/panda

#########################
### Working directory ###
#########################
WORKDIR ${PANDA_PATH}

############################
### Download pandaspigot ###
############################
ARG PANDA_DOWNLOAD_URL="https://nightly.link/hpfxd/PandaSpigot/workflows/build/master/Server%20JAR.zip"

#########################
### Unzip pandaspigot ###
#########################
RUN apt-get update && apt-get install -y unzip curl \
    && curl -L ${PANDA_DOWNLOAD_URL} -o server.zip \
    && unzip server.zip '*.jar' \
    && mv *.jar panda.jar \
    && rm server.zip

#####################
### Runtime stage ###
#####################
FROM itzg/minecraft-server:java17 as runtime

ARG PANDA_PATH=/panda

WORKDIR ${PANDA_PATH}

#######################################
### Copy panda.jar from build stage ###
#######################################
COPY --from=build ${PANDA_PATH}/panda.jar .

#########################################
### Set minecraft engine to panda.jar ###
#########################################
ENV TYPE CUSTOM
ENV CUSTOM_SERVER ${PANDA_PATH}/panda.jar
