using System;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using NitroxServer.Docker.Configuration;
using NitroxServer.Docker.GameFiles;
using NitroxServer.Docker.Health;
using NitroxServer.Docker.Persistence;
using NitroxServer.Docker.Security;

namespace NitroxServer.Docker.Tests;

[TestClass]
public class DockerIntegrationTests
{
    private string testDataDirectory;
    private DockerConfigurationProvider configurationProvider;
    private GameFileManager gameFileManager;
    private ContainerHealthService healthService;
    private DataPersistenceManager persistenceManager;
    private SecurityManager securityManager;

    [TestInitialize]
    public void Setup()
    {
        // Create temporary test directory
        testDataDirectory = Path.Combine(Path.GetTempPath(), $"nitrox_test_{Guid.NewGuid():N}");
        Directory.CreateDirectory(testDataDirectory);

        // Set up test environment variables
        Environment.SetEnvironmentVariable("NITROX_GAME_FILES_PATH", Path.Combine(testDataDirectory, "gamefiles"));
        Environment.SetEnvironmentVariable("NITROX_SAVE_DATA_PATH", Path.Combine(testDataDirectory, "saves"));
        Environment.SetEnvironmentVariable("NITROX_CONFIG_PATH", Path.Combine(testDataDirectory, "config", "server.cfg"));
        Environment.SetEnvironmentVariable("NITROX_ADMIN_PASSWORD", "test_admin_password_123");
        Environment.SetEnvironmentVariable("NITROX_SERVER_NAME", "Test Server");
        Environment.SetEnvironmentVariable("NITROX_ENABLE_STEAM_DOWNLOAD", "false");

        // Initialize services
        configurationProvider = new DockerConfigurationProvider();
        gameFileManager = new GameFileManager();
        healthService = new ContainerHealthService(configurationProvider, gameFileManager);
        persistenceManager = new DataPersistenceManager(configurationProvider);
        securityManager = new SecurityManager(configurationProvider);
    }

    [TestCleanup]
    public void Cleanup()
    {
        // Clean up test directory
        if (Directory.Exists(testDataDirectory))
        {
            try
            {
                Directory.Delete(testDataDirectory, true);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Failed to cleanup test directory: {ex.Message}");
            }
        }

        // Clean up environment variables
        Environment.SetEnvironmentVariable("NITROX_GAME_FILES_PATH", null);
        Environment.SetEnvironmentVariable("NITROX_SAVE_DATA_PATH", null);
        Environment.SetEnvironmentVariable("NITROX_CONFIG_PATH", null);
        Environment.SetEnvironmentVariable("NITROX_ADMIN_PASSWORD", null);
        Environment.SetEnvironmentVariable("NITROX_SERVER_NAME", null);
        Environment.SetEnvironmentVariable("NITROX_ENABLE_STEAM_DOWNLOAD", null);
    }

    [TestMethod]
    public void ConfigurationProvider_LoadsEnvironmentVariables_Successfully()
    {
        // Act
        var config = configurationProvider.GetServerConfiguration();

        // Assert
        Assert.AreEqual("Test Server", config.ServerName);
        Assert.AreEqual("test_admin_password_123", config.AdminPassword);
        Assert.AreEqual(false, config.EnableSteamDownload);
        Assert.IsTrue(config.GameFilesPath.Contains("gamefiles"));
        Assert.IsTrue(config.SaveDataPath.Contains("saves"));
    }

    [TestMethod]
    public void ConfigurationProvider_ValidatesConfiguration_Successfully()
    {
        // Act
        bool isValid = configurationProvider.ValidateConfiguration(out var errors);

        // Assert
        Assert.IsTrue(isValid, $"Configuration validation failed: {string.Join(", ", errors)}");
        Assert.AreEqual(0, errors.Count);
    }

