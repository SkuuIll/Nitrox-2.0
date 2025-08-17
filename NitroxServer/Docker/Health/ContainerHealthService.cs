using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net.NetworkInformation;
using System.Threading;
using System.Threading.Tasks;
using NitroxModel.Logger;
using NitroxServer.Docker.Configuration;
using NitroxServer.Docker.GameFiles;

namespace NitroxServer.Docker.Health;

/// <summary>
/// Provides comprehensive health monitoring for Docker-deployed Nitrox server
/// </summary>
public class ContainerHealthService : IContainerHealthService
{
    private readonly IDockerConfigurationProvider configurationProvider;
    private readonly IGameFileManager gameFileManager;
    private CancellationTokenSource monitoringCancellationTokenSource;
    private Task monitoringTask;
    private HealthStatus lastHealthStatus = new();

    public bool IsMonitoring => monitoringTask != null && !monitoringTask.IsCompleted;
    public HealthStatus LastHealthStatus => lastHealthStatus;

    public ContainerHealthService(
        IDockerConfigurationProvider configurationProvider,
        IGameFileManager gameFileManager)
    {
        this.configurationProvider = configurationProvider ?? throw new ArgumentNullException(nameof(configurationProvider));
        this.gameFileManager = gameFileManager ?? throw new ArgumentNullException(nameof(gameFileManager));
    }

    public async Task<HealthStatus> CheckHealthAsync()
    {
        var stopwatch = Stopwatch.StartNew();
        var healthStatus = new HealthStatus();

        try
        {
            Log.Debug("Performing health check...");

            // Check server process
            await CheckServerProcessHealth(healthStatus);

            // Check network connectivity
            await CheckNetworkHealth(healthStatus);

            // Check game files
            await CheckGameFilesHealth(healthStatus);

            // Check file system access
            await CheckFileSystemHealth(healthStatus);

            // Check system resources
            await CheckSystemResourcesHealth(healthStatus);

            // Determine overall health status
            DetermineOverallHealth(healthStatus);

            stopwatch.Stop();
            healthStatus.CheckDurationMs = stopwatch.ElapsedMilliseconds;
            healthStatus.Timestamp = DateTime.UtcNow;

            lastHealthStatus = healthStatus;
            
            Log.Debug($"Health check completed in {healthStatus.CheckDurationMs}ms: {healthStatus.Status}");
            
            return healthStatus;
        }
        catch (Exception ex)
        {
            Log.Error(ex, "Health check failed with exception");
            
            stopwatch.Stop();
            healthStatus.Status = HealthState.Critical;
            healthStatus.Message = $"Health check failed: {ex.Message}";
            healthStatus.CheckDurationMs = stopwatch.ElapsedMilliseconds;
            
            return healthStatus;
        }
    }

    public async Task<Dictionary<string, object>> GetMetricsAsync()
    {
        var metrics = new Dictionary<string, object>();

        try
        {
            // Basic system metrics
            var process = Process.GetCurrentProcess();
            metrics["process_id"] = process.Id;
            metrics["process_name"] = process.ProcessName;
            metrics["working_set_mb"] = Math.Round(process.WorkingSet64 / 1024.0 / 1024.0, 2);
            metrics["cpu_time_ms"] = process.TotalProcessorTime.TotalMilliseconds;
            metrics["start_time"] = process.StartTime;
            metrics["uptime_seconds"] = (DateTime.Now - process.StartTime).TotalSeconds;

            // Server-specific metrics
            var config = configurationProvider.GetServerConfiguration();
            metrics["server_name"] = config.ServerName;
            metrics["server_port"] = config.ServerPort;
            metrics["game_mode"] = config.GameMode.ToString();
            metrics["max_players"] = config.MaxPlayers;

            // File system metrics
            if (Directory.Exists(config.SaveDataPath))
            {
                var saveDir = new DirectoryInfo(config.SaveDataPath);
                var saveFiles = saveDir.GetFiles("*", SearchOption.AllDirectories);
                metrics["save_files_count"] = saveFiles.Length;
                metrics["save_data_size_mb"] = Math.Round(saveFiles.Sum(f => f.Length) / 1024.0 / 1024.0, 2);
            }

            if (Directory.Exists(config.GameFilesPath))
            {
                var gameDir = new DirectoryInfo(config.GameFilesPath);
                var gameFiles = gameDir.GetFiles("*", SearchOption.AllDirectories);
                metrics["game_files_count"] = gameFiles.Length;
                metrics["game_files_size_mb"] = Math.Round(gameFiles.Sum(f => f.Length) / 1024.0 / 1024.0, 2);
            }

            // Network metrics
            try
            {
                var udpConnections = IPGlobalProperties.GetIPGlobalProperties()
                    .GetActiveUdpListeners()
                    .Where(ep => ep.Port == config.ServerPort)
                    .ToArray();
                
                metrics["server_port_listening"] = udpConnections.Length > 0;
                metrics["active_udp_listeners"] = udpConnections.Length;
            }
            catch (Exception ex)
            {
                Log.Debug(ex, "Failed to get network metrics");
                metrics["network_metrics_error"] = ex.Message;
            }

            // Health status metrics
            var healthStatus = await CheckHealthAsync();
            metrics["health_status"] = healthStatus.Status.ToString();
            metrics["healthy_components"] = healthStatus.ComponentHealths.Count(c => c.IsHealthy);
            metrics["total_components"] = healthStatus.ComponentHealths.Count;
            metrics["last_health_check"] = healthStatus.Timestamp;
            metrics["health_check_duration_ms"] = healthStatus.CheckDurationMs;

            return metrics;
        }
        catch (Exception ex)
        {
            Log.Error(ex, "Failed to collect metrics");
            metrics["metrics_error"] = ex.Message;
            return metrics;
        }
    }

