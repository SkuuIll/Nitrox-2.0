using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using NitroxServer.Docker.Configuration;
using NitroxServer.Docker.Health;
using NitroxServer.Docker.Persistence;

namespace NitroxServer.Docker.Tests;

[TestClass]
public class DockerPerformanceTests
{
    private string testDataDirectory;
    private DockerConfigurationProvider configurationProvider;
    private ContainerHealthService healthService;
    private DataPersistenceManager persistenceManager;

    [TestInitialize]
    public void Setup()
    {
        testDataDirectory = Path.Combine(Path.GetTempPath(), $"nitrox_perf_test_{Guid.NewGuid():N}");
        Directory.CreateDirectory(testDataDirectory);

        Environment.SetEnvironmentVariable("NITROX_GAME_FILES_PATH", Path.Combine(testDataDirectory, "gamefiles"));
        Environment.SetEnvironmentVariable("NITROX_SAVE_DATA_PATH", Path.Combine(testDataDirectory, "saves"));
        Environment.SetEnvironmentVariable("NITROX_CONFIG_PATH", Path.Combine(testDataDirectory, "config", "server.cfg"));
        Environment.SetEnvironmentVariable("NITROX_ADMIN_PASSWORD", "test_admin_password_123");
        Environment.SetEnvironmentVariable("NITROX_ENABLE_STEAM_DOWNLOAD", "false");

        configurationProvider = new DockerConfigurationProvider();
        healthService = new ContainerHealthService(configurationProvider, null);
        persistenceManager = new DataPersistenceManager(configurationProvider);
    }

    [TestCleanup]
    public void Cleanup()
    {
        if (Directory.Exists(testDataDirectory))
        {
            try
            {
                Directory.Delete(testDataDirectory, true);
            }
            catch { }
        }

        Environment.SetEnvironmentVariable("NITROX_GAME_FILES_PATH", null);
        Environment.SetEnvironmentVariable("NITROX_SAVE_DATA_PATH", null);
        Environment.SetEnvironmentVariable("NITROX_CONFIG_PATH", null);
        Environment.SetEnvironmentVariable("NITROX_ADMIN_PASSWORD", null);
        Environment.SetEnvironmentVariable("NITROX_ENABLE_STEAM_DOWNLOAD", null);
    }

    [TestMethod]
    public async Task HealthCheck_Performance_MeetsRequirements()
    {
        // Arrange
        await persistenceManager.InitializePersistentStorageAsync(CancellationToken.None);
        const int iterations = 10;
        var durations = new List<long>();

        // Act
        for (int i = 0; i < iterations; i++)
        {
            var stopwatch = Stopwatch.StartNew();
            await healthService.CheckHealthAsync();
            stopwatch.Stop();
            durations.Add(stopwatch.ElapsedMilliseconds);
        }

        // Assert
        var averageDuration = durations.Sum() / (double)durations.Count;
        var maxDuration = durations.Max();

        Console.WriteLine($"Health check performance:");
        Console.WriteLine($"  Average: {averageDuration:F2}ms");
        Console.WriteLine($"  Maximum: {maxDuration}ms");
        Console.WriteLine($"  Minimum: {durations.Min()}ms");

        // Health checks should complete within reasonable time
        Assert.IsTrue(averageDuration < 1000, $"Average health check duration ({averageDuration:F2}ms) exceeds 1000ms");
        Assert.IsTrue(maxDuration < 2000, $"Maximum health check duration ({maxDuration}ms) exceeds 2000ms");
    }

    [TestMethod]
    public async Task ConfigurationLoading_Performance_MeetsRequirements()
    {
        // Arrange
        const int iterations = 100;
        var durations = new List<long>();

        // Act
        for (int i = 0; i < iterations; i++)
        {
            var stopwatch = Stopwatch.StartNew();
            var config = configurationProvider.GetServerConfiguration();
            stopwatch.Stop();
            durations.Add(stopwatch.ElapsedMilliseconds);
        }

        // Assert
        var averageDuration = durations.Sum() / (double)durations.Count;
        var maxDuration = durations.Max();

        Console.WriteLine($"Configuration loading performance:");
        Console.WriteLine($"  Average: {averageDuration:F2}ms");
        Console.WriteLine($"  Maximum: {maxDuration}ms");

        // Configuration loading should be very fast
        Assert.IsTrue(averageDuration < 10, $"Average configuration loading ({averageDuration:F2}ms) exceeds 10ms");
        Assert.IsTrue(maxDuration < 50, $"Maximum configuration loading ({maxDuration}ms) exceeds 50ms");
    }

