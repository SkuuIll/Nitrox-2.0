using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using NitroxModel;
using NitroxModel.Logger;
using NitroxServer.Docker.Configuration;

namespace NitroxServer.Docker.Persistence;

/// <summary>
/// Manages persistent data storage, backups, and data integrity for Docker deployment
/// </summary>
public class DataPersistenceManager : IDataPersistenceManager
{
    private readonly IDockerConfigurationProvider configurationProvider;
    private const string BACKUP_DIRECTORY = "backups";
    private const string BACKUP_METADATA_FILE = "backup_metadata.json";

    public DataPersistenceManager(IDockerConfigurationProvider configurationProvider)
    {
        this.configurationProvider = configurationProvider ?? throw new ArgumentNullException(nameof(configurationProvider));
    }

    public async Task<bool> InitializePersistentStorageAsync(CancellationToken cancellationToken)
    {
        try
        {
            Log.Info("Initializing persistent storage...");
            
            var config = configurationProvider.GetServerConfiguration();
            
            // Create required directories
            string[] requiredDirectories = {
                config.SaveDataPath,
                Path.GetDirectoryName(config.ConfigPath),
                Path.Combine(config.SaveDataPath, BACKUP_DIRECTORY)
            };

            foreach (string directory in requiredDirectories)
            {
                if (!Directory.Exists(directory))
                {
                    Log.Debug($"Creating directory: {directory}");
                    Directory.CreateDirectory(directory);
                }

                // Test write permissions
                await TestDirectoryWriteAccess(directory, cancellationToken);
            }

            // Initialize backup metadata if it doesn't exist
            await InitializeBackupMetadata(cancellationToken);

            // Perform data migration if needed
            if (!await MigrateDataAsync(cancellationToken))
            {
                Log.Error("Data migration failed");
                return false;
            }

            Log.Info("Persistent storage initialized successfully");
            return true;
        }
        catch (Exception ex)
        {
            Log.Error(ex, "Failed to initialize persistent storage");
            return false;
        }
    }

    public async Task<bool> CreateBackupAsync(string backupName, CancellationToken cancellationToken)
    {
        try
        {
            Log.Info($"Creating backup: {backupName}");
            
            var config = configurationProvider.GetServerConfiguration();
            string backupDir = Path.Combine(config.SaveDataPath, BACKUP_DIRECTORY);
            string backupPath = Path.Combine(backupDir, $"{backupName}_{DateTime.UtcNow:yyyyMMdd_HHmmss}.zip");

            // Ensure backup directory exists
            Directory.CreateDirectory(backupDir);

            // Create backup archive
            using (var archive = ZipFile.Open(backupPath, ZipArchiveMode.Create))
            {
                // Backup save files
                if (Directory.Exists(config.SaveDataPath))
                {
                    await AddDirectoryToArchive(archive, config.SaveDataPath, "saves", cancellationToken);
                }

                // Backup configuration
                string configDir = Path.GetDirectoryName(config.ConfigPath);
                if (Directory.Exists(configDir))
                {
                    await AddDirectoryToArchive(archive, configDir, "config", cancellationToken);
                }

                // Add backup metadata
                var backupInfo = new BackupInfo
                {
                    Name = backupName,
                    CreatedAt = DateTime.UtcNow,
                    Type = BackupType.Manual,
                    NitroxVersion = NitroxEnvironment.Version?.ToString() ?? "Unknown",
                    Description = $"Manual backup created at {DateTime.UtcNow:yyyy-MM-dd HH:mm:ss} UTC"
                };

                var metadataEntry = archive.CreateEntry("backup_info.json");
                using (var stream = metadataEntry.Open())
                {
                    await JsonSerializer.SerializeAsync(stream, backupInfo, cancellationToken: cancellationToken);
                }
            }

            // Update backup info with final size
            var fileInfo = new FileInfo(backupPath);
            await UpdateBackupMetadata(backupName, backupPath, fileInfo.Length, cancellationToken);

            Log.Info($"Backup created successfully: {backupPath} ({FormatFileSize(fileInfo.Length)})");
            return true;
        }
        catch (Exception ex)
        {
            Log.Error(ex, $"Failed to create backup: {backupName}");
            return false;
        }
    }

