using System;
using System.Collections.Generic;

namespace NitroxServer.Docker.Logging;

/// <summary>
/// Enhanced logging interface for Docker deployment with structured logging support
/// </summary>
public interface IDockerLogger
{
    /// <summary>
    /// Log an informational message
    /// </summary>
    /// <param name="message">Log message</param>
    /// <param name="properties">Additional structured properties</param>
    void LogInfo(string message, Dictionary<string, object> properties = null);

    /// <summary>
    /// Log a warning message
    /// </summary>
    /// <param name="message">Log message</param>
    /// <param name="properties">Additional structured properties</param>
    void LogWarning(string message, Dictionary<string, object> properties = null);

    /// <summary>
    /// Log an error message
    /// </summary>
    /// <param name="message">Log message</param>
    /// <param name="exception">Exception details</param>
    /// <param name="properties">Additional structured properties</param>
    void LogError(string message, Exception exception = null, Dictionary<string, object> properties = null);

    /// <summary>
    /// Log a debug message
    /// </summary>
    /// <param name="message">Log message</param>
    /// <param name="properties">Additional structured properties</param>
    void LogDebug(string message, Dictionary<string, object> properties = null);

    /// <summary>
    /// Log a security event
    /// </summary>
    /// <param name="eventType">Type of security event</param>
    /// <param name="message">Event message</param>
    /// <param name="properties">Additional event properties</param>
    void LogSecurityEvent(SecurityEventType eventType, string message, Dictionary<string, object> properties = null);

    /// <summary>
    /// Log a performance metric
    /// </summary>
    /// <param name="metricName">Name of the metric</param>
    /// <param name="value">Metric value</param>
    /// <param name="unit">Unit of measurement</param>
    /// <param name="properties">Additional metric properties</param>
    void LogMetric(string metricName, double value, string unit = null, Dictionary<string, object> properties = null);

    /// <summary>
    /// Log an audit event
    /// </summary>
    /// <param name="action">Action performed</param>
    /// <param name="resource">Resource affected</param>
    /// <param name="outcome">Outcome of the action</param>
    /// <param name="properties">Additional audit properties</param>
    void LogAudit(string action, string resource, AuditOutcome outcome, Dictionary<string, object> properties = null);

    /// <summary>
    /// Create a scoped logger with additional context
    /// </summary>
    /// <param name="scope">Scope name</param>
    /// <param name="properties">Scope properties</param>
    /// <returns>Scoped logger instance</returns>
    IDockerLogger CreateScope(string scope, Dictionary<string, object> properties = null);
}

/// <summary>
/// Types of security events
/// </summary>
public enum SecurityEventType
{
    Authentication,
    Authorization,
    AccessDenied,
    ConfigurationChange,
    SecurityViolation,
    AnomalousActivity
}

/// <summary>
/// Audit outcomes
/// </summary>
public enum AuditOutcome
{
    Success,
    Failure,
    Partial,
    Unknown
}