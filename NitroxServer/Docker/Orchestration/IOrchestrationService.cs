using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

namespace NitroxServer.Docker.Orchestration;

/// <summary>
/// Provides container orchestration support and service discovery
/// </summary>
public interface IOrchestrationService
{
    /// <summary>
    /// Initialize orchestration support
    /// </summary>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>True if initialization was successful</returns>
    Task<bool> InitializeAsync(CancellationToken cancellationToken);

    /// <summary>
    /// Register this instance with service discovery
    /// </summary>
    /// <param name="serviceName">Name of the service</param>
    /// <param name="instanceId">Unique instance identifier</param>
    /// <param name="metadata">Additional metadata</param>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>True if registration was successful</returns>
    Task<bool> RegisterServiceAsync(string serviceName, string instanceId, Dictionary<string, string> metadata, CancellationToken cancellationToken);

    /// <summary>
    /// Deregister this instance from service discovery
    /// </summary>
    /// <param name="serviceName">Name of the service</param>
    /// <param name="instanceId">Unique instance identifier</param>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>True if deregistration was successful</returns>
    Task<bool> DeregisterServiceAsync(string serviceName, string instanceId, CancellationToken cancellationToken);

    /// <summary>
    /// Handle graceful shutdown signals from orchestration platform
    /// </summary>
    /// <param name="shutdownHandler">Handler to call when shutdown is requested</param>
    void RegisterShutdownHandler(System.Action shutdownHandler);

    /// <summary>
    /// Get orchestration platform information
    /// </summary>
    /// <returns>Platform information</returns>
    OrchestrationPlatformInfo GetPlatformInfo();

    /// <summary>
    /// Check if running in an orchestrated environment
    /// </summary>
    bool IsOrchestrated { get; }
}