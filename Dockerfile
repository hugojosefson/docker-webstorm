FROM ubuntu:20.04
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
RUN (test ! -z "${NVM_VERSION}" && exit 0 || echo "--build-arg NVM_VERSION must be supplied to docker build." >&2 && exit 1)
ENV NVM_DIR="/opt/nvm"
COPY etc-profile.d-nvm /etc/profile.d/nvm
RUN groupadd --system nvm \
  && usermod --append --groups nvm root
RUN mkdir -p "${NVM_DIR}/{.cache,versions,alias}" \
  && chown -R :nvm "${NVM_DIR}" \
  && chmod -R g+ws "${NVM_DIR}"
RUN curl https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | PROFILE=/etc/bash.bashrc bash
RUN . "${NVM_DIR}/nvm.sh" \
  && nvm install --lts \
  && nvm exec --lts npm install -g npm@latest \
  && nvm exec --lts npm install -g yarn@latest \
  && nvm install stable \
  && nvm exec stable npm install -g npm@latest \
  && nvm exec stable npm install -g yarn@latest \
  && nvm alias default stable \
  && nvm use default

WORKDIR /
COPY entrypoint /
ENTRYPOINT ["/entrypoint"]
CMD ["/usr/local/bin/webstorm"]
