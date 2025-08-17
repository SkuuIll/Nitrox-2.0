using System;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using NitroxModel.Logger;
using NitroxServer.Docker.Configuration;
using NitroxServer.Docker.GameFiles;
using NitroxServer.Docker.Health;

namespace NitroxServer.Docker;

/// <summary>
/// Handles Docker container initialization, orchestrating startup sequence and graceful shutdown
/// </summary>
public class InitializationService : IInitializationService
{
    private readonly IDockerConfigurationProvider configurationProvider;
    private readonly IGameFileManager gameFileManager;
    private readonly IContainerHealthService healthService;
    private InitializationStatus status = InitializationStatus.NotStarted;

    public InitializationStatus Status => status;

    public InitializationService(
        IDockerConfigurationProvider configurationProvider,
        IGameFileManager gameFileManager,
        IContainerHealthService healthService)
    {
        this.configurationProvider = configurationProvider ?? throw new ArgumentNullException(nameof(configurationProvider));
        this.gameFileManager = gameFileManager ?? throw new ArgumentNullException(nameof(gameFileManager));
        this.healthService = healthService ?? throw new ArgumentNullException(nameof(healthService));
    }

    public async Task<bool> InitializeAsync(CancellationToken cancellationToken)
    {
        try
        {
            status = InitializationStatus.Initializing;
            Log.Info("Starting Docker container initialization...");

            // Step 1: Validate configuration
            Log.Info("Validating container configuration...");
            if (!ValidateConfiguration())
            {
                Log.Error("Configuration validation failed");
                status = InitializationStatus.Failed;
                return false;
            }

            // Step 2: Ensure directory structure
            Log.Info("Setting up directory structure...");
            if (!await SetupDirectoriesAsync(cancellationToken))
            {
                Log.Error("Directory setup failed");
                status = InitializationStatus.Failed;
                return false;
            }

            // Step 3: Ensure game files are available
            Log.Info("Ensuring game files are available...");
            var config = configurationProvider.GetServerConfiguration();
            if (!await gameFileManager.EnsureGameFilesAsync(config.GameFilesPath, cancellationToken))
            {
                Log.Error("Game files setup failed");
                status = InitializationStatus.Failed;
                return false;
            }

            // Step 4: Validate game files
            Log.Info("Validating game files integrity...");
            if (!await gameFileManager.ValidateGameFilesAsync(config.GameFilesPath))
            {
                Log.Error("Game files validation failed");
                status = InitializationStatus.Failed;
                return false;
            }

            // Step 5: Initialize health monitoring
            Log.Info("Starting health monitoring service...");
            await healthService.StartMonitoringAsync(cancellationToken);

            status = InitializationStatus.Initialized;
            Log.Info("Container initialization completed successfully");
            return true;
        }
        catch (OperationCanceledException)
        {
            Log.Warn("Container initialization was cancelled");
            status = InitializationStatus.Failed;
            return false;
        }
        catch (Exception ex)
        {
            Log.Error(ex, "Container initialization failed with exception");
            status = InitializationStatus.Failed;
            return false;
        }
    }

    public async Task ShutdownAsync(CancellationToken cancellationToken)
    {
        try
        {
            status = InitializationStatus.ShuttingDown;
            Log.Info("Starting graceful container shutdown...");

            // Stop health monitoring
            Log.Info("Stopping health monitoring service...");
            await healthService.StopMonitoringAsync(cancellationToken);

            // Perform any cleanup operations
            Log.Info("Performing cleanup operations...");
            await PerformCleanupAsync(cancellationToken);

            status = InitializationStatus.Shutdown;
            Log.Info("Container shutdown completed");
        }
        catch (OperationCanceledException)
        {
            Log.Warn("Container shutdown was cancelled");
        }
        catch (Exception ex)
        {
            Log.Error(ex, "Error during container shutdown");
        }
    }

    private bool ValidateConfiguration()
    {
        try
        {
            var config = configurationProvider.GetServerConfiguration();
            
            if (string.IsNullOrWhiteSpace(config.ServerName))
            {
                Log.Error("Server name is required");
                return false;
            }

            if (config.ServerPort <= 0 || config.ServerPort > 65535)
            {
                Log.Error($"Invalid server port: {config.ServerPort}");
                return false;
            }

            if (string.IsNullOrWhiteSpace(config.AdminPassword))
            {
                Log.Error("Admin password is required");
                return false;
            }

            if (string.IsNullOrWhiteSpace(config.GameFilesPath))
            {
                Log.Error("Game files path is required");
                return false;
            }

            if (string.IsNullOrWhiteSpace(config.SaveDataPath))
            {
                Log.Error("Save data path is required");
                return false;
            }

            Log.Info("Configuration validation passed");
            return true;
        }
        catch (Exception ex)
        {
            Log.Error(ex, "Configuration validation failed");
            return false;
        }
    }

    private async Task<bool> SetupDirectoriesAsync(CancellationToken cancellationToken)
    {
        try
        {
            var config = configurationProvider.GetServerConfiguration();

            // Create required directories
            string[] requiredDirectories = {
                config.GameFilesPath,
                config.SaveDataPath,
                Path.GetDirectoryName(config.ConfigPath) ?? "/app/config",
                "/app/logs"
            };

            foreach (string directory in requiredDirectories)
            {
                if (!Directory.Exists(directory))
                {
                    Log.Debug($"Creating directory: {directory}");
                    Directory.CreateDirectory(directory);
                }

                // Verify directory is writable
                string testFile = Path.Combine(directory, ".write_test");
                try
                {
                    await File.WriteAllTextAsync(testFile, "test", cancellationToken);
                    File.Delete(testFile);
                }
                catch (Exception ex)
                {
                    Log.Error(ex, $"Directory {directory} is not writable");
                    return false;
                }
            }

            Log.Info("Directory structure setup completed");
            return true;
        }
        catch (Exception ex)
        {
            Log.Error(ex, "Failed to setup directory structure");
            return false;
        }
    }

    private async Task PerformCleanupAsync(CancellationToken cancellationToken)
    {
        try
        {
            // Clean up temporary files
            string tempDir = Path.GetTempPath();
            string[] tempFiles = Directory.GetFiles(tempDir, "nitrox_*", SearchOption.TopDirectoryOnly);
            
            foreach (string tempFile in tempFiles)
            {
                try
                {
                    File.Delete(tempFile);
                }
                catch (Exception ex)
                {
                    Log.Debug(ex, $"Failed to delete temp file: {tempFile}");
                }
            }

            // Flush any pending logs
            await Task.Delay(100, cancellationToken);
            
            Log.Info("Cleanup operations completed");
        }
        catch (Exception ex)
        {
            Log.Error(ex, "Error during cleanup operations");
        }
    }
}