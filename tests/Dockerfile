# ─── test-runner: imagen con todas las herramientas para tests + SonarQube ───
FROM maven:3.9.9-eclipse-temurin-21 AS drogon-build

RUN apt-get update && apt-get install -y \
    git cmake g++ gcc make libjsoncpp-dev libssl-dev zlib1g-dev libbrotli-dev \
    libcurl4-openssl-dev uuid-dev libpq-dev \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --recurse-submodules --branch v1.9.13 --depth 1 \
    https://github.com/drogonframework/drogon.git /tmp/drogon \
    && mkdir /tmp/drogon/build && cd /tmp/drogon/build \
    && cmake .. -DCMAKE_BUILD_TYPE=Release \
    && make -j$(nproc) \
    && make install \
    && rm -rf /tmp/drogon

# ─── Etapa final ──────────────────────────────────────────────────────────
FROM maven:3.9.9-eclipse-temurin-21

RUN apt-get update && apt-get install -y \
    curl wget unzip \
    cmake g++ gcc make gcovr \
    libjsoncpp-dev libssl-dev zlib1g-dev libbrotli-dev \
    libcurl4-openssl-dev uuid-dev libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Node.js 22
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# .NET SDK 10.0
RUN wget https://dot.net/v1/dotnet-install.sh -O /tmp/dotnet-install.sh \
    && chmod +x /tmp/dotnet-install.sh \
    && /tmp/dotnet-install.sh --channel 10.0 --install-dir /usr/share/dotnet \
    && ln -sf /usr/share/dotnet/dotnet /usr/local/bin/dotnet \
    && rm /tmp/dotnet-install.sh

# SonarScanner CLI
RUN wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-6.2.1.4610-linux-x64.zip -O /tmp/sonar-scanner.zip \
    && unzip /tmp/sonar-scanner.zip -d /opt \
    && rm /tmp/sonar-scanner.zip
ENV PATH="/opt/sonar-scanner-6.2.1.4610-linux-x64/bin:${PATH}"

# Drogon (desde la etapa anterior)
COPY --from=drogon-build /usr/local/lib /usr/local/lib
COPY --from=drogon-build /usr/local/include/drogon /usr/local/include/drogon
COPY --from=drogon-build /usr/local/lib/cmake/Drogon /usr/local/lib/cmake/Drogon
RUN ldconfig

WORKDIR /app
COPY tests/run-tests.sh /app/run-tests.sh
RUN chmod +x /app/run-tests.sh

CMD ["/app/run-tests.sh"]
