#
#--------------------------------------------------------------------------
# Image Setup
#--------------------------------------------------------------------------
#

FROM phusion/baseimage:0.11

LABEL maintainer="Mahmoud Zalt <mahmoud@zalt.me>"

RUN DEBIAN_FRONTEND=noninteractive
RUN locale-gen en_US.UTF-8

ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV LC_CTYPE=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV TERM xterm

# Add the "PHP 7" ppa
RUN apt-get install -y software-properties-common && \
    add-apt-repository -y ppa:ondrej/php

#
#--------------------------------------------------------------------------
# Software's Installation
#--------------------------------------------------------------------------
#

RUN echo 'DPkg::options { "--force-confdef"; };' >> /etc/apt/apt.conf

# Install "PHP Extentions", "libraries", "Software's"
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --allow-downgrades --allow-remove-essential \
        --allow-change-held-packages \
        php7.4-cli \
        php7.4-common \
        php7.4-curl \
        php7.4-intl \
        php7.4-json \
        php7.4-xml \
        php7.4-mbstring \
        php7.4-mysql \
        php7.4-pgsql \
        php7.4-sqlite \
        php7.4-sqlite3 \
        php7.4-zip \
        php7.4-bcmath \
        php7.4-memcached \
        php7.4-gd \
        php7.4-dev \
        pkg-config \
        libcurl4-openssl-dev \
        libedit-dev \
        libssl-dev \
        libxml2-dev \
        xz-utils \
        libsqlite3-dev \
        sqlite3 \
        git \
        curl \
        vim \
        nano \
        postgresql-client \
    && apt-get clean

# Start as root
USER root

###########################################################################
# Laradock non-root user:
###########################################################################

# Add a non-root user to prevent files being created with root permissions on host machine.
ARG PUID=1000
ENV PUID ${PUID}
ARG PGID=1000
ENV PGID ${PGID}

# always run apt update when start and after add new source list, then clean up at end.
RUN set -xe; \
    apt-get update -yqq && \
    pecl channel-update pecl.php.net && \
    groupadd -g ${PGID} laradock && \
    useradd -u ${PUID} -g laradock -m laradock -G docker_env && \
    usermod -p "*" laradock -s /bin/bash && \
    apt-get install -yqq \
      apt-utils \
      #
      #--------------------------------------------------------------------------
      # Mandatory Software's Installation
      #--------------------------------------------------------------------------
      #
      # Mandatory Software's such as ("php-cli", "git", "vim", ....) are
      # installed on the base image 'laradock/workspace' image. If you want
      # to add more Software's or remove existing one, you need to edit the
      # base image (https://github.com/Laradock/workspace).
      #
      # next lines are here because there is no auto build on dockerhub see https://github.com/laradock/laradock/pull/1903#issuecomment-463142846
      libzip-dev zip unzip \
      # Install the zip extension
      php7.4-zip \
      # nasm
      nasm && \
      php -m | grep -q 'zip'

###########################################################################
# User Aliases
###########################################################################

USER root

COPY ./aliases.sh /root/aliases.sh
COPY ./aliases.sh /home/laradock/aliases.sh

RUN sed -i 's/\r//' /root/aliases.sh && \
    sed -i 's/\r//' /home/laradock/aliases.sh && \
    chown laradock:laradock /home/laradock/aliases.sh && \
    echo "" >> ~/.bashrc && \
    echo "# Load Custom Aliases" >> ~/.bashrc && \
    echo "source ~/aliases.sh" >> ~/.bashrc && \
	  echo "" >> ~/.bashrc

USER laradock

RUN echo "" >> ~/.bashrc && \
    echo "# Load Custom Aliases" >> ~/.bashrc && \
    echo "source ~/aliases.sh" >> ~/.bashrc && \
	  echo "" >> ~/.bashrc

###########################################################################
# Composer:
###########################################################################

USER root

# Add the composer.json
COPY ./composer.json /home/laradock/.composer/composer.json

# Add the auth.json for magento 2 credentials
COPY ./auth.json /home/laradock/.composer/auth.json

# Make sure that ~/.composer belongs to laradock
RUN chown -R laradock:laradock /home/laradock/.composer

# Export composer vendor path
RUN echo "" >> ~/.bashrc && \
    echo 'export PATH="$HOME/.composer/vendor/bin:$PATH"' >> ~/.bashrc

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

USER laradock

# Check if global install need to be ran
ARG COMPOSER_GLOBAL_INSTALL=true
ENV COMPOSER_GLOBAL_INSTALL ${COMPOSER_GLOBAL_INSTALL}

RUN if [ ${COMPOSER_GLOBAL_INSTALL} = true ]; then \
    # run the install
    composer global install \
;fi

# Check if auth file is disabled
ARG COMPOSER_AUTH=false
ENV COMPOSER_AUTH ${COMPOSER_AUTH}

RUN if [ ${COMPOSER_AUTH} = false ]; then \
    # remove the file
    rm /home/laradock/.composer/auth.json \
;fi

ARG COMPOSER_REPO_PACKAGIST
ENV COMPOSER_REPO_PACKAGIST ${COMPOSER_REPO_PACKAGIST}

RUN if [ ${COMPOSER_REPO_PACKAGIST} ]; then \
    composer config -g repo.packagist composer ${COMPOSER_REPO_PACKAGIST} \
;fi

# Export composer vendor path
RUN echo "" >> ~/.bashrc && \
    echo 'export PATH="~/.composer/vendor/bin:$PATH"' >> ~/.bashrc

