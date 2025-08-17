using System;
using System.Collections.Generic;

namespace NitroxServer.Docker.Security;

/// <summary>
/// Result of security validation
/// </summary>
public class SecurityValidationResult
{
    /// <summary>
    /// Whether the security validation passed
    /// </summary>
    public bool IsSecure { get; set; } = true;

    /// <summary>
    /// Security issues found during validation
    /// </summary>
    public List<SecurityIssue> Issues { get; set; } = new();

    /// <summary>
    /// Security warnings (non-critical issues)
    /// </summary>
    public List<SecurityWarning> Warnings { get; set; } = new();

    /// <summary>
    /// When the validation was performed
    /// </summary>
    public DateTime ValidatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// Overall security score (0-100)
    /// </summary>
    public int SecurityScore { get; set; } = 100;

    /// <summary>
    /// Get a summary of the security validation
    /// </summary>
    /// <returns>Security validation summary</returns>
    public string GetSummary()
    {
        if (IsSecure && Issues.Count == 0)
        {
            return $"Security validation passed (Score: {SecurityScore}/100)";
        }

        return $"Security issues found: {Issues.Count} critical, {Warnings.Count} warnings (Score: {SecurityScore}/100)";
    }
}

/// <summary>
/// Represents a security issue
/// </summary>
public class SecurityIssue
{
    /// <summary>
    /// Severity level of the issue
    /// </summary>
    public SecuritySeverity Severity { get; set; }

    /// <summary>
    /// Category of the security issue
    /// </summary>
    public SecurityCategory Category { get; set; }

    /// <summary>
    /// Description of the issue
    /// </summary>
    public string Description { get; set; } = "";

    /// <summary>
    /// Recommended remediation steps
    /// </summary>
    public string Remediation { get; set; } = "";

    /// <summary>
    /// Affected component or file
    /// </summary>
    public string AffectedComponent { get; set; } = "";

    /// <summary>
    /// Risk level associated with this issue
    /// </summary>
    public RiskLevel Risk { get; set; }
}

/// <summary>
/// Represents a security warning
/// </summary>
public class SecurityWarning
{
    /// <summary>
    /// Description of the warning
    /// </summary>
    public string Description { get; set; } = "";

    /// <summary>
    /// Recommendation to address the warning
    /// </summary>
    public string Recommendation { get; set; } = "";

    /// <summary>
    /// Category of the warning
    /// </summary>
    public SecurityCategory Category { get; set; }
}

/// <summary>
/// Security recommendation for improving deployment security
/// </summary>
public class SecurityRecommendation
{
    /// <summary>
    /// Title of the recommendation
    /// </summary>
    public string Title { get; set; } = "";

    /// <summary>
    /// Detailed description
    /// </summary>
    public string Description { get; set; } = "";

    /// <summary>
    /// Priority level
    /// </summary>
    public RecommendationPriority Priority { get; set; }

    /// <summary>
    /// Category of the recommendation
    /// </summary>
    public SecurityCategory Category { get; set; }

    /// <summary>
    /// Implementation steps
    /// </summary>
    public string[] ImplementationSteps { get; set; } = Array.Empty<string>();

    /// <summary>
    /// Whether this recommendation is already implemented
    /// </summary>
    public bool IsImplemented { get; set; } = false;
}

/// <summary>
/// Result of security audit
/// </summary>
public class SecurityAuditResult
{
    /// <summary>
    /// When the audit was performed
    /// </summary>
    public DateTime AuditedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// Overall security posture
    /// </summary>
    public SecurityPosture Posture { get; set; }

    /// <summary>
    /// Audit findings
    /// </summary>
    public List<AuditFinding> Findings { get; set; } = new();

    /// <summary>
    /// Compliance status with security standards
    /// </summary>
    public Dictionary<string, bool> ComplianceStatus { get; set; } = new();

    /// <summary>
    /// Security metrics collected during audit
    /// </summary>
    public Dictionary<string, object> SecurityMetrics { get; set; } = new();
}

/// <summary>
/// Individual audit finding
/// </summary>
public class AuditFinding
{
    /// <summary>
    /// Type of finding
    /// </summary>
    public AuditFindingType Type { get; set; }

    /// <summary>
    /// Severity of the finding
    /// </summary>
    public SecuritySeverity Severity { get; set; }

    /// <summary>
    /// Description of the finding
    /// </summary>
    public string Description { get; set; } = "";

    /// <summary>
    /// Evidence supporting the finding
    /// </summary>
    public string Evidence { get; set; } = "";

    /// <summary>
    /// Recommended actions
    /// </summary>
    public string[] RecommendedActions { get; set; } = Array.Empty<string>();
}

/// <summary>
/// Security severity levels
/// </summary>
public enum SecuritySeverity
{
    Low,
    Medium,
    High,
    Critical
}

/// <summary>
/// Security categories
/// </summary>
public enum SecurityCategory
{
    Authentication,
    Authorization,
    DataProtection,
    NetworkSecurity,
    FilePermissions,
    ContainerSecurity,
    ConfigurationSecurity,
    Logging,
    Monitoring
}

/// <summary>
/// Risk levels
/// </summary>
public enum RiskLevel
{
    Low,
    Medium,
    High,
    Critical
}

/// <summary>
/// Recommendation priorities
/// </summary>
public enum RecommendationPriority
{
    Low,
    Medium,
    High,
    Critical
}

/// <summary>
/// Overall security posture
/// </summary>
public enum SecurityPosture
{
    Poor,
    Fair,
    Good,
    Excellent
}

/// <summary>
/// Types of audit findings
/// </summary>
public enum AuditFindingType
{
    Vulnerability,
    Misconfiguration,
    PolicyViolation,
    BestPracticeDeviation,
    ComplianceIssue
}