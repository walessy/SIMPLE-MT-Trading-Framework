FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y wine64 wine-stable wget cabextract && rm -rf /var/lib/apt/lists/*
RUN wine64 wineboot --init
WORKDIR /app
COPY metaeditor.exe /app/
COPY metaeditor64.exe /app/
COPY scripts/build_mt4.sh /usr/local/bin/build_mt4
COPY scripts/build_mt5.sh /usr/local/bin/build_mt5
RUN chmod +x /usr/local/bin/build_mt*
CMD ["bash"]