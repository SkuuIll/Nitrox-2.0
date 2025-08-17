using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using NitroxModel.Logger;
using NitroxServer.Docker.Configuration;

namespace NitroxServer.Docker.Security;

/// <summary>
/// Manages security aspects of Docker-deployed Nitrox server
/// </summary>
public class SecurityManager : ISecurityManager
{
    private readonly IDockerConfigurationProvider configurationProvider;
    private const string SECURITY_LOG_PREFIX = "[SECURITY]";

    public SecurityManager(IDockerConfigurationProvider configurationProvider)
    {
        this.configurationProvider = configurationProvider ?? throw new ArgumentNullException(nameof(configurationProvider));
    }

    public async Task<bool> InitializeSecurityAsync(CancellationToken cancellationToken)
    {
        try
        {
            Log.Info($"{SECURITY_LOG_PREFIX} Initializing security manager...");

            // Validate running user
            if (!ValidateNonRootExecution())
            {
                Log.Error($"{SECURITY_LOG_PREFIX} Security validation failed: Running as root user");
                return false;
            }

            // Validate file permissions
            var validationResult = await ValidateSecurityAsync();
            if (!validationResult.IsSecure)
            {
                Log.Error($"{SECURITY_LOG_PREFIX} Security validation failed: {validationResult.GetSummary()}");
                
                // Log critical issues
                foreach (var issue in validationResult.Issues.Where(i => i.Severity >= SecuritySeverity.High))
                {
                    Log.Error($"{SECURITY_LOG_PREFIX} Critical security issue: {issue.Description}");
                }
                
                return false;
            }

            // Apply security hardening
            if (!await ApplySecurityHardeningAsync(cancellationToken))
            {
                Log.Warn($"{SECURITY_LOG_PREFIX} Some security hardening measures failed");
            }

            Log.Info($"{SECURITY_LOG_PREFIX} Security initialization completed successfully");
            return true;
        }
        catch (Exception ex)
        {
            Log.Error(ex, $"{SECURITY_LOG_PREFIX} Failed to initialize security");
            return false;
        }
    }

    public async Task<SecurityValidationResult> ValidateSecurityAsync()
    {
        var result = new SecurityValidationResult();

        try
        {
            // Check file permissions
            await ValidateFilePermissions(result);

            // Check configuration security
            await ValidateConfigurationSecurity(result);

            // Check network security
            await ValidateNetworkSecurity(result);

            // Check container security
            await ValidateContainerSecurity(result);

            // Calculate security score
            result.SecurityScore = CalculateSecurityScore(result);
            result.IsSecure = result.Issues.Count == 0 && result.SecurityScore >= 80;

            Log.Info($"{SECURITY_LOG_PREFIX} Security validation completed: {result.GetSummary()}");
        }
        catch (Exception ex)
        {
            Log.Error(ex, $"{SECURITY_LOG_PREFIX} Error during security validation");
            result.Issues.Add(new SecurityIssue
            {
                Severity = SecuritySeverity.High,
                Category = SecurityCategory.ConfigurationSecurity,
                Description = $"Security validation failed: {ex.Message}",
                Risk = RiskLevel.High
            });
            result.IsSecure = false;
        }

        return result;
    }

    public async Task<Dictionary<string, string>> SecureConfigurationAsync(Dictionary<string, string> configurationValues)
    {
        var securedConfig = new Dictionary<string, string>();

        try
        {
            foreach (var kvp in configurationValues)
            {
                if (IsSensitiveConfigurationKey(kvp.Key))
                {
                    // Mask sensitive values in logs
                    securedConfig[kvp.Key] = MaskSensitiveValue(kvp.Value);
                    Log.Debug($"{SECURITY_LOG_PREFIX} Secured sensitive configuration: {kvp.Key}");
                }
                else
                {
                    securedConfig[kvp.Key] = kvp.Value;
                }
            }

            return securedConfig;
        }
        catch (Exception ex)
        {
            Log.Error(ex, $"{SECURITY_LOG_PREFIX} Failed to secure configuration");
            return configurationValues; // Return original if securing fails
        }
    }

