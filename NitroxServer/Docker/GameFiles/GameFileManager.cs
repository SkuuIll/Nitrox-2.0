using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Threading;
using System.Threading.Tasks;
using NitroxModel;
using NitroxModel.Logger;

namespace NitroxServer.Docker.GameFiles;

/// <summary>
/// Manages Subnautica game file downloading, validation, and caching for Docker deployment
/// </summary>
public class GameFileManager : IGameFileManager
{
    private const int SUBNAUTICA_APP_ID = 264710;
    private const string STEAMCMD_PATH = "/app/steamcmd/steamcmd.sh";
    
    // Critical files that must exist for Nitrox to work
    private static readonly string[] RequiredFiles = {
        "Subnautica.exe",
        "Subnautica_Data/Managed/Assembly-CSharp.dll",
        "Subnautica_Data/Managed/UnityEngine.dll",
        "Subnautica_Data/Managed/UnityEngine.CoreModule.dll",
        "Subnautica_Data/Managed/Newtonsoft.Json.dll",
        "Subnautica_Data/StreamingAssets/SNUnmanagedData/BuildInfo.json"
    };

    public async Task<bool> EnsureGameFilesAsync(string targetPath, CancellationToken cancellationToken)
    {
        try
        {
            Log.Info($"Ensuring game files are available at: {targetPath}");

            // First check if files already exist and are valid
            var status = await GetGameFileStatusAsync(targetPath);
            if (status.IsValid && status.IsComplete)
            {
                Log.Info("Game files are already present and valid");
                return true;
            }

            // Check if Steam download is enabled
            string enableSteamDownload = Environment.GetEnvironmentVariable("NITROX_ENABLE_STEAM_DOWNLOAD") ?? "true";
            if (!bool.Parse(enableSteamDownload))
            {
                Log.Error("Game files not found and Steam download is disabled");
                return false;
            }

            // Get Steam credentials
            string steamUsername = Environment.GetEnvironmentVariable("STEAM_USERNAME");
            string steamPassword = Environment.GetEnvironmentVariable("STEAM_PASSWORD");

            if (string.IsNullOrWhiteSpace(steamUsername) || string.IsNullOrWhiteSpace(steamPassword))
            {
                Log.Error("Steam credentials are required for game file download");
                Log.Error("Please set STEAM_USERNAME and STEAM_PASSWORD environment variables");
                return false;
            }

            // Download game files
            Log.Info("Downloading game files via SteamCMD...");
            return await DownloadGameFilesAsync(targetPath, steamUsername, steamPassword, cancellationToken);
        }
        catch (Exception ex)
        {
            Log.Error(ex, "Failed to ensure game files are available");
            return false;
        }
    }

    public async Task<bool> ValidateGameFilesAsync(string gamePath)
    {
        try
        {
            var status = await GetGameFileStatusAsync(gamePath);
            return status.IsValid && status.IsComplete;
        }
        catch (Exception ex)
        {
            Log.Error(ex, $"Failed to validate game files at: {gamePath}");
            return false;
        }
    }

    public async Task<GameFileStatus> GetGameFileStatusAsync(string gamePath)
    {
        var status = new GameFileStatus
        {
            LastValidated = DateTime.UtcNow,
            SteamDownloadAvailable = File.Exists(STEAMCMD_PATH)
        };

        try
        {
            if (!Directory.Exists(gamePath))
            {
                status.ValidationMessages.Add("Game directory does not exist");
                return status;
            }

            // Check for required files
            foreach (string requiredFile in RequiredFiles)
            {
                string fullPath = Path.Combine(gamePath, requiredFile);
                if (!File.Exists(fullPath))
                {
                    status.MissingFiles.Add(requiredFile);
                }
            }

            // Calculate total size
            if (Directory.Exists(gamePath))
            {
                var directoryInfo = new DirectoryInfo(gamePath);
                status.TotalSize = await Task.Run(() => 
                    directoryInfo.GetFiles("*", SearchOption.AllDirectories)
                                .Sum(file => file.Length));
            }

            // Try to detect game version
            string buildInfoPath = Path.Combine(gamePath, "Subnautica_Data/StreamingAssets/SNUnmanagedData/BuildInfo.json");
            if (File.Exists(buildInfoPath))
            {
                try
                {
                    string buildInfo = await File.ReadAllTextAsync(buildInfoPath);
                    // Simple version extraction - could be enhanced with JSON parsing
                    if (buildInfo.Contains("\"Version\""))
                    {
                        status.GameVersion = "Detected";
                    }
                }
                catch (Exception ex)
                {
                    Log.Debug(ex, "Failed to read build info");
                }
            }

            // Validate critical assemblies
            await ValidateCriticalAssemblies(gamePath, status);

            status.IsComplete = status.MissingFiles.Count == 0;
            status.IsValid = status.IsComplete && status.CorruptedFiles.Count == 0;

            if (status.IsValid)
            {
                status.ValidationMessages.Add("All game files are present and valid");
            }
            else
            {
                if (status.MissingFiles.Count > 0)
                {
                    status.ValidationMessages.Add($"Missing {status.MissingFiles.Count} required files");
                }
                if (status.CorruptedFiles.Count > 0)
                {
                    status.ValidationMessages.Add($"Found {status.CorruptedFiles.Count} corrupted files");
                }
            }

            return status;
        }
        catch (Exception ex)
        {
            Log.Error(ex, "Error during game file status check");
            status.ValidationMessages.Add($"Validation error: {ex.Message}");
            return status;
        }
    }

