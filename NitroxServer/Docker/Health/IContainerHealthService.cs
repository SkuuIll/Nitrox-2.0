using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

namespace NitroxServer.Docker.Health;

/// <summary>
/// Provides health monitoring and metrics collection for Docker container
/// </summary>
public interface IContainerHealthService
{
    /// <summary>
    /// Perform a comprehensive health check of the container and server
    /// </summary>
    /// <returns>Current health status</returns>
    Task<HealthStatus> CheckHealthAsync();

    /// <summary>
    /// Get detailed metrics about server performance and status
    /// </summary>
    /// <returns>Dictionary of metrics and their values</returns>
    Task<Dictionary<string, object>> GetMetricsAsync();

    /// <summary>
    /// Start continuous health monitoring
    /// </summary>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>Task representing the monitoring operation</returns>
    Task StartMonitoringAsync(CancellationToken cancellationToken);

    /// <summary>
    /// Stop health monitoring
    /// </summary>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>Task representing the stop operation</returns>
    Task StopMonitoringAsync(CancellationToken cancellationToken);

    /// <summary>
    /// Get the current monitoring status
    /// </summary>
    bool IsMonitoring { get; }

    /// <summary>
    /// Get the last health check result
    /// </summary>
    HealthStatus LastHealthStatus { get; }
}