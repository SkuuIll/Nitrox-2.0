using System;
using NitroxModel.DataStructures.GameLogic;

namespace NitroxServer.Docker.Configuration;

/// <summary>
/// Configuration model for Docker-deployed Nitrox server
/// </summary>
public class DockerServerConfiguration
{
    /// <summary>
    /// Display name of the server
    /// </summary>
    public string ServerName { get; set; } = "Nitrox Docker Server";

    /// <summary>
    /// UDP port for server communication
    /// </summary>
    public int ServerPort { get; set; } = 11000;

    /// <summary>
    /// Password required to join the server (empty for public server)
    /// </summary>
    public string ServerPassword { get; set; } = "";

    /// <summary>
    /// Password for admin commands
    /// </summary>
    public string AdminPassword { get; set; } = "admin123";

    /// <summary>
    /// Game mode for the server
    /// </summary>
    public GameMode GameMode { get; set; } = GameMode.Survival;

    /// <summary>
    /// Whether automatic saving is disabled
    /// </summary>
    public bool DisableAutoSave { get; set; } = false;

    /// <summary>
    /// Interval between automatic saves in milliseconds
    /// </summary>
    public int SaveInterval { get; set; } = 300000; // 5 minutes

    /// <summary>
    /// Maximum number of backup saves to keep
    /// </summary>
    public int MaxBackups { get; set; } = 10;

    /// <summary>
    /// Path to Subnautica game files
    /// </summary>
    public string GameFilesPath { get; set; } = "/app/gamefiles";

    /// <summary>
    /// Path to server save data
    /// </summary>
    public string SaveDataPath { get; set; } = "/app/saves";

    /// <summary>
    /// Path to server configuration files
    /// </summary>
    public string ConfigPath { get; set; } = "/app/config/server.cfg";

    /// <summary>
    /// Whether to enable Steam-based game file downloading
    /// </summary>
    public bool EnableSteamDownload { get; set; } = true;

    /// <summary>
    /// Steam username for game file download
    /// </summary>
    public string SteamUsername { get; set; } = "";

    /// <summary>
    /// Steam password for game file download
    /// </summary>
    public string SteamPassword { get; set; } = "";

    /// <summary>
    /// Whether to create full entity cache on startup
    /// </summary>
    public bool CreateFullEntityCache { get; set; } = false;

    /// <summary>
    /// Whether to disable automatic backups
    /// </summary>
    public bool DisableAutoBackup { get; set; } = false;

    /// <summary>
    /// Serialization mode for save files
    /// </summary>
    public string SerializerMode { get; set; } = "PROTOBUF";

    /// <summary>
    /// Maximum number of players allowed on the server
    /// </summary>
    public int MaxPlayers { get; set; } = 100;

    /// <summary>
    /// Server description displayed in server browser
    /// </summary>
    public string ServerDescription { get; set; } = "Nitrox multiplayer server running in Docker";

    /// <summary>
    /// Whether the server should be listed in public server browser
    /// </summary>
    public bool IsPublicServer { get; set; } = false;

    /// <summary>
    /// Validate the configuration and return any errors
    /// </summary>
    /// <returns>Array of validation error messages, empty if valid</returns>
    public string[] Validate()
    {
        var errors = new System.Collections.Generic.List<string>();

        if (string.IsNullOrWhiteSpace(ServerName))
        {
            errors.Add("Server name cannot be empty");
        }

        if (ServerPort <= 0 || ServerPort > 65535)
        {
            errors.Add($"Server port must be between 1 and 65535, got: {ServerPort}");
        }

        if (string.IsNullOrWhiteSpace(AdminPassword))
        {
            errors.Add("Admin password cannot be empty");
        }

        if (AdminPassword?.Length < 6)
        {
            errors.Add("Admin password must be at least 6 characters long");
        }

        if (string.IsNullOrWhiteSpace(GameFilesPath))
        {
            errors.Add("Game files path cannot be empty");
        }

        if (string.IsNullOrWhiteSpace(SaveDataPath))
        {
            errors.Add("Save data path cannot be empty");
        }

        if (SaveInterval < 60000) // Less than 1 minute
        {
            errors.Add("Save interval must be at least 60000ms (1 minute)");
        }

        if (MaxBackups < 0)
        {
            errors.Add("Max backups cannot be negative");
        }

        if (MaxPlayers <= 0 || MaxPlayers > 1000)
        {
            errors.Add("Max players must be between 1 and 1000");
        }

        if (EnableSteamDownload)
        {
            if (string.IsNullOrWhiteSpace(SteamUsername))
            {
                errors.Add("Steam username is required when Steam download is enabled");
            }

            if (string.IsNullOrWhiteSpace(SteamPassword))
            {
                errors.Add("Steam password is required when Steam download is enabled");
            }
        }

        return errors.ToArray();
    }

    /// <summary>
    /// Get a summary of the configuration for logging
    /// </summary>
    /// <returns>Configuration summary string</returns>
    public string GetSummary()
    {
        return $@"Docker Server Configuration:
  Server Name: {ServerName}
  Server Port: {ServerPort}
  Game Mode: {GameMode}
  Max Players: {MaxPlayers}
  Auto Save: {(DisableAutoSave ? "Disabled" : $"Every {SaveInterval / 1000}s")}
  Max Backups: {MaxBackups}
  Steam Download: {(EnableSteamDownload ? "Enabled" : "Disabled")}
  Public Server: {(IsPublicServer ? "Yes" : "No")}
  Entity Cache: {(CreateFullEntityCache ? "Full" : "On-demand")}";
    }
}