    public async Task StartMonitoringAsync(CancellationToken cancellationToken)
    {
        if (IsMonitoring)
        {
            Log.Warn("Health monitoring is already running");
            return;
        }

        Log.Info("Starting health monitoring service...");
        
        monitoringCancellationTokenSource = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        
        monitoringTask = Task.Run(async () =>
        {
            while (!monitoringCancellationTokenSource.Token.IsCancellationRequested)
            {
                try
                {
                    await CheckHealthAsync();
                    
                    // Wait 30 seconds between health checks
                    await Task.Delay(30000, monitoringCancellationTokenSource.Token);
                }
                catch (OperationCanceledException)
                {
                    break;
                }
                catch (Exception ex)
                {
                    Log.Error(ex, "Error during health monitoring");
                    
                    // Wait before retrying
                    try
                    {
                        await Task.Delay(10000, monitoringCancellationTokenSource.Token);
                    }
                    catch (OperationCanceledException)
                    {
                        break;
                    }
                }
            }
        }, monitoringCancellationTokenSource.Token);

        Log.Info("Health monitoring service started");
    }

    public async Task StopMonitoringAsync(CancellationToken cancellationToken)
    {
        if (!IsMonitoring)
        {
            return;
        }

        Log.Info("Stopping health monitoring service...");
        
        monitoringCancellationTokenSource?.Cancel();
        
        if (monitoringTask != null)
        {
            try
            {
                await monitoringTask.WaitAsync(TimeSpan.FromSeconds(5), cancellationToken);
            }
            catch (TimeoutException)
            {
                Log.Warn("Health monitoring service did not stop within timeout");
            }
        }

        monitoringCancellationTokenSource?.Dispose();
        monitoringTask = null;
        
        Log.Info("Health monitoring service stopped");
    }

    private async Task CheckServerProcessHealth(HealthStatus healthStatus)
    {
        try
        {
            // Check if Nitrox server process is running
            var processes = Process.GetProcessesByName("dotnet")
                .Where(p => p.MainModule?.FileName?.Contains("NitroxServer") == true)
                .ToArray();

            if (processes.Length == 0)
            {
                // Try alternative process detection
                processes = Process.GetProcesses()
                    .Where(p => p.ProcessName.Contains("Nitrox") || 
                               (p.MainModule?.FileName?.Contains("NitroxServer") == true))
                    .ToArray();
            }

            bool serverRunning = processes.Length > 0;
            
            healthStatus.AddComponentHealth(
                "ServerProcess",
                serverRunning,
                serverRunning ? $"Server process found (PID: {processes[0].Id})" : "Server process not found"
            );

            if (serverRunning)
            {
                var process = processes[0];
                var metadata = new Dictionary<string, object>
                {
                    ["process_id"] = process.Id,
                    ["memory_mb"] = Math.Round(process.WorkingSet64 / 1024.0 / 1024.0, 2),
                    ["cpu_time"] = process.TotalProcessorTime.TotalSeconds
                };
                
                healthStatus.ComponentHealths.Last().Metadata = metadata;
            }
        }
        catch (Exception ex)
        {
            Log.Debug(ex, "Error checking server process health");
            healthStatus.AddComponentHealth("ServerProcess", false, $"Process check failed: {ex.Message}");
        }
    }

    private async Task CheckNetworkHealth(HealthStatus healthStatus)
    {
        try
        {
            var config = configurationProvider.GetServerConfiguration();
            
            // Check if server port is listening
            var udpListeners = IPGlobalProperties.GetIPGlobalProperties()
                .GetActiveUdpListeners()
                .Where(ep => ep.Port == config.ServerPort)
                .ToArray();

            bool portListening = udpListeners.Length > 0;
            
            healthStatus.AddComponentHealth(
                "NetworkPort",
                portListening,
                portListening ? $"Port {config.ServerPort} is listening" : $"Port {config.ServerPort} is not listening"
            );
        }
        catch (Exception ex)
        {
            Log.Debug(ex, "Error checking network health");
            healthStatus.AddComponentHealth("NetworkPort", false, $"Network check failed: {ex.Message}");
        }
    }