###########################################################################
# Node / NVM:
###########################################################################

# Check if NVM needs to be installed
ARG NODE_VERSION=node
ENV NODE_VERSION ${NODE_VERSION}
ARG INSTALL_NODE=true
ARG INSTALL_NPM_GULP=false
ARG INSTALL_NPM_BOWER=false
ARG INSTALL_NPM_VUE_CLI=false
ARG INSTALL_NPM_ANGULAR_CLI=false
ARG NPM_REGISTRY
ENV NPM_REGISTRY ${NPM_REGISTRY}
ENV NVM_DIR /home/laradock/.nvm
ARG NVM_NODEJS_ORG_MIRROR
ENV NVM_NODEJS_ORG_MIRROR ${NVM_NODEJS_ORG_MIRROR}

RUN if [ ${INSTALL_NODE} = true ]; then \
    # Install nvm (A Node Version Manager)
    mkdir -p $NVM_DIR && \
    curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash \
        && . $NVM_DIR/nvm.sh \
        && nvm install ${NODE_VERSION} \
        && nvm use ${NODE_VERSION} \
        && nvm alias ${NODE_VERSION} \
        && if [ ${NPM_REGISTRY} ]; then \
        npm config set registry ${NPM_REGISTRY} \
        ;fi \
        && if [ ${INSTALL_NPM_GULP} = true ]; then \
        npm install -g gulp \
        ;fi \
        && if [ ${INSTALL_NPM_BOWER} = true ]; then \
        npm install -g bower \
        ;fi \
        && if [ ${INSTALL_NPM_VUE_CLI} = true ]; then \
        npm install -g @vue/cli \
        ;fi \
        && if [ ${INSTALL_NPM_ANGULAR_CLI} = true ]; then \
        npm install -g @angular/cli \
        ;fi \
        && ln -s `npm bin --global` /home/laradock/.node-bin \
;fi

# Wouldn't execute when added to the RUN statement in the above block
# Source NVM when loading bash since ~/.profile isn't loaded on non-login shell
RUN if [ ${INSTALL_NODE} = true ]; then \
    echo "" >> ~/.bashrc && \
    echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm' >> ~/.bashrc \
;fi

# Add NVM binaries to root's .bashrc
USER root

RUN if [ ${INSTALL_NODE} = true ]; then \
    echo "" >> ~/.bashrc && \
    echo 'export NVM_DIR="/home/laradock/.nvm"' >> ~/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm' >> ~/.bashrc \
;fi

# Add PATH for node
ENV PATH $PATH:/home/laradock/.node-bin

# Make it so the node modules can be executed with 'docker-compose exec'
# We'll create symbolic links into '/usr/local/bin'.
RUN if [ ${INSTALL_NODE} = true ]; then \
    find $NVM_DIR -type f -name node -exec ln -s {} /usr/local/bin/node \; && \
    NODE_MODS_DIR="$NVM_DIR/versions/node/$(node -v)/lib/node_modules" && \
    ln -s $NODE_MODS_DIR/bower/bin/bower /usr/local/bin/bower && \
    ln -s $NODE_MODS_DIR/gulp/bin/gulp.js /usr/local/bin/gulp && \
    ln -s $NODE_MODS_DIR/npm/bin/npm-cli.js /usr/local/bin/npm && \
    ln -s $NODE_MODS_DIR/npm/bin/npx-cli.js /usr/local/bin/npx && \
    ln -s $NODE_MODS_DIR/vue-cli/bin/vue /usr/local/bin/vue && \
    ln -s $NODE_MODS_DIR/vue-cli/bin/vue-init /usr/local/bin/vue-init && \
    ln -s $NODE_MODS_DIR/vue-cli/bin/vue-list /usr/local/bin/vue-list \
;fi

RUN if [ ${NPM_REGISTRY} ]; then \
    . ~/.bashrc && npm config set registry ${NPM_REGISTRY} \
;fi

###########################################################################
# SSH2:
###########################################################################

USER root

ARG INSTALL_SSH2=true

RUN if [ ${INSTALL_SSH2} = true ]; then \
  # Install the PHP SSH2 extension
  apt-get -y install libssh2-1-dev php7.4-ssh2 \
;fi

###########################################################################
# ssh:
###########################################################################

# ARG INSTALL_WORKSPACE_SSH=true

# Do not want to add the keys to the image. We will probably add them manually 
# later on
# COPY insecure_id_rsa /tmp/id_rsa
# COPY insecure_id_rsa.pub /tmp/id_rsa.pub

# RUN if [ ${INSTALL_WORKSPACE_SSH} = true ]; then \
#     rm -f /etc/service/sshd/down && \
#     cat /tmp/id_rsa.pub >> /root/.ssh/authorized_keys \
#         && cat /tmp/id_rsa.pub >> /root/.ssh/id_rsa.pub \
#         && cat /tmp/id_rsa >> /root/.ssh/id_rsa \
#         && rm -f /tmp/id_rsa* \
#         && chmod 644 /root/.ssh/authorized_keys /root/.ssh/id_rsa.pub \
#     && chmod 400 /root/.ssh/id_rsa \
#     && cp -rf /root/.ssh /home/laradock \
#     && chown -R laradock:laradock /home/laradock/.ssh \
# ;fi

#
#--------------------------------------------------------------------------
# Final Touch
#--------------------------------------------------------------------------
#

USER root

# Clean up
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    rm /var/log/lastlog /var/log/faillog

# Set default work directory
WORKDIR /code