    [TestMethod]
    public async Task BackupCreation_Performance_WithLargeDataset()
    {
        // Arrange
        await persistenceManager.InitializePersistentStorageAsync(CancellationToken.None);
        
        var config = configurationProvider.GetServerConfiguration();
        
        // Create test data (simulate save files)
        var testDataSize = 10 * 1024 * 1024; // 10MB
        var testData = new byte[testDataSize];
        Random.Shared.NextBytes(testData);
        
        for (int i = 0; i < 5; i++)
        {
            var testFile = Path.Combine(config.SaveDataPath, $"test_save_{i}.dat");
            await File.WriteAllBytesAsync(testFile, testData);
        }

        // Act
        var stopwatch = Stopwatch.StartNew();
        bool result = await persistenceManager.CreateBackupAsync("performance_test", CancellationToken.None);
        stopwatch.Stop();

        // Assert
        Assert.IsTrue(result);
        
        var backupDuration = stopwatch.ElapsedMilliseconds;
        var dataProcessed = testDataSize * 5; // 5 files
        var throughputMBps = (dataProcessed / 1024.0 / 1024.0) / (backupDuration / 1000.0);

        Console.WriteLine($"Backup performance:");
        Console.WriteLine($"  Duration: {backupDuration}ms");
        Console.WriteLine($"  Data processed: {dataProcessed / 1024 / 1024}MB");
        Console.WriteLine($"  Throughput: {throughputMBps:F2} MB/s");

        // Backup should complete within reasonable time (allow for slower systems)
        Assert.IsTrue(backupDuration < 30000, $"Backup duration ({backupDuration}ms) exceeds 30 seconds");
        Assert.IsTrue(throughputMBps > 1.0, $"Backup throughput ({throughputMBps:F2} MB/s) is too low");
    }

    [TestMethod]
    public async Task ConcurrentHealthChecks_Performance_MeetsRequirements()
    {
        // Arrange
        await persistenceManager.InitializePersistentStorageAsync(CancellationToken.None);
        const int concurrentChecks = 10;
        
        // Act
        var stopwatch = Stopwatch.StartNew();
        
        var tasks = new List<Task>();
        for (int i = 0; i < concurrentChecks; i++)
        {
            tasks.Add(healthService.CheckHealthAsync());
        }
        
        await Task.WhenAll(tasks);
        stopwatch.Stop();

        // Assert
        var totalDuration = stopwatch.ElapsedMilliseconds;
        var averageDurationPerCheck = totalDuration / (double)concurrentChecks;

        Console.WriteLine($"Concurrent health checks performance:");
        Console.WriteLine($"  Total duration: {totalDuration}ms");
        Console.WriteLine($"  Average per check: {averageDurationPerCheck:F2}ms");
        Console.WriteLine($"  Concurrent checks: {concurrentChecks}");

        // Concurrent checks should not significantly degrade performance
        Assert.IsTrue(averageDurationPerCheck < 2000, $"Average concurrent health check duration ({averageDurationPerCheck:F2}ms) exceeds 2000ms");
    }