    public async Task<bool> RestoreBackupAsync(string backupName, CancellationToken cancellationToken)
    {
        try
        {
            Log.Info($"Restoring backup: {backupName}");
            
            var config = configurationProvider.GetServerConfiguration();
            string backupDir = Path.Combine(config.SaveDataPath, BACKUP_DIRECTORY);
            
            // Find the backup file
            var backupFiles = Directory.GetFiles(backupDir, $"{backupName}_*.zip");
            if (backupFiles.Length == 0)
            {
                Log.Error($"Backup not found: {backupName}");
                return false;
            }

            string backupPath = backupFiles.OrderByDescending(f => File.GetCreationTime(f)).First();
            
            // Create temporary restore directory
            string tempRestoreDir = Path.Combine(Path.GetTempPath(), $"nitrox_restore_{Guid.NewGuid():N}");
            Directory.CreateDirectory(tempRestoreDir);

            try
            {
                // Extract backup
                ZipFile.ExtractToDirectory(backupPath, tempRestoreDir);

                // Validate backup contents
                if (!await ValidateBackupContents(tempRestoreDir))
                {
                    Log.Error("Backup validation failed");
                    return false;
                }

                // Stop server if running (this would need integration with server management)
                Log.Info("Backup validation successful, proceeding with restore...");

                // Restore save files
                string savesBackupPath = Path.Combine(tempRestoreDir, "saves");
                if (Directory.Exists(savesBackupPath))
                {
                    await RestoreDirectory(savesBackupPath, config.SaveDataPath, cancellationToken);
                }

                // Restore configuration
                string configBackupPath = Path.Combine(tempRestoreDir, "config");
                if (Directory.Exists(configBackupPath))
                {
                    string configDir = Path.GetDirectoryName(config.ConfigPath);
                    await RestoreDirectory(configBackupPath, configDir, cancellationToken);
                }

                Log.Info($"Backup restored successfully: {backupName}");
                return true;
            }
            finally
            {
                // Clean up temporary directory
                try
                {
                    Directory.Delete(tempRestoreDir, true);
                }
                catch (Exception ex)
                {
                    Log.Debug(ex, "Failed to clean up temporary restore directory");
                }
            }
        }
        catch (Exception ex)
        {
            Log.Error(ex, $"Failed to restore backup: {backupName}");
            return false;
        }
    }

    public async Task<BackupInfo[]> GetAvailableBackupsAsync()
    {
        try
        {
            var config = configurationProvider.GetServerConfiguration();
            string backupDir = Path.Combine(config.SaveDataPath, BACKUP_DIRECTORY);
            
            if (!Directory.Exists(backupDir))
            {
                return Array.Empty<BackupInfo>();
            }

            var backups = new List<BackupInfo>();
            var backupFiles = Directory.GetFiles(backupDir, "*.zip");

            foreach (string backupFile in backupFiles)
            {
                try
                {
                    var fileInfo = new FileInfo(backupFile);
                    var backupInfo = await ExtractBackupInfo(backupFile);
                    
                    if (backupInfo != null)
                    {
                        backupInfo.Path = backupFile;
                        backupInfo.SizeBytes = fileInfo.Length;
                        backups.Add(backupInfo);
                    }
                }
                catch (Exception ex)
                {
                    Log.Debug(ex, $"Failed to read backup info from: {backupFile}");
                }
            }

            return backups.OrderByDescending(b => b.CreatedAt).ToArray();
        }
        catch (Exception ex)
        {
            Log.Error(ex, "Failed to get available backups");
            return Array.Empty<BackupInfo>();
        }
    }

