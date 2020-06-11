FROM node:8.14-alpine

# Intialize
RUN apk update \
  && apk add --no-cache --update alpine-sdk \
  && apk del alpine-sdk \
  && rm -rf /tmp/* /var/cache/apk/* *.tar.gz ~/.npm \
  && npm cache verify \
  && sed -i -e "s/bin\/ash/bin\/sh/" /etc/passwd \
  && apk add --no-cache  curl grep sed unzip git 

# OpenJDK 8 -- Start (Source: https://github.com/docker-library/openjdk/blob/master/8/jdk/alpine/Dockerfile)

# Default to UTF-8 file.encoding
ENV LANG C.UTF-8

# add a simple script that can auto-detect the appropriate JAVA_HOME value
# based on whether the JDK or only the JRE is installed
RUN { \
		echo '#!/bin/sh'; \
		echo 'set -e'; \
		echo; \
		echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
	} > /usr/local/bin/docker-java-home \
	&& chmod +x /usr/local/bin/docker-java-home
ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
ENV PATH $PATH:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin

ENV JAVA_VERSION 8u181
ENV JAVA_ALPINE_VERSION 8.181.13-r0

RUN set -x \
	&& apk add --no-cache \
		openjdk8="$JAVA_ALPINE_VERSION" \
	&& [ "$JAVA_HOME" = "$(docker-java-home)" ]
# OpenJDK 8 -- End

# Sonar Scanner
RUN curl --insecure -o /opt/sonarscanner.zip -L https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-3.0.3.778-linux.zip \
    && unzip /opt/sonarscanner.zip -d /opt/ \
    && rm /opt/sonarscanner.zip \
    && mv /opt/sonar-scanner-3.0.3.778-linux /opt/sonar-scanner \
    && sed -i 's/use_embedded_jre=true/use_embedded_jre=false/g' /opt/sonar-scanner/bin/sonar-scanner         
# 'sed' above makes Sonar use the provided JDK instead of the embedded one (glibc - wont work in alpine)

ENV SONAR_RUNNER_HOME=/opt/sonar-scanner
ENV PATH $PATH:/opt/sonar-scanner/bin

# Create Jenkins User & Setup Permissions
RUN addgroup -S jenkins && adduser -S jenkins -G root \
    && mkdir  -p /.yarn && mkdir -p /.cache/yarn && chmod a+rw /.yarn && chmod a+rw /.cache/yarn/

USER jenkins