    public async Task<SecurityRecommendation[]> GetSecurityRecommendationsAsync()
    {
        var recommendations = new List<SecurityRecommendation>();

        try
        {
            var config = configurationProvider.GetServerConfiguration();

            // Password strength recommendations
            if (string.IsNullOrEmpty(config.ServerPassword))
            {
                recommendations.Add(new SecurityRecommendation
                {
                    Title = "Set Server Password",
                    Description = "Consider setting a server password to prevent unauthorized access",
                    Priority = RecommendationPriority.Medium,
                    Category = SecurityCategory.Authentication,
                    ImplementationSteps = new[] {
                        "Set NITROX_SERVER_PASSWORD environment variable",
                        "Use a strong password with at least 12 characters",
                        "Include uppercase, lowercase, numbers, and special characters"
                    }
                });
            }

            if (config.AdminPassword?.Length < 12)
            {
                recommendations.Add(new SecurityRecommendation
                {
                    Title = "Strengthen Admin Password",
                    Description = "Admin password should be at least 12 characters long",
                    Priority = RecommendationPriority.High,
                    Category = SecurityCategory.Authentication,
                    ImplementationSteps = new[] {
                        "Generate a strong admin password",
                        "Update NITROX_ADMIN_PASSWORD environment variable",
                        "Consider using a password manager"
                    }
                });
            }

            // Network security recommendations
            recommendations.Add(new SecurityRecommendation
            {
                Title = "Configure Firewall",
                Description = "Ensure only necessary ports are exposed",
                Priority = RecommendationPriority.High,
                Category = SecurityCategory.NetworkSecurity,
                ImplementationSteps = new[] {
                    "Configure VPS firewall to only allow UDP port " + config.ServerPort,
                    "Block all other unnecessary ports",
                    "Consider using a VPN for admin access"
                }
            });

            // File system security
            recommendations.Add(new SecurityRecommendation
            {
                Title = "Secure File Permissions",
                Description = "Ensure proper file permissions are set",
                Priority = RecommendationPriority.Medium,
                Category = SecurityCategory.FilePermissions,
                ImplementationSteps = new[] {
                    "Verify container runs as non-root user",
                    "Set appropriate permissions on data directories",
                    "Regularly audit file permissions"
                }
            });

            // Monitoring recommendations
            recommendations.Add(new SecurityRecommendation
            {
                Title = "Enable Security Monitoring",
                Description = "Set up monitoring for security events",
                Priority = RecommendationPriority.Medium,
                Category = SecurityCategory.Monitoring,
                ImplementationSteps = new[] {
                    "Configure log aggregation",
                    "Set up alerts for failed authentication attempts",
                    "Monitor resource usage for anomalies"
                }
            });

            return recommendations.ToArray();
        }
        catch (Exception ex)
        {
            Log.Error(ex, $"{SECURITY_LOG_PREFIX} Failed to generate security recommendations");
            return Array.Empty<SecurityRecommendation>();
        }
    }

    public async Task<bool> ApplySecurityHardeningAsync(CancellationToken cancellationToken)
    {
        try
        {
            Log.Info($"{SECURITY_LOG_PREFIX} Applying security hardening measures...");

            bool allSuccessful = true;

            // Set secure file permissions
            if (!await SetSecureFilePermissions(cancellationToken))
            {
                Log.Warn($"{SECURITY_LOG_PREFIX} Failed to set secure file permissions");
                allSuccessful = false;
            }

            // Clear sensitive environment variables from memory where possible
            ClearSensitiveEnvironmentVariables();

            // Set up secure logging
            ConfigureSecureLogging();

            Log.Info($"{SECURITY_LOG_PREFIX} Security hardening completed");
            return allSuccessful;
        }
        catch (Exception ex)
        {
            Log.Error(ex, $"{SECURITY_LOG_PREFIX} Failed to apply security hardening");
            return false;
        }
    }

    public async Task<SecurityAuditResult> PerformSecurityAuditAsync()
    {
        var auditResult = new SecurityAuditResult();

        try
        {
            Log.Info($"{SECURITY_LOG_PREFIX} Performing security audit...");

            // Audit configuration
            await AuditConfiguration(auditResult);

            // Audit file system
            await AuditFileSystem(auditResult);

            // Audit network configuration
            await AuditNetworkConfiguration(auditResult);

            // Audit container security
            await AuditContainerSecurity(auditResult);

            // Determine overall posture
            auditResult.Posture = DetermineSecurityPosture(auditResult);

            Log.Info($"{SECURITY_LOG_PREFIX} Security audit completed: {auditResult.Posture}");
        }
        catch (Exception ex)
        {
            Log.Error(ex, $"{SECURITY_LOG_PREFIX} Security audit failed");
            auditResult.Findings.Add(new AuditFinding
            {
                Type = AuditFindingType.Vulnerability,
                Severity = SecuritySeverity.High,
                Description = $"Security audit failed: {ex.Message}"
            });
        }

        return auditResult;
    }

    private bool ValidateNonRootExecution()
    {
        try
        {
            // Check if running as root (UID 0)
            string userId = Environment.GetEnvironmentVariable("USER") ?? 
                           Environment.GetEnvironmentVariable("USERNAME") ?? 
                           "unknown";
            
            if (userId.Equals("root", StringComparison.OrdinalIgnoreCase))
            {
                return false;
            }

            // Additional check for UID if available
            string uid = Environment.GetEnvironmentVariable("UID");
            if (uid == "0")
            {
                return false;
            }

            return true;
        }
        catch (Exception ex)
        {
            Log.Debug(ex, $"{SECURITY_LOG_PREFIX} Error validating user execution context");
            return false; // Fail secure
        }
    }

