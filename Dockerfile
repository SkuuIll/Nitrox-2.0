# Multi-stage Dockerfile for Nitrox Server VPS Deployment
# Stage 1: Build environment
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy project files
COPY *.sln ./
COPY NitroxModel/*.csproj ./NitroxModel/
COPY NitroxModel-Subnautica/*.csproj ./NitroxModel-Subnautica/
COPY NitroxServer/*.csproj ./NitroxServer/
COPY NitroxServer-Subnautica/*.csproj ./NitroxServer-Subnautica/
COPY NitroxPatcher/*.csproj ./NitroxPatcher/

# Restore dependencies
RUN dotnet restore

# Copy source code
COPY . .

# Build the server
RUN dotnet publish NitroxServer-Subnautica/NitroxServer-Subnautica.csproj \
    -c Release \
    -o /app/publish \
    --no-restore \
    --self-contained false

# Stage 2: SteamCMD for game file acquisition
FROM steamcmd/steamcmd:latest AS steamcmd

# Stage 3: Runtime environment
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime

# Install required packages
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN groupadd -r nitrox && useradd -r -g nitrox -m -d /home/nitrox nitrox

# Create application directories
RUN mkdir -p /app/server /app/gamefiles /app/saves /app/config /app/logs \
    && chown -R nitrox:nitrox /app

# Copy SteamCMD from steamcmd stage
COPY --from=steamcmd /home/steam/steamcmd /app/steamcmd
RUN chown -R nitrox:nitrox /app/steamcmd

# Copy published application
COPY --from=build /app/publish /app/server
RUN chown -R nitrox:nitrox /app/server

# Copy Docker-specific scripts
COPY docker/entrypoint.sh /app/entrypoint.sh
COPY docker/healthcheck.sh /app/healthcheck.sh
COPY docker/download-game.sh /app/download-game.sh

# Make scripts executable
RUN chmod +x /app/entrypoint.sh /app/healthcheck.sh /app/download-game.sh \
    && chown nitrox:nitrox /app/*.sh

# Set working directory
WORKDIR /app

# Switch to non-root user
USER nitrox

# Expose server port (UDP)
EXPOSE 11000/udp

# Set environment variables with defaults
ENV NITROX_SERVER_NAME="Docker Nitrox Server" \
    NITROX_SERVER_PORT=11000 \
    NITROX_SERVER_PASSWORD="" \
    NITROX_ADMIN_PASSWORD="admin123" \
    NITROX_GAME_MODE="Survival" \
    NITROX_DISABLE_AUTO_SAVE=false \
    NITROX_SAVE_INTERVAL=300000 \
    NITROX_MAX_BACKUPS=10 \
    NITROX_GAME_FILES_PATH="/app/gamefiles" \
    NITROX_SAVE_DATA_PATH="/app/saves" \
    NITROX_CONFIG_PATH="/app/config" \
    NITROX_ENABLE_STEAM_DOWNLOAD=true \
    STEAM_USERNAME="" \
    STEAM_PASSWORD="" \
    DOTNET_ENVIRONMENT=Production

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD /app/healthcheck.sh

# Entry point
ENTRYPOINT ["/app/entrypoint.sh"]