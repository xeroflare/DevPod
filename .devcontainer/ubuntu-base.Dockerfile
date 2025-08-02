FROM ubuntu:noble

ENV PYTHONUNBUFFERED=1
ENV TZ=Etc/GMT+3
ENV DEBIAN_FRONTEND=noninteractive

# [Optional] Uncomment this section to install additional OS packages
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive && \
    apt-get install -y --no-install-recommends \
    software-properties-common \
    git \
    nano \
    apt-utils \
    curl \
    zip \
    openssh-client \
    xz-utils \
    dirmngr \
    gnupg \
    sudo \
    sqlite3

# [Optional] Uncomment this section to install additional OS packages
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive && \
#     apt-get install -y --no-install-recommends \
#     # list of <packages-here>

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create user and directories
RUN useradd -m --home-dir /home/user -s /bin/bash user && \
    echo "user:user" | chpasswd && \
    usermod -aG sudo user

USER user

COPY --chown=user:user ./workspace /mnt/workspace
# Fix ownership after copying
RUN chown -R user:user /mnt/workspace

WORKDIR /mnt/workspace