    public async Task<bool> DownloadGameFilesAsync(string targetPath, string username, string password, CancellationToken cancellationToken)
    {
        try
        {
            if (!File.Exists(STEAMCMD_PATH))
            {
                Log.Error($"SteamCMD not found at: {STEAMCMD_PATH}");
                return false;
            }

            // Ensure target directory exists
            Directory.CreateDirectory(targetPath);

            // Create SteamCMD script
            string scriptPath = Path.Combine(Path.GetTempPath(), $"download_subnautica_{Guid.NewGuid():N}.txt");
            
            await File.WriteAllTextAsync(scriptPath, $@"@ShutdownOnFailedCommand 1
@NoPromptForPassword 1
login {username} {password}
force_install_dir {targetPath}
app_update {SUBNAUTICA_APP_ID} validate
quit", cancellationToken);

            try
            {
                // Execute SteamCMD with retry logic
                const int maxRetries = 3;
                for (int attempt = 1; attempt <= maxRetries; attempt++)
                {
                    Log.Info($"Starting SteamCMD download attempt {attempt}/{maxRetries}");

                    var processInfo = new ProcessStartInfo
                    {
                        FileName = STEAMCMD_PATH,
                        Arguments = $"+runscript {scriptPath}",
                        UseShellExecute = false,
                        RedirectStandardOutput = true,
                        RedirectStandardError = true,
                        CreateNoWindow = true
                    };

                    using var process = new Process { StartInfo = processInfo };
                    
                    var outputBuilder = new System.Text.StringBuilder();
                    var errorBuilder = new System.Text.StringBuilder();

                    process.OutputDataReceived += (sender, e) =>
                    {
                        if (!string.IsNullOrEmpty(e.Data))
                        {
                            outputBuilder.AppendLine(e.Data);
                            Log.Debug($"SteamCMD: {e.Data}");
                        }
                    };

                    process.ErrorDataReceived += (sender, e) =>
                    {
                        if (!string.IsNullOrEmpty(e.Data))
                        {
                            errorBuilder.AppendLine(e.Data);
                            Log.Warn($"SteamCMD Error: {e.Data}");
                        }
                    };

                    process.Start();
                    process.BeginOutputReadLine();
                    process.BeginErrorReadLine();

                    // Wait for completion with cancellation support
                    while (!process.HasExited)
                    {
                        if (cancellationToken.IsCancellationRequested)
                        {
                            Log.Warn("Download cancelled, terminating SteamCMD process");
                            process.Kill();
                            return false;
                        }
                        await Task.Delay(1000, cancellationToken);
                    }

                    if (process.ExitCode == 0)
                    {
                        Log.Info("SteamCMD download completed successfully");
                        
                        // Verify the download
                        if (await ValidateGameFilesAsync(targetPath))
                        {
                            Log.Info("Game files downloaded and validated successfully");
                            return true;
                        }
                        else
                        {
                            Log.Warn("Downloaded files failed validation");
                        }
                    }
                    else
                    {
                        Log.Error($"SteamCMD exited with code: {process.ExitCode}");
                        Log.Error($"SteamCMD output: {outputBuilder}");
                        Log.Error($"SteamCMD errors: {errorBuilder}");
                    }

                    if (attempt < maxRetries)
                    {
                        Log.Info($"Retrying download in 30 seconds...");
                        await Task.Delay(30000, cancellationToken);
                    }
                }

                Log.Error($"Failed to download game files after {maxRetries} attempts");
                return false;
            }
            finally
            {
                // Clean up script file
                try
                {
                    File.Delete(scriptPath);
                }
                catch (Exception ex)
                {
                    Log.Debug(ex, "Failed to delete SteamCMD script file");
                }
            }
        }
        catch (Exception ex)
        {
            Log.Error(ex, "Error during game file download");
            return false;
        }
    }

    private async Task ValidateCriticalAssemblies(string gamePath, GameFileStatus status)
    {
        try
        {
            // Check Assembly-CSharp.dll specifically as it's critical for Nitrox
            string assemblyCSharpPath = Path.Combine(gamePath, "Subnautica_Data/Managed/Assembly-CSharp.dll");
            if (File.Exists(assemblyCSharpPath))
            {
                var fileInfo = new FileInfo(assemblyCSharpPath);
                
                // Basic size check - Assembly-CSharp.dll should be substantial
                if (fileInfo.Length < 1024 * 1024) // Less than 1MB is suspicious
                {
                    status.CorruptedFiles.Add("Subnautica_Data/Managed/Assembly-CSharp.dll");
                    status.ValidationMessages.Add("Assembly-CSharp.dll appears to be corrupted (too small)");
                }
                else
                {
                    // Try to calculate checksum for integrity
                    try
                    {
                        using var stream = File.OpenRead(assemblyCSharpPath);
                        using var sha256 = SHA256.Create();
                        byte[] hash = await Task.Run(() => sha256.ComputeHash(stream));
                        
                        // We don't have reference checksums, but we can at least verify the file is readable
                        Log.Debug($"Assembly-CSharp.dll checksum calculated successfully");
                    }
                    catch (Exception ex)
                    {
                        Log.Debug(ex, "Failed to calculate checksum for Assembly-CSharp.dll");
                        status.CorruptedFiles.Add("Subnautica_Data/Managed/Assembly-CSharp.dll");
                        status.ValidationMessages.Add("Assembly-CSharp.dll failed integrity check");
                    }
                }
            }
        }
        catch (Exception ex)
        {
            Log.Debug(ex, "Error during assembly validation");
        }
    }
}