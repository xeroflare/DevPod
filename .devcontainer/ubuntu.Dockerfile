FROM ubuntu:noble

ENV PYTHONUNBUFFERED=1
ENV TZ=Etc/GMT+3
ENV DEBIAN_FRONTEND=noninteractive

# Install base OS packages
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

# [Optional] Install additional OS packages for Python & Odoo v17/v18 development
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive && \
    apt-get install -y --no-install-recommends \
    # Python environment and build tools
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    python3-wheel \
    python3-setuptools \
    build-essential \
    # PostgreSQL client and development libraries
    postgresql-client \
    libpq-dev \
    postgresql-contrib \
    # XML/HTML processing libraries
    libxml2-dev \
    libxslt1-dev \
    # Image processing libraries
    libjpeg-dev \
    libjpeg8-dev \
    liblcms2-dev \
    libtiff5-dev \
    libfreetype6-dev \
    libopenjp2-7-dev \
    libpng-dev \
    libwebp-dev \
    # LDAP and authentication libraries
    libldap2-dev \
    libsasl2-dev \
    libssl-dev \
    # Mathematical and scientific libraries
    libblas-dev \
    libatlas-base-dev \
    liblapack-dev \
    # Additional development libraries
    libffi-dev \
    libmysqlclient-dev \
    zlib1g-dev \
    libzip-dev \
    # Node.js and frontend tools for RTL support
    nodejs \
    npm \
    node-less \
    # Font and localization support
    fontconfig \
    locales \
    # System monitoring and debugging tools
    htop \
    vim \
    wget \
    ca-certificates \
    # Additional Python packages often needed (Ubuntu Noble compatible)
    python3-babel \
    python3-dateutil \
    python3-decorator \
    python3-docutils \
    python3-feedparser \
    python3-pil \
    python3-jinja2 \
    python3-ldap \
    python3-lxml \
    python3-num2words \
    python3-openid \
    python3-passlib \
    python3-phonenumbers \
    python3-pillow \
    python3-psutil \
    python3-psycopg2 \
    python3-pyparsing \
    python3-qrcode \
    python3-renderpm \
    python3-reportlab \
    python3-requests \
    python3-serial \
    python3-tz \
    python3-usb \
    python3-vobject \
    python3-werkzeug \
    python3-xlrd \
    python3-xlwt \
    python3-yaml

# Install Node.js packages for frontend development
RUN npm install -g less less-plugin-clean-css rtlcss

# # Install wkhtmltopdf (required for PDF reports) - separate block as requested
# RUN apt-get install -y --no-install-recommends \
#     xfonts-75dpi \
#     xfonts-base \
#     xfonts-encodings \
#     xfonts-utils && \
#     wget -q https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.jammy_amd64.deb && \
#     dpkg -i wkhtmltox_0.12.6.1-3.jammy_amd64.deb || apt-get install -f -y && \
#     rm wkhtmltox_0.12.6.1-3.jammy_amd64.deb && \
#     ln -sf /usr/local/bin/wkhtmltopdf /usr/bin/ && \
#     ln -sf /usr/local/bin/wkhtmltoimage /usr/bin/

# Clean up package cache
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Generate locales for international support
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Create user and directories
RUN useradd -m --home-dir /home/user -s /bin/bash user && \
    echo "user:user" | chpasswd && \
    usermod -aG sudo user

USER user

COPY --chown=user:user ./workspace /mnt/workspace
# Fix ownership after copying
RUN chown -R user:user /mnt/workspace

WORKDIR /mnt/workspace