    [TestMethod]
    public void ConfigurationProvider_DetectsInvalidConfiguration()
    {
        // Arrange
        Environment.SetEnvironmentVariable("NITROX_ADMIN_PASSWORD", "123"); // Too short

        var provider = new DockerConfigurationProvider();

        // Act
        bool isValid = provider.ValidateConfiguration(out var errors);

        // Assert
        Assert.IsFalse(isValid);
        Assert.IsTrue(errors.Count > 0);
        Assert.IsTrue(errors.Exists(e => e.Contains("Admin password")));
    }

    [TestMethod]
    public async Task PersistenceManager_InitializesStorage_Successfully()
    {
        // Act
        bool result = await persistenceManager.InitializePersistentStorageAsync(CancellationToken.None);

        // Assert
        Assert.IsTrue(result);
        
        var config = configurationProvider.GetServerConfiguration();
        Assert.IsTrue(Directory.Exists(config.SaveDataPath));
        Assert.IsTrue(Directory.Exists(Path.GetDirectoryName(config.ConfigPath)));
    }

    [TestMethod]
    public async Task PersistenceManager_CreatesAndRestoresBackup_Successfully()
    {
        // Arrange
        await persistenceManager.InitializePersistentStorageAsync(CancellationToken.None);
        
        var config = configurationProvider.GetServerConfiguration();
        var testFile = Path.Combine(config.SaveDataPath, "test_save.dat");
        await File.WriteAllTextAsync(testFile, "test data");

        // Act - Create backup
        bool backupResult = await persistenceManager.CreateBackupAsync("test_backup", CancellationToken.None);
        
        // Delete original file
        File.Delete(testFile);
        
        // Restore backup
        bool restoreResult = await persistenceManager.RestoreBackupAsync("test_backup", CancellationToken.None);

        // Assert
        Assert.IsTrue(backupResult);
        Assert.IsTrue(restoreResult);
        Assert.IsTrue(File.Exists(testFile));
        
        var restoredContent = await File.ReadAllTextAsync(testFile);
        Assert.AreEqual("test data", restoredContent);
    }

    [TestMethod]
    public async Task PersistenceManager_ValidatesDataIntegrity_Successfully()
    {
        // Arrange
        await persistenceManager.InitializePersistentStorageAsync(CancellationToken.None);

        // Act
        var integrityStatus = await persistenceManager.ValidateDataIntegrityAsync();

        // Assert
        Assert.IsNotNull(integrityStatus);
        Assert.IsTrue(integrityStatus.IsValid);
        Assert.AreEqual(0, integrityStatus.Issues.Length);
    }

    [TestMethod]
    public async Task GameFileManager_ValidatesGameFiles_WithoutSteamDownload()
    {
        // Arrange
        var config = configurationProvider.GetServerConfiguration();
        Directory.CreateDirectory(config.GameFilesPath);

        // Act
        var status = await gameFileManager.GetGameFileStatusAsync(config.GameFilesPath);

        // Assert
        Assert.IsNotNull(status);
        Assert.IsFalse(status.IsValid); // Should be invalid without game files
        Assert.IsFalse(status.IsComplete);
        Assert.IsTrue(status.MissingFiles.Count > 0);
    }

    [TestMethod]
    public async Task GameFileManager_EnsuresGameFiles_SkipsDownloadWhenDisabled()
    {
        // Arrange
        var config = configurationProvider.GetServerConfiguration();
        Directory.CreateDirectory(config.GameFilesPath);

        // Act
        bool result = await gameFileManager.EnsureGameFilesAsync(config.GameFilesPath, CancellationToken.None);

        // Assert
        Assert.IsFalse(result); // Should fail when Steam download is disabled and no files exist
    }

    [TestMethod]
    public async Task HealthService_PerformsHealthCheck_Successfully()
    {
        // Arrange
        await persistenceManager.InitializePersistentStorageAsync(CancellationToken.None);

        // Act
        var healthStatus = await healthService.CheckHealthAsync();

        // Assert
        Assert.IsNotNull(healthStatus);
        Assert.IsTrue(healthStatus.ComponentHealths.Count > 0);
        Assert.IsTrue(healthStatus.CheckDurationMs > 0);
    }

