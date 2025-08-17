using System.Threading;
using System.Threading.Tasks;

namespace NitroxServer.Docker;

/// <summary>
/// Service responsible for Docker container initialization and lifecycle management
/// </summary>
public interface IInitializationService
{
    /// <summary>
    /// Initialize the container environment and prepare for server startup
    /// </summary>
    /// <param name="cancellationToken">Cancellation token for graceful shutdown</param>
    /// <returns>True if initialization was successful, false otherwise</returns>
    Task<bool> InitializeAsync(CancellationToken cancellationToken);

    /// <summary>
    /// Perform graceful shutdown of container services
    /// </summary>
    /// <param name="cancellationToken">Cancellation token for shutdown timeout</param>
    /// <returns>Task representing the shutdown operation</returns>
    Task ShutdownAsync(CancellationToken cancellationToken);

    /// <summary>
    /// Get the current initialization status
    /// </summary>
    InitializationStatus Status { get; }
}

/// <summary>
/// Represents the current state of container initialization
/// </summary>
public enum InitializationStatus
{
    NotStarted,
    Initializing,
    Initialized,
    Failed,
    ShuttingDown,
    Shutdown
}