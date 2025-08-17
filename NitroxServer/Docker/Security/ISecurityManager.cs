using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

namespace NitroxServer.Docker.Security;

/// <summary>
/// Manages security aspects of Docker-deployed Nitrox server
/// </summary>
public interface ISecurityManager
{
    /// <summary>
    /// Initialize security configurations and validate setup
    /// </summary>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>True if security initialization was successful</returns>
    Task<bool> InitializeSecurityAsync(CancellationToken cancellationToken);

    /// <summary>
    /// Validate file permissions and access controls
    /// </summary>
    /// <returns>Security validation result</returns>
    Task<SecurityValidationResult> ValidateSecurityAsync();

    /// <summary>
    /// Secure sensitive configuration values
    /// </summary>
    /// <param name="configurationValues">Configuration values to secure</param>
    /// <returns>Secured configuration values</returns>
    Task<Dictionary<string, string>> SecureConfigurationAsync(Dictionary<string, string> configurationValues);

    /// <summary>
    /// Get security recommendations for the current deployment
    /// </summary>
    /// <returns>List of security recommendations</returns>
    Task<SecurityRecommendation[]> GetSecurityRecommendationsAsync();

    /// <summary>
    /// Apply security hardening measures
    /// </summary>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>True if hardening was successful</returns>
    Task<bool> ApplySecurityHardeningAsync(CancellationToken cancellationToken);

    /// <summary>
    /// Audit security configuration and log findings
    /// </summary>
    /// <returns>Security audit result</returns>
    Task<SecurityAuditResult> PerformSecurityAuditAsync();
}