using System;
using System.Collections.Generic;
using System.Globalization;
using NitroxModel.DataStructures.GameLogic;
using NitroxModel.Logger;

namespace NitroxServer.Docker.Configuration;

/// <summary>
/// Manages configuration for Docker-deployed Nitrox server using environment variables
/// </summary>
public class DockerConfigurationProvider : IDockerConfigurationProvider
{
    private DockerServerConfiguration currentConfiguration;
    private readonly Dictionary<string, string> configurationOverrides = new();

    public DockerConfigurationProvider()
    {
        LoadConfigurationFromEnvironment();
    }

    public DockerServerConfiguration GetServerConfiguration()
    {
        return currentConfiguration ?? LoadConfigurationFromEnvironment();
    }

    public void UpdateConfiguration(Dictionary<string, string> environmentVariables)
    {
        if (environmentVariables == null)
            return;

        foreach (var kvp in environmentVariables)
        {
            configurationOverrides[kvp.Key] = kvp.Value;
        }

        LoadConfigurationFromEnvironment();
    }

    public bool ValidateConfiguration(out List<string> errors)
    {
        errors = new List<string>();

        try
        {
            var config = GetServerConfiguration();
            var validationErrors = config.Validate();
            errors.AddRange(validationErrors);

            return errors.Count == 0;
        }
        catch (Exception ex)
        {
            Log.Error(ex, "Error during configuration validation");
            errors.Add($"Configuration validation failed: {ex.Message}");
            return false;
        }
    }

    public void ReloadConfiguration()
    {
        LoadConfigurationFromEnvironment();
    }

    public string GetConfigurationValue(string key, string defaultValue = null)
    {
        // Check overrides first
        if (configurationOverrides.TryGetValue(key, out string overrideValue))
        {
            return overrideValue;
        }

        // Check environment variables
        string envValue = Environment.GetEnvironmentVariable(key);
        return !string.IsNullOrEmpty(envValue) ? envValue : defaultValue;
    }

    public void SetConfigurationValue(string key, string value)
    {
        configurationOverrides[key] = value;
    }

    private DockerServerConfiguration LoadConfigurationFromEnvironment()
    {
        try
        {
            Log.Info("Loading configuration from environment variables...");

            currentConfiguration = new DockerServerConfiguration
            {
                ServerName = GetConfigurationValue("NITROX_SERVER_NAME", "Nitrox Docker Server"),
                ServerPort = ParseInt("NITROX_SERVER_PORT", 11000),
                ServerPassword = GetConfigurationValue("NITROX_SERVER_PASSWORD", ""),
                AdminPassword = GetConfigurationValue("NITROX_ADMIN_PASSWORD", "admin123"),
                GameMode = ParseEnum<GameMode>("NITROX_GAME_MODE", GameMode.Survival),
                DisableAutoSave = ParseBool("NITROX_DISABLE_AUTO_SAVE", false),
                SaveInterval = ParseInt("NITROX_SAVE_INTERVAL", 300000),
                MaxBackups = ParseInt("NITROX_MAX_BACKUPS", 10),
                GameFilesPath = GetConfigurationValue("NITROX_GAME_FILES_PATH", "/app/gamefiles"),
                SaveDataPath = GetConfigurationValue("NITROX_SAVE_DATA_PATH", "/app/saves"),
                ConfigPath = GetConfigurationValue("NITROX_CONFIG_PATH", "/app/config/server.cfg"),
                EnableSteamDownload = ParseBool("NITROX_ENABLE_STEAM_DOWNLOAD", true),
                SteamUsername = GetConfigurationValue("STEAM_USERNAME", ""),
                SteamPassword = GetConfigurationValue("STEAM_PASSWORD", ""),
                CreateFullEntityCache = ParseBool("NITROX_CREATE_FULL_ENTITY_CACHE", false),
                DisableAutoBackup = ParseBool("NITROX_DISABLE_AUTO_BACKUP", false),
                SerializerMode = GetConfigurationValue("NITROX_SERIALIZER_MODE", "PROTOBUF"),
                MaxPlayers = ParseInt("NITROX_MAX_PLAYERS", 100),
                ServerDescription = GetConfigurationValue("NITROX_SERVER_DESCRIPTION", "Nitrox multiplayer server running in Docker"),
                IsPublicServer = ParseBool("NITROX_IS_PUBLIC_SERVER", false)
            };

            Log.Info("Configuration loaded successfully");
            Log.Debug(currentConfiguration.GetSummary());

            return currentConfiguration;
        }
        catch (Exception ex)
        {
            Log.Error(ex, "Failed to load configuration from environment");
            
            // Return default configuration as fallback
            currentConfiguration = new DockerServerConfiguration();
            return currentConfiguration;
        }
    }

    private int ParseInt(string key, int defaultValue)
    {
        string value = GetConfigurationValue(key);
        
        if (string.IsNullOrEmpty(value))
            return defaultValue;

        if (int.TryParse(value, NumberStyles.Integer, CultureInfo.InvariantCulture, out int result))
        {
            return result;
        }

        Log.Warn($"Invalid integer value for {key}: '{value}', using default: {defaultValue}");
        return defaultValue;
    }

    private bool ParseBool(string key, bool defaultValue)
    {
        string value = GetConfigurationValue(key);
        
        if (string.IsNullOrEmpty(value))
            return defaultValue;

        // Support various boolean representations
        value = value.ToLowerInvariant();
        
        if (value == "true" || value == "1" || value == "yes" || value == "on" || value == "enabled")
            return true;
            
        if (value == "false" || value == "0" || value == "no" || value == "off" || value == "disabled")
            return false;

        Log.Warn($"Invalid boolean value for {key}: '{value}', using default: {defaultValue}");
        return defaultValue;
    }

    private T ParseEnum<T>(string key, T defaultValue) where T : struct, Enum
    {
        string value = GetConfigurationValue(key);
        
        if (string.IsNullOrEmpty(value))
            return defaultValue;

        if (Enum.TryParse<T>(value, true, out T result))
        {
            return result;
        }

        Log.Warn($"Invalid enum value for {key}: '{value}', using default: {defaultValue}");
        return defaultValue;
    }
}