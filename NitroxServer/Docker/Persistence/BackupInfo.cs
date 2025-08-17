using System;

namespace NitroxServer.Docker.Persistence;

/// <summary>
/// Information about a server data backup
/// </summary>
public class BackupInfo
{
    /// <summary>
    /// Name of the backup
    /// </summary>
    public string Name { get; set; } = "";

    /// <summary>
    /// When the backup was created
    /// </summary>
    public DateTime CreatedAt { get; set; }

    /// <summary>
    /// Size of the backup in bytes
    /// </summary>
    public long SizeBytes { get; set; }

    /// <summary>
    /// Path to the backup file or directory
    /// </summary>
    public string Path { get; set; } = "";

    /// <summary>
    /// Type of backup (full, incremental, etc.)
    /// </summary>
    public BackupType Type { get; set; } = BackupType.Full;

    /// <summary>
    /// Version of Nitrox that created this backup
    /// </summary>
    public string NitroxVersion { get; set; } = "";

    /// <summary>
    /// Whether the backup is valid and can be restored
    /// </summary>
    public bool IsValid { get; set; } = true;

    /// <summary>
    /// Additional metadata about the backup
    /// </summary>
    public string Description { get; set; } = "";

    /// <summary>
    /// Get a human-readable summary of the backup
    /// </summary>
    /// <returns>Backup summary string</returns>
    public string GetSummary()
    {
        string sizeStr = FormatFileSize(SizeBytes);
        return $"{Name} ({sizeStr}) - {CreatedAt:yyyy-MM-dd HH:mm:ss} UTC";
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

/// <summary>
/// Type of backup
/// </summary>
public enum BackupType
{
    Full,
    Incremental,
    Differential,
    Manual
}

/// <summary>
/// Status of data integrity validation
/// </summary>
public class DataIntegrityStatus
{
    /// <summary>
    /// Whether data integrity is valid
    /// </summary>
    public bool IsValid { get; set; } = true;

    /// <summary>
    /// List of integrity issues found
    /// </summary>
    public string[] Issues { get; set; } = Array.Empty<string>();

    /// <summary>
    /// When the integrity check was performed
    /// </summary>
    public DateTime CheckedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// Additional details about the integrity check
    /// </summary>
    public string Details { get; set; } = "";

    /// <summary>
    /// Get a summary of the integrity status
    /// </summary>
    /// <returns>Integrity summary string</returns>
    public string GetSummary()
    {
        if (IsValid)
        {
            return "Data integrity is valid";
        }

        return $"Data integrity issues found: {string.Join(", ", Issues)}";
    }
}