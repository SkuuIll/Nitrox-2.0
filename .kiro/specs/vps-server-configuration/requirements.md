# Requirements Document

## Introduction

This feature creates a fully automated VPS deployment solution for Nitrox multiplayer server. Instead of manual configuration, the system will automatically install Steam, download Subnautica, and configure the server to run directly on the VPS without Docker. The solution addresses the current crashes by implementing automated Steam installation and game download processes that work in headless server environments.

## Requirements

### Requirement 1

**User Story:** As a server administrator, I want Steam to be automatically installed on my VPS, so that I can download Subnautica without manual intervention.

#### Acceptance Criteria

1. WHEN the deployment script runs THEN the system SHALL automatically install SteamCMD on the VPS
2. WHEN SteamCMD is installed THEN the system SHALL configure it to run in headless mode without GUI requirements
3. WHEN Steam installation completes THEN the system SHALL verify the installation is working correctly
4. WHEN Steam is not already installed THEN the system SHALL download and install it automatically
5. WHEN Steam installation fails THEN the system SHALL provide clear error messages and retry mechanisms

### Requirement 2

**User Story:** As a server administrator, I want Subnautica to be automatically downloaded via Steam, so that all game files are available for the Nitrox server.

#### Acceptance Criteria

1. WHEN SteamCMD is installed THEN the system SHALL automatically download Subnautica using the game's App ID
2. WHEN Subnautica download starts THEN the system SHALL monitor download progress and handle network interruptions
3. WHEN Subnautica download completes THEN the system SHALL verify all required game files are present
4. WHEN game files are missing or corrupted THEN the system SHALL re-download or repair the installation
5. WHEN download fails THEN the system SHALL retry with exponential backoff and provide detailed error information

### Requirement 3

**User Story:** As a server administrator, I want the Nitrox server to automatically detect the downloaded Subnautica installation, so that it starts without manual configuration.

#### Acceptance Criteria

1. WHEN Subnautica is downloaded via Steam THEN the Nitrox server SHALL automatically detect the installation path
2. WHEN the server starts THEN it SHALL use the Steam-installed Subnautica files without requiring manual path configuration
3. WHEN game files are found THEN the system SHALL validate they are the correct version and complete
4. WHEN automatic detection fails THEN the system SHALL provide clear error messages with the expected file locations
5. WHEN the server configuration is complete THEN it SHALL create necessary configuration files automatically

### Requirement 4

**User Story:** As a server administrator, I want a single deployment script that handles everything, so that I can set up the entire server with one command.

#### Acceptance Criteria

1. WHEN the deployment script is executed THEN it SHALL install all dependencies (SteamCMD, .NET runtime, etc.)
2. WHEN dependencies are installed THEN the script SHALL download Subnautica via Steam automatically
3. WHEN Subnautica is downloaded THEN the script SHALL configure and start the Nitrox server
4. WHEN the process completes THEN the server SHALL be running and accessible for multiplayer connections
5. WHEN any step fails THEN the script SHALL provide clear error messages and cleanup instructions

### Requirement 5

**User Story:** As a server administrator, I want the server to handle VPS-specific environment issues automatically, so that it runs reliably without desktop dependencies.

#### Acceptance Criteria

1. WHEN environment variables like HOME or XDG_CONFIG_HOME are missing THEN the system SHALL create local configuration directories
2. WHEN running as root user THEN the system SHALL handle permissions and paths correctly
3. WHEN the server needs to save configuration THEN it SHALL use the local server directory structure
4. WHEN Steam is running in headless mode THEN the server SHALL detect game files correctly
5. WHEN the deployment is complete THEN the system SHALL work entirely without Docker or GUI dependencies