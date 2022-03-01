FROM ubuntu:21.04
MAINTAINER Hugo Josefson <hugo@josefson.org> (https://www.hugojosefson.com/)

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
  && apt-get install -y apt-utils \
  && apt-get dist-upgrade --purge -y \
  && apt-get autoremove --purge -y \
  && apt-get install -y \
    curl                   $(: 'required by these setup scripts') \
    wget                   $(: 'required by these setup scripts') \
    jq                     $(: 'required by these setup scripts') \
    gosu                   $(: 'for better process signalling in docker') \
    x11-apps               $(: 'basic X11 support') \
    libxtst6               $(: 'required for graphics') \
    libxi6                 $(: 'required for graphics') \
    openjfx                $(: 'required for graphics') \
    libopenjfx-java        $(: 'required for graphics') \
    matchbox               $(: 'required for graphics') \
    libxslt1.1             $(: 'required for graphics') \
    libgl1-mesa-dri        $(: 'required for graphics') \
    libgl1-mesa-glx        $(: 'required for graphics') \
    libcanberra-gtk-module $(: '~required by webstorm on manjaro') \
    firefox                $(: '~required by webstorm' ) \
    git                    $(: '~required by webstorm' ) \
    build-essential        $(: 'required by clion' ) \
    gcc                    $(: 'required for rust' ) \
    sudo                   $(: 'useful') \
    vim                    $(: 'useful') \
    libnss3 libnss3-tools libnspr4 libgbm1 libxss1 \
    unzip                  $(: 'required by deno install.sh') \
  && apt-get clean

ARG WEBSTORM_URL
ARG CLION_URL
RUN mkdir /tmp/install-jetbrains
COPY \
  jetbrains-url-to-version \
  /tmp/install-jetbrains/
COPY \
  install-webstorm \
  latest-webstorm-url \
  /tmp/install-jetbrains/
RUN /tmp/install-jetbrains/install-webstorm "${WEBSTORM_URL}"
COPY \
  install-clion \
  latest-clion-url \
  /tmp/install-jetbrains/
RUN /tmp/install-jetbrains/install-clion "${CLION_URL}"
RUN rm -rf /tmp/install-jetbrains

ARG NVM_VERSION
ARG NODE_VERSION
ARG NPM_VERSION
ARG YARN_VERSION

RUN (test ! -z "${NVM_VERSION}" && exit 0 || echo "--build-arg NVM_VERSION must be supplied to docker build." >&2 && exit 1)
RUN (test ! -z "${NODE_VERSION}" && exit 0 || echo "--build-arg NODE_VERSION must be supplied to docker build." >&2 && exit 1)
RUN (test ! -z "${NPM_VERSION}" && exit 0 || echo "--build-arg NPM_VERSION must be supplied to docker build." >&2 && exit 1)
RUN (test ! -z "${YARN_VERSION}" && exit 0 || echo "--build-arg YARN_VERSION must be supplied to docker build." >&2 && exit 1)

RUN echo NVM_VERSION=${NVM_VERSION}
RUN echo NODE_VERSION=${NODE_VERSION}
RUN echo NPM_VERSION=${NPM_VERSION}
RUN echo YARN_VERSION=${YARN_VERSION}

ENV NVM_DIR="/opt/nvm"
COPY etc-profile.d-nvm /etc/profile.d/nvm.sh
RUN groupadd --system nvm \
  && usermod --append --groups nvm root
RUN mkdir -p "${NVM_DIR}/{.cache,versions,alias}" \
  && chown -R :nvm "${NVM_DIR}" \
  && chmod -R g+ws "${NVM_DIR}"
RUN curl https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | PROFILE=/etc/bash.bashrc bash
RUN . "${NVM_DIR}/nvm.sh" && nvm install --lts
RUN . "${NVM_DIR}/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "${NVM_DIR}/nvm.sh" && nvm exec --lts -- npm install -g npm@${NPM_VERSION}
RUN . "${NVM_DIR}/nvm.sh" && nvm exec ${NODE_VERSION} -- npm install -g npm@${NPM_VERSION}
RUN . "${NVM_DIR}/nvm.sh" && nvm exec --lts -- npm install -g yarn@${YARN_VERSION}
RUN . "${NVM_DIR}/nvm.sh" && nvm exec ${NODE_VERSION} -- npm install -g yarn@${YARN_VERSION}
RUN . "${NVM_DIR}/nvm.sh" && nvm alias default ${NODE_VERSION}
RUN . "${NVM_DIR}/nvm.sh" && nvm use default

ARG DENO_VERSION
RUN (test ! -z "${DENO_VERSION}" && exit 0 || echo "--build-arg DENO_VERSION must be supplied to docker build." >&2 && exit 1)
ENV DENO_INSTALL="/usr/local"
RUN curl -fsSL https://deno.land/x/install/install.sh | sh -s "${DENO_VERSION}"
RUN deno --version

WORKDIR /
COPY entrypoint /
ENTRYPOINT ["/entrypoint"]
CMD ["/usr/local/bin/webstorm"]
