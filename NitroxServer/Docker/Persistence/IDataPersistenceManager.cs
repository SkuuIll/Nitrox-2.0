using System.Threading;
using System.Threading.Tasks;

namespace NitroxServer.Docker.Persistence;

/// <summary>
/// Manages persistent data storage for Docker-deployed Nitrox server
/// </summary>
public interface IDataPersistenceManager
{
    /// <summary>
    /// Initialize persistent storage and validate volume mounts
    /// </summary>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>True if initialization was successful</returns>
    Task<bool> InitializePersistentStorageAsync(CancellationToken cancellationToken);

    /// <summary>
    /// Create a backup of current server data
    /// </summary>
    /// <param name="backupName">Name for the backup</param>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>True if backup was successful</returns>
    Task<bool> CreateBackupAsync(string backupName, CancellationToken cancellationToken);

    /// <summary>
    /// Restore server data from a backup
    /// </summary>
    /// <param name="backupName">Name of the backup to restore</param>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>True if restore was successful</returns>
    Task<bool> RestoreBackupAsync(string backupName, CancellationToken cancellationToken);

    /// <summary>
    /// Get information about available backups
    /// </summary>
    /// <returns>Array of backup information</returns>
    Task<BackupInfo[]> GetAvailableBackupsAsync();

    /// <summary>
    /// Clean up old backups based on retention policy
    /// </summary>
    /// <param name="maxBackups">Maximum number of backups to keep</param>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>Number of backups cleaned up</returns>
    Task<int> CleanupOldBackupsAsync(int maxBackups, CancellationToken cancellationToken);

    /// <summary>
    /// Validate data integrity of persistent storage
    /// </summary>
    /// <returns>Data integrity status</returns>
    Task<DataIntegrityStatus> ValidateDataIntegrityAsync();

    /// <summary>
    /// Migrate data from older versions if necessary
    /// </summary>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>True if migration was successful or not needed</returns>
    Task<bool> MigrateDataAsync(CancellationToken cancellationToken);
}