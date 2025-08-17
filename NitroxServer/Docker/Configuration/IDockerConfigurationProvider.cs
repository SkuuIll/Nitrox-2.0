using System.Collections.Generic;

namespace NitroxServer.Docker.Configuration;

/// <summary>
/// Provides configuration management for Docker-deployed Nitrox server
/// </summary>
public interface IDockerConfigurationProvider
{
    /// <summary>
    /// Get the current server configuration
    /// </summary>
    /// <returns>Current server configuration</returns>
    DockerServerConfiguration GetServerConfiguration();

    /// <summary>
    /// Update configuration with new environment variables
    /// </summary>
    /// <param name="environmentVariables">Dictionary of environment variables</param>
    void UpdateConfiguration(Dictionary<string, string> environmentVariables);

    /// <summary>
    /// Validate the current configuration
    /// </summary>
    /// <param name="errors">List of validation errors if any</param>
    /// <returns>True if configuration is valid</returns>
    bool ValidateConfiguration(out List<string> errors);

    /// <summary>
    /// Reload configuration from environment variables
    /// </summary>
    void ReloadConfiguration();

    /// <summary>
    /// Get configuration value by key with optional default
    /// </summary>
    /// <param name="key">Configuration key</param>
    /// <param name="defaultValue">Default value if key not found</param>
    /// <returns>Configuration value or default</returns>
    string GetConfigurationValue(string key, string defaultValue = null);

    /// <summary>
    /// Set configuration value
    /// </summary>
    /// <param name="key">Configuration key</param>
    /// <param name="value">Configuration value</param>
    void SetConfigurationValue(string key, string value);
}