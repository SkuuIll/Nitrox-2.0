using System;
using System.Collections.Generic;

namespace NitroxServer.Docker.GameFiles;

/// <summary>
/// Represents the status and validation information for Subnautica game files
/// </summary>
public class GameFileStatus
{
    /// <summary>
    /// Whether the game files are valid and complete
    /// </summary>
    public bool IsValid { get; set; }

    /// <summary>
    /// Whether all required files are present
    /// </summary>
    public bool IsComplete { get; set; }

    /// <summary>
    /// When the files were last validated
    /// </summary>
    public DateTime LastValidated { get; set; }

    /// <summary>
    /// Total size of game files in bytes
    /// </summary>
    public long TotalSize { get; set; }

    /// <summary>
    /// List of missing required files
    /// </summary>
    public List<string> MissingFiles { get; set; } = new();

    /// <summary>
    /// List of corrupted files (failed checksum validation)
    /// </summary>
    public List<string> CorruptedFiles { get; set; } = new();

    /// <summary>
    /// Additional validation messages
    /// </summary>
    public List<string> ValidationMessages { get; set; } = new();

    /// <summary>
    /// Game version detected from files
    /// </summary>
    public string? GameVersion { get; set; }

    /// <summary>
    /// Whether Steam download is available/configured
    /// </summary>
    public bool SteamDownloadAvailable { get; set; }

    /// <summary>
    /// Get a human-readable summary of the status
    /// </summary>
    public string GetSummary()
    {
        if (IsValid && IsComplete)
        {
            return $"Game files are valid and complete ({FormatFileSize(TotalSize)})";
        }

        var issues = new List<string>();
        
        if (MissingFiles.Count > 0)
        {
            issues.Add($"{MissingFiles.Count} missing files");
        }
        
        if (CorruptedFiles.Count > 0)
        {
            issues.Add($"{CorruptedFiles.Count} corrupted files");
        }

        return issues.Count > 0 ? $"Issues found: {string.Join(", ", issues)}" : "Unknown validation status";
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