    public async Task<int> CleanupOldBackupsAsync(int maxBackups, CancellationToken cancellationToken)
    {
        try
        {
            if (maxBackups <= 0)
            {
                return 0;
            }

            var backups = await GetAvailableBackupsAsync();
            if (backups.Length <= maxBackups)
            {
                return 0;
            }

            var backupsToDelete = backups.Skip(maxBackups).ToArray();
            int deletedCount = 0;

            foreach (var backup in backupsToDelete)
            {
                try
                {
                    File.Delete(backup.Path);
                    deletedCount++;
                    Log.Debug($"Deleted old backup: {backup.Name}");
                }
                catch (Exception ex)
                {
                    Log.Warn(ex, $"Failed to delete backup: {backup.Path}");
                }
            }

            if (deletedCount > 0)
            {
                Log.Info($"Cleaned up {deletedCount} old backups");
            }

            return deletedCount;
        }
        catch (Exception ex)
        {
            Log.Error(ex, "Failed to cleanup old backups");
            return 0;
        }
    }

    public async Task<DataIntegrityStatus> ValidateDataIntegrityAsync()
    {
        var status = new DataIntegrityStatus();
        var issues = new List<string>();

        try
        {
            var config = configurationProvider.GetServerConfiguration();

            // Check save data directory
            if (!Directory.Exists(config.SaveDataPath))
            {
                issues.Add("Save data directory does not exist");
            }
            else
            {
                // Check for critical save files
                var saveFiles = Directory.GetFiles(config.SaveDataPath, "*.nitrox", SearchOption.AllDirectories);
                if (saveFiles.Length == 0)
                {
                    issues.Add("No Nitrox save files found");
                }
            }

            // Check configuration directory
            string configDir = Path.GetDirectoryName(config.ConfigPath);
            if (!Directory.Exists(configDir))
            {
                issues.Add("Configuration directory does not exist");
            }

            // Check file permissions
            try
            {
                await TestDirectoryWriteAccess(config.SaveDataPath, CancellationToken.None);
            }
            catch (Exception ex)
            {
                issues.Add($"Save directory not writable: {ex.Message}");
            }

            status.IsValid = issues.Count == 0;
            status.Issues = issues.ToArray();
            status.Details = $"Checked {config.SaveDataPath} and {configDir}";

            return status;
        }
        catch (Exception ex)
        {
            Log.Error(ex, "Error during data integrity validation");
            status.IsValid = false;
            status.Issues = new[] { $"Validation error: {ex.Message}" };
            return status;
        }
    }

    public async Task<bool> MigrateDataAsync(CancellationToken cancellationToken)
    {
        try
        {
            // For now, just return true as no migration is needed
            // This method can be expanded in the future for version migrations
            Log.Debug("Data migration check completed - no migration needed");
            return true;
        }
        catch (Exception ex)
        {
            Log.Error(ex, "Data migration failed");
            return false;
        }
    }

    private async Task TestDirectoryWriteAccess(string directory, CancellationToken cancellationToken)
    {
        string testFile = Path.Combine(directory, $".write_test_{Guid.NewGuid():N}");
        try
        {
            await File.WriteAllTextAsync(testFile, "test", cancellationToken);
            File.Delete(testFile);
        }
        catch (Exception ex)
        {
            throw new UnauthorizedAccessException($"Directory {directory} is not writable", ex);
        }
    }

    private async Task InitializeBackupMetadata(CancellationToken cancellationToken)
    {
        var config = configurationProvider.GetServerConfiguration();
        string backupDir = Path.Combine(config.SaveDataPath, BACKUP_DIRECTORY);
        string metadataPath = Path.Combine(backupDir, BACKUP_METADATA_FILE);

        if (!File.Exists(metadataPath))
        {
            var metadata = new { initialized = DateTime.UtcNow, version = "1.0" };
            await File.WriteAllTextAsync(metadataPath, JsonSerializer.Serialize(metadata), cancellationToken);
        }
    }

