using System.Threading;
using System.Threading.Tasks;

namespace NitroxServer.Docker.GameFiles;

/// <summary>
/// Manages Subnautica game file downloading, validation, and caching
/// </summary>
public interface IGameFileManager
{
    /// <summary>
    /// Ensure game files are available at the target path, downloading if necessary
    /// </summary>
    /// <param name="targetPath">Path where game files should be located</param>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>True if game files are available and valid</returns>
    Task<bool> EnsureGameFilesAsync(string targetPath, CancellationToken cancellationToken);

    /// <summary>
    /// Validate the integrity of game files at the specified path
    /// </summary>
    /// <param name="gamePath">Path to game files</param>
    /// <returns>True if game files are valid and complete</returns>
    Task<bool> ValidateGameFilesAsync(string gamePath);

    /// <summary>
    /// Get detailed status information about game files
    /// </summary>
    /// <param name="gamePath">Path to game files</param>
    /// <returns>Detailed status of game files</returns>
    Task<GameFileStatus> GetGameFileStatusAsync(string gamePath);

    /// <summary>
    /// Download game files using SteamCMD
    /// </summary>
    /// <param name="targetPath">Target directory for download</param>
    /// <param name="username">Steam username</param>
    /// <param name="password">Steam password</param>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>True if download was successful</returns>
    Task<bool> DownloadGameFilesAsync(string targetPath, string username, string password, CancellationToken cancellationToken);
}