    [TestMethod]
    public async Task MemoryUsage_StaysWithinLimits()
    {
        // Arrange
        await persistenceManager.InitializePersistentStorageAsync(CancellationToken.None);
        
        var initialMemory = GC.GetTotalMemory(true);
        const int iterations = 100;

        // Act - Perform operations that might cause memory leaks
        for (int i = 0; i < iterations; i++)
        {
            await healthService.CheckHealthAsync();
            var config = configurationProvider.GetServerConfiguration();
            
            if (i % 10 == 0)
            {
                GC.Collect();
                GC.WaitForPendingFinalizers();
            }
        }

        var finalMemory = GC.GetTotalMemory(true);
        var memoryIncrease = finalMemory - initialMemory;

        // Assert
        Console.WriteLine($"Memory usage:");
        Console.WriteLine($"  Initial: {initialMemory / 1024 / 1024:F2} MB");
        Console.WriteLine($"  Final: {finalMemory / 1024 / 1024:F2} MB");
        Console.WriteLine($"  Increase: {memoryIncrease / 1024 / 1024:F2} MB");

        // Memory increase should be reasonable (less than 50MB for this test)
        Assert.IsTrue(memoryIncrease < 50 * 1024 * 1024, $"Memory increase ({memoryIncrease / 1024 / 1024:F2} MB) exceeds 50MB limit");
    }

    [TestMethod]
    public async Task StartupTime_MeetsRequirements()
    {
        // This test measures the time it takes to initialize all Docker services

        // Act
        var stopwatch = Stopwatch.StartNew();

        // Simulate container startup sequence
        await persistenceManager.InitializePersistentStorageAsync(CancellationToken.None);
        var config = configurationProvider.GetServerConfiguration();
        configurationProvider.ValidateConfiguration(out _);
        await healthService.CheckHealthAsync();

        stopwatch.Stop();

        // Assert
        var startupTime = stopwatch.ElapsedMilliseconds;
        
        Console.WriteLine($"Startup performance:");
        Console.WriteLine($"  Total startup time: {startupTime}ms");

        // Startup should complete within reasonable time (excluding game file download)
        Assert.IsTrue(startupTime < 10000, $"Startup time ({startupTime}ms) exceeds 10 seconds");
    }

    [TestMethod]
    public async Task ResourceCleanup_Performance()
    {
        // Arrange
        await persistenceManager.InitializePersistentStorageAsync(CancellationToken.None);
        
        // Create multiple backups to test cleanup performance
        for (int i = 0; i < 20; i++)
        {
            await persistenceManager.CreateBackupAsync($"cleanup_test_{i}", CancellationToken.None);
        }

        // Act
        var stopwatch = Stopwatch.StartNew();
        int cleanedUp = await persistenceManager.CleanupOldBackupsAsync(5, CancellationToken.None);
        stopwatch.Stop();

        // Assert
        var cleanupDuration = stopwatch.ElapsedMilliseconds;
        
        Console.WriteLine($"Cleanup performance:");
        Console.WriteLine($"  Duration: {cleanupDuration}ms");
        Console.WriteLine($"  Files cleaned: {cleanedUp}");

        Assert.AreEqual(15, cleanedUp); // Should clean up 15 old backups (20 - 5)
        Assert.IsTrue(cleanupDuration < 5000, $"Cleanup duration ({cleanupDuration}ms) exceeds 5 seconds");
    }

    [TestMethod]
    public void ConfigurationValidation_Performance_MeetsRequirements()
    {
        // Arrange
        const int iterations = 1000;
        var durations = new List<long>();

        // Act
        for (int i = 0; i < iterations; i++)
        {
            var stopwatch = Stopwatch.StartNew();
            configurationProvider.ValidateConfiguration(out _);
            stopwatch.Stop();
            durations.Add(stopwatch.ElapsedMilliseconds);
        }

        // Assert
        var averageDuration = durations.Sum() / (double)durations.Count;
        var maxDuration = durations.Max();

        Console.WriteLine($"Configuration validation performance:");
        Console.WriteLine($"  Average: {averageDuration:F2}ms");
        Console.WriteLine($"  Maximum: {maxDuration}ms");
        Console.WriteLine($"  Iterations: {iterations}");

        // Validation should be very fast
        Assert.IsTrue(averageDuration < 1, $"Average validation duration ({averageDuration:F2}ms) exceeds 1ms");
        Assert.IsTrue(maxDuration < 10, $"Maximum validation duration ({maxDuration}ms) exceeds 10ms");
    }
}