    private async Task AddDirectoryToArchive(ZipArchive archive, string sourceDir, string entryPrefix, CancellationToken cancellationToken)
    {
        var files = Directory.GetFiles(sourceDir, "*", SearchOption.AllDirectories);
        
        foreach (string file in files)
        {
            // Skip backup directory to avoid recursion
            if (file.Contains(BACKUP_DIRECTORY))
                continue;

            string relativePath = Path.GetRelativePath(sourceDir, file);
            string entryName = Path.Combine(entryPrefix, relativePath).Replace('\\', '/');
            
            var entry = archive.CreateEntry(entryName);
            using (var entryStream = entry.Open())
            using (var fileStream = File.OpenRead(file))
            {
                await fileStream.CopyToAsync(entryStream, cancellationToken);
            }
        }
    }

    private async Task<bool> ValidateBackupContents(string backupDir)
    {
        // Check if backup info exists
        string backupInfoPath = Path.Combine(backupDir, "backup_info.json");
        if (!File.Exists(backupInfoPath))
        {
            Log.Warn("Backup validation: backup_info.json not found");
            return false;
        }

        // Check if saves directory exists
        string savesDir = Path.Combine(backupDir, "saves");
        if (!Directory.Exists(savesDir))
        {
            Log.Warn("Backup validation: saves directory not found");
            return false;
        }

        return true;
    }

    private async Task RestoreDirectory(string sourceDir, string targetDir, CancellationToken cancellationToken)
    {
        // Create target directory if it doesn't exist
        Directory.CreateDirectory(targetDir);

        var files = Directory.GetFiles(sourceDir, "*", SearchOption.AllDirectories);
        
        foreach (string file in files)
        {
            string relativePath = Path.GetRelativePath(sourceDir, file);
            string targetPath = Path.Combine(targetDir, relativePath);
            
            // Create target subdirectory if needed
            string targetSubDir = Path.GetDirectoryName(targetPath);
            if (!Directory.Exists(targetSubDir))
            {
                Directory.CreateDirectory(targetSubDir);
            }

            // Copy file
            using (var sourceStream = File.OpenRead(file))
            using (var targetStream = File.Create(targetPath))
            {
                await sourceStream.CopyToAsync(targetStream, cancellationToken);
            }
        }
    }

    private async Task<BackupInfo> ExtractBackupInfo(string backupPath)
    {
        try
        {
            using (var archive = ZipFile.OpenRead(backupPath))
            {
                var infoEntry = archive.GetEntry("backup_info.json");
                if (infoEntry != null)
                {
                    using (var stream = infoEntry.Open())
                    {
                        return await JsonSerializer.DeserializeAsync<BackupInfo>(stream);
                    }
                }
            }

            // Fallback: create backup info from filename
            var fileInfo = new FileInfo(backupPath);
            return new BackupInfo
            {
                Name = Path.GetFileNameWithoutExtension(backupPath),
                CreatedAt = fileInfo.CreationTime,
                SizeBytes = fileInfo.Length,
                Type = BackupType.Manual,
                Description = "Legacy backup (no metadata)"
            };
        }
        catch (Exception ex)
        {
            Log.Debug(ex, $"Failed to extract backup info from: {backupPath}");
            return null;
        }
    }

    private async Task UpdateBackupMetadata(string backupName, string backupPath, long sizeBytes, CancellationToken cancellationToken)
    {
        // This method could be used to maintain a backup registry
        // For now, we rely on individual backup metadata within each archive
    }

    private static string FormatFileSize(long bytes)
    {
        string[] suffixes = { "B", "KB", "MB", "GB", "TB" };
        int counter = 0;
        decimal number = bytes;
        
        while (Math.Round(number / 1024) >= 1)
        {
            number /= 1024;
            counter++;
        }
        
        return $"{number:n1} {suffixes[counter]}";
    }
}