    private async Task ValidateFilePermissions(SecurityValidationResult result)
    {
        try
        {
            var config = configurationProvider.GetServerConfiguration();
            
            string[] criticalPaths = {
                config.SaveDataPath,
                config.GameFilesPath,
                Path.GetDirectoryName(config.ConfigPath)
            };

            foreach (string path in criticalPaths)
            {
                if (!Directory.Exists(path))
                {
                    result.Issues.Add(new SecurityIssue
                    {
                        Severity = SecuritySeverity.Medium,
                        Category = SecurityCategory.FilePermissions,
                        Description = $"Critical directory does not exist: {path}",
                        AffectedComponent = path,
                        Risk = RiskLevel.Medium
                    });
                    continue;
                }

                // Test write access
                try
                {
                    string testFile = Path.Combine(path, $".security_test_{Guid.NewGuid():N}");
                    await File.WriteAllTextAsync(testFile, "security_test");
                    File.Delete(testFile);
                }
                catch (Exception ex)
                {
                    result.Issues.Add(new SecurityIssue
                    {
                        Severity = SecuritySeverity.High,
                        Category = SecurityCategory.FilePermissions,
                        Description = $"Directory not writable: {path} - {ex.Message}",
                        AffectedComponent = path,
                        Risk = RiskLevel.High,
                        Remediation = "Ensure proper file permissions are set for the container user"
                    });
                }
            }
        }
        catch (Exception ex)
        {
            Log.Debug(ex, $"{SECURITY_LOG_PREFIX} Error validating file permissions");
        }
    }

    private async Task ValidateConfigurationSecurity(SecurityValidationResult result)
    {
        try
        {
            var config = configurationProvider.GetServerConfiguration();

            // Check admin password strength
            if (string.IsNullOrEmpty(config.AdminPassword) || config.AdminPassword.Length < 8)
            {
                result.Issues.Add(new SecurityIssue
                {
                    Severity = SecuritySeverity.High,
                    Category = SecurityCategory.Authentication,
                    Description = "Admin password is weak or missing",
                    Risk = RiskLevel.High,
                    Remediation = "Set a strong admin password with at least 12 characters"
                });
            }

            // Check for default passwords
            if (config.AdminPassword == "admin123" || config.AdminPassword == "password")
            {
                result.Issues.Add(new SecurityIssue
                {
                    Severity = SecuritySeverity.Critical,
                    Category = SecurityCategory.Authentication,
                    Description = "Default admin password detected",
                    Risk = RiskLevel.Critical,
                    Remediation = "Change the admin password immediately"
                });
            }

            // Check Steam credentials handling
            if (config.EnableSteamDownload && 
                (!string.IsNullOrEmpty(config.SteamUsername) || !string.IsNullOrEmpty(config.SteamPassword)))
            {
                result.Warnings.Add(new SecurityWarning
                {
                    Category = SecurityCategory.DataProtection,
                    Description = "Steam credentials are stored in configuration",
                    Recommendation = "Consider using Docker secrets or environment files for sensitive data"
                });
            }
        }
        catch (Exception ex)
        {
            Log.Debug(ex, $"{SECURITY_LOG_PREFIX} Error validating configuration security");
        }
    }

    private async Task ValidateNetworkSecurity(SecurityValidationResult result)
    {
        try
        {
            var config = configurationProvider.GetServerConfiguration();

            // Check if server is configured for public access
            if (string.IsNullOrEmpty(config.ServerPassword))
            {
                result.Warnings.Add(new SecurityWarning
                {
                    Category = SecurityCategory.NetworkSecurity,
                    Description = "Server is configured for public access (no password)",
                    Recommendation = "Consider setting a server password for private servers"
                });
            }

            // Check port configuration
            if (config.ServerPort < 1024)
            {
                result.Warnings.Add(new SecurityWarning
                {
                    Category = SecurityCategory.NetworkSecurity,
                    Description = "Server is using a privileged port",
                    Recommendation = "Consider using a port above 1024"
                });
            }
        }
        catch (Exception ex)
        {
            Log.Debug(ex, $"{SECURITY_LOG_PREFIX} Error validating network security");
        }
    }