    [TestMethod]
    public async Task HealthService_CollectsMetrics_Successfully()
    {
        // Act
        var metrics = await healthService.GetMetricsAsync();

        // Assert
        Assert.IsNotNull(metrics);
        Assert.IsTrue(metrics.Count > 0);
        Assert.IsTrue(metrics.ContainsKey("process_id"));
        Assert.IsTrue(metrics.ContainsKey("server_name"));
    }

    [TestMethod]
    public async Task SecurityManager_InitializesSecurity_Successfully()
    {
        // Arrange
        await persistenceManager.InitializePersistentStorageAsync(CancellationToken.None);

        // Act
        bool result = await securityManager.InitializeSecurityAsync(CancellationToken.None);

        // Assert
        Assert.IsTrue(result);
    }

    [TestMethod]
    public async Task SecurityManager_ValidatesSecurity_Successfully()
    {
        // Arrange
        await persistenceManager.InitializePersistentStorageAsync(CancellationToken.None);

        // Act
        var validationResult = await securityManager.ValidateSecurityAsync();

        // Assert
        Assert.IsNotNull(validationResult);
        Assert.IsTrue(validationResult.SecurityScore > 0);
    }

    [TestMethod]
    public async Task SecurityManager_GeneratesRecommendations_Successfully()
    {
        // Act
        var recommendations = await securityManager.GetSecurityRecommendationsAsync();

        // Assert
        Assert.IsNotNull(recommendations);
        Assert.IsTrue(recommendations.Length > 0);
    }

    [TestMethod]
    public async Task SecurityManager_PerformsAudit_Successfully()
    {
        // Act
        var auditResult = await securityManager.PerformSecurityAuditAsync();

        // Assert
        Assert.IsNotNull(auditResult);
        Assert.IsTrue(auditResult.AuditedAt > DateTime.MinValue);
        Assert.IsNotNull(auditResult.Findings);
        Assert.IsNotNull(auditResult.ComplianceStatus);
        Assert.IsNotNull(auditResult.SecurityMetrics);
    }

    [TestMethod]
    public async Task IntegrationTest_FullInitializationSequence_Succeeds()
    {
        // This test simulates the full container initialization sequence

        // Act & Assert - Step by step initialization
        
        // 1. Initialize persistence
        bool persistenceInit = await persistenceManager.InitializePersistentStorageAsync(CancellationToken.None);
        Assert.IsTrue(persistenceInit, "Persistence initialization failed");

        // 2. Initialize security
        bool securityInit = await securityManager.InitializeSecurityAsync(CancellationToken.None);
        Assert.IsTrue(securityInit, "Security initialization failed");

        // 3. Validate configuration
        bool configValid = configurationProvider.ValidateConfiguration(out var errors);
        Assert.IsTrue(configValid, $"Configuration validation failed: {string.Join(", ", errors)}");

        // 4. Check health
        var healthStatus = await healthService.CheckHealthAsync();
        Assert.IsNotNull(healthStatus, "Health check failed");

        // 5. Validate data integrity
        var integrityStatus = await persistenceManager.ValidateDataIntegrityAsync();
        Assert.IsTrue(integrityStatus.IsValid, "Data integrity validation failed");

        // 6. Security validation
        var securityStatus = await securityManager.ValidateSecurityAsync();
        Assert.IsNotNull(securityStatus, "Security validation failed");

        Console.WriteLine("Full initialization sequence completed successfully");
        Console.WriteLine($"Health Status: {healthStatus.GetSummary()}");
        Console.WriteLine($"Security Score: {securityStatus.SecurityScore}/100");
        Console.WriteLine($"Data Integrity: {integrityStatus.GetSummary()}");
    }
}