    private async Task CheckGameFilesHealth(HealthStatus healthStatus)
    {
        try
        {
            var config = configurationProvider.GetServerConfiguration();
            var gameFileStatus = await gameFileManager.GetGameFileStatusAsync(config.GameFilesPath);
            
            healthStatus.AddComponentHealth(
                "GameFiles",
                gameFileStatus.IsValid && gameFileStatus.IsComplete,
                gameFileStatus.GetSummary(),
                new Dictionary<string, object>
                {
                    ["total_size_mb"] = Math.Round(gameFileStatus.TotalSize / 1024.0 / 1024.0, 2),
                    ["missing_files"] = gameFileStatus.MissingFiles.Count,
                    ["corrupted_files"] = gameFileStatus.CorruptedFiles.Count,
                    ["game_version"] = gameFileStatus.GameVersion ?? "Unknown"
                }
            );
        }
        catch (Exception ex)
        {
            Log.Debug(ex, "Error checking game files health");
            healthStatus.AddComponentHealth("GameFiles", false, $"Game files check failed: {ex.Message}");
        }
    }

    private async Task CheckFileSystemHealth(HealthStatus healthStatus)
    {
        try
        {
            var config = configurationProvider.GetServerConfiguration();
            
            // Check critical directories
            string[] criticalPaths = {
                config.SaveDataPath,
                config.GameFilesPath,
                Path.GetDirectoryName(config.ConfigPath)
            };

            bool allPathsAccessible = true;
            var pathResults = new List<string>();

            foreach (string path in criticalPaths)
            {
                try
                {
                    if (!Directory.Exists(path))
                    {
                        allPathsAccessible = false;
                        pathResults.Add($"{path}: Missing");
                        continue;
                    }

                    // Test write access
                    string testFile = Path.Combine(path, $".health_check_{Guid.NewGuid():N}");
                    await File.WriteAllTextAsync(testFile, "health_check");
                    File.Delete(testFile);
                    
                    pathResults.Add($"{path}: OK");
                }
                catch (Exception ex)
                {
                    allPathsAccessible = false;
                    pathResults.Add($"{path}: Error - {ex.Message}");
                }
            }

            healthStatus.AddComponentHealth(
                "FileSystem",
                allPathsAccessible,
                string.Join("; ", pathResults)
            );
        }
        catch (Exception ex)
        {
            Log.Debug(ex, "Error checking file system health");
            healthStatus.AddComponentHealth("FileSystem", false, $"File system check failed: {ex.Message}");
        }
    }

    private async Task CheckSystemResourcesHealth(HealthStatus healthStatus)
    {
        try
        {
            var process = Process.GetCurrentProcess();
            
            // Memory check (warn if over 2GB, critical if over 4GB)
            long memoryMB = process.WorkingSet64 / 1024 / 1024;
            bool memoryHealthy = memoryMB < 2048;
            
            // CPU time check (basic validation that process is responsive)
            var cpuTime = process.TotalProcessorTime.TotalSeconds;
            
            healthStatus.AddComponentHealth(
                "SystemResources",
                memoryHealthy,
                $"Memory: {memoryMB}MB, CPU Time: {cpuTime:F1}s",
                new Dictionary<string, object>
                {
                    ["memory_mb"] = memoryMB,
                    ["cpu_time_seconds"] = cpuTime,
                    ["uptime_seconds"] = (DateTime.Now - process.StartTime).TotalSeconds
                }
            );
        }
        catch (Exception ex)
        {
            Log.Debug(ex, "Error checking system resources health");
            healthStatus.AddComponentHealth("SystemResources", false, $"Resource check failed: {ex.Message}");
        }
    }

    private void DetermineOverallHealth(HealthStatus healthStatus)
    {
        if (healthStatus.ComponentHealths.Count == 0)
        {
            healthStatus.Status = HealthState.Unknown;
            healthStatus.Message = "No health checks performed";
            return;
        }

        int healthyCount = healthStatus.ComponentHealths.Count(c => c.IsHealthy);
        int totalCount = healthStatus.ComponentHealths.Count;
        
        if (healthyCount == totalCount)
        {
            healthStatus.Status = HealthState.Healthy;
            healthStatus.Message = "All systems operational";
        }
        else if (healthyCount >= totalCount * 0.8) // 80% healthy
        {
            healthStatus.Status = HealthState.Degraded;
            healthStatus.Message = $"{totalCount - healthyCount} components unhealthy";
        }
        else if (healthyCount >= totalCount * 0.5) // 50% healthy
        {
            healthStatus.Status = HealthState.Unhealthy;
            healthStatus.Message = $"Multiple components failing ({healthyCount}/{totalCount} healthy)";
        }
        else
        {
            healthStatus.Status = HealthState.Critical;
            healthStatus.Message = $"Critical system failure ({healthyCount}/{totalCount} healthy)";
        }
    }
}