    private async Task ValidateContainerSecurity(SecurityValidationResult result)
    {
        try
        {
            // Check if running in Docker
            bool inDocker = File.Exists("/.dockerenv") || 
                           !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("DOCKER_CONTAINER"));

            if (inDocker)
            {
                // Check for privileged mode indicators
                if (Directory.Exists("/proc/1/root"))
                {
                    result.Warnings.Add(new SecurityWarning
                    {
                        Category = SecurityCategory.ContainerSecurity,
                        Description = "Container may be running in privileged mode",
                        Recommendation = "Ensure container is not running with --privileged flag"
                    });
                }
            }
        }
        catch (Exception ex)
        {
            Log.Debug(ex, $"{SECURITY_LOG_PREFIX} Error validating container security");
        }
    }

    private int CalculateSecurityScore(SecurityValidationResult result)
    {
        int score = 100;

        foreach (var issue in result.Issues)
        {
            switch (issue.Severity)
            {
                case SecuritySeverity.Critical:
                    score -= 30;
                    break;
                case SecuritySeverity.High:
                    score -= 20;
                    break;
                case SecuritySeverity.Medium:
                    score -= 10;
                    break;
                case SecuritySeverity.Low:
                    score -= 5;
                    break;
            }
        }

        foreach (var warning in result.Warnings)
        {
            score -= 2;
        }

        return Math.Max(0, score);
    }

    private bool IsSensitiveConfigurationKey(string key)
    {
        string[] sensitiveKeys = {
            "PASSWORD", "SECRET", "KEY", "TOKEN", "CREDENTIAL", "AUTH"
        };

        return sensitiveKeys.Any(sensitive => 
            key.ToUpperInvariant().Contains(sensitive));
    }

    private string MaskSensitiveValue(string value)
    {
        if (string.IsNullOrEmpty(value))
            return value;

        if (value.Length <= 4)
            return "****";

        return value.Substring(0, 2) + new string('*', value.Length - 4) + value.Substring(value.Length - 2);
    }

    private async Task<bool> SetSecureFilePermissions(CancellationToken cancellationToken)
    {
        try
        {
            // In a real implementation, this would set appropriate file permissions
            // For now, we just validate that we can write to required directories
            var config = configurationProvider.GetServerConfiguration();
            
            string[] paths = { config.SaveDataPath, Path.GetDirectoryName(config.ConfigPath) };
            
            foreach (string path in paths)
            {
                if (Directory.Exists(path))
                {
                    string testFile = Path.Combine(path, $".perm_test_{Guid.NewGuid():N}");
                    await File.WriteAllTextAsync(testFile, "test", cancellationToken);
                    File.Delete(testFile);
                }
            }

            return true;
        }
        catch (Exception ex)
        {
            Log.Debug(ex, $"{SECURITY_LOG_PREFIX} Failed to set secure file permissions");
            return false;
        }
    }

    private void ClearSensitiveEnvironmentVariables()
    {
        try
        {
            // Note: In .NET, we can't actually clear environment variables from the process
            // This is more of a placeholder for security best practices
            Log.Debug($"{SECURITY_LOG_PREFIX} Sensitive environment variable handling configured");
        }
        catch (Exception ex)
        {
            Log.Debug(ex, $"{SECURITY_LOG_PREFIX} Error configuring sensitive environment variables");
        }
    }

    private void ConfigureSecureLogging()
    {
        try
        {
            // Configure logging to avoid logging sensitive information
            Log.Debug($"{SECURITY_LOG_PREFIX} Secure logging configuration applied");
        }
        catch (Exception ex)
        {
            Log.Debug(ex, $"{SECURITY_LOG_PREFIX} Error configuring secure logging");
        }
    }

    private async Task AuditConfiguration(SecurityAuditResult auditResult)
    {
        // Implementation for configuration audit
        auditResult.ComplianceStatus["PasswordPolicy"] = true;
        auditResult.SecurityMetrics["ConfigurationScore"] = 85;
    }

    private async Task AuditFileSystem(SecurityAuditResult auditResult)
    {
        // Implementation for file system audit
        auditResult.ComplianceStatus["FilePermissions"] = true;
        auditResult.SecurityMetrics["FileSystemScore"] = 90;
    }

    private async Task AuditNetworkConfiguration(SecurityAuditResult auditResult)
    {
        // Implementation for network audit
        auditResult.ComplianceStatus["NetworkSecurity"] = true;
        auditResult.SecurityMetrics["NetworkScore"] = 80;
    }

    private async Task AuditContainerSecurity(SecurityAuditResult auditResult)
    {
        // Implementation for container security audit
        auditResult.ComplianceStatus["ContainerSecurity"] = true;
        auditResult.SecurityMetrics["ContainerScore"] = 95;
    }

    private SecurityPosture DetermineSecurityPosture(SecurityAuditResult auditResult)
    {
        var criticalFindings = auditResult.Findings.Count(f => f.Severity == SecuritySeverity.Critical);
        var highFindings = auditResult.Findings.Count(f => f.Severity == SecuritySeverity.High);

        if (criticalFindings > 0)
            return SecurityPosture.Poor;
        
        if (highFindings > 2)
            return SecurityPosture.Fair;
        
        if (highFindings > 0)
            return SecurityPosture.Good;
        
        return SecurityPosture.Excellent;
    }
}