FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV WINEDEBUG=-all
ENV WINEPREFIX=/root/.wine

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    software-properties-common \
    winbind \
    cabextract \
    xvfb \
    git \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Install Wine
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends wine wine32 wine64 libwine libwine:i386 && \
    rm -rf /var/lib/apt/lists/*

# Install winetricks
RUN wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks -O /usr/local/bin/winetricks && \
    chmod +x /usr/local/bin/winetricks

# Setup Wine environment
RUN mkdir -p /root/.cache/wine
RUN wine wineboot --init

# Install MetaEditor for MT4
RUN wget http://web.archive.org/web/20220512025614/https://download.mql5.com/cdn/web/metaquotes.software.corp/mt4/metaeditor4setup.exe -O /tmp/metaeditor4setup.exe && \
    xvfb-run wine /tmp/metaeditor4setup.exe /S && \
    rm /tmp/metaeditor4setup.exe

# Install MetaEditor for MT5
RUN wget https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/metaeditor64.exe -O /tmp/metaeditor5setup.exe && \
    xvfb-run wine /tmp/metaeditor5setup.exe /S && \
    rm /tmp/metaeditor5setup.exe

# Create working directory
WORKDIR /app

# Copy build scripts
COPY scripts/build_mt4.sh /usr/local/bin/build_mt4
COPY scripts/build_mt5.sh /usr/local/bin/build_mt5
RUN chmod +x /usr/local/bin/build_mt4 /usr/local/bin/build_mt5

ENTRYPOINT ["/bin/bash"]