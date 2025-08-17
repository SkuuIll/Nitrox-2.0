using System;
using System.Collections.Generic;

namespace NitroxServer.Docker.Health;

/// <summary>
/// Represents the health status of the Docker container and Nitrox server
/// </summary>
public class HealthStatus
{
    /// <summary>
    /// Overall health status
    /// </summary>
    public HealthState Status { get; set; } = HealthState.Unknown;

    /// <summary>
    /// Timestamp when the health check was performed
    /// </summary>
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// List of health check results for individual components
    /// </summary>
    public List<ComponentHealth> ComponentHealths { get; set; } = new();

    /// <summary>
    /// Overall health message
    /// </summary>
    public string Message { get; set; } = "";

    /// <summary>
    /// Time taken to perform the health check in milliseconds
    /// </summary>
    public long CheckDurationMs { get; set; }

    /// <summary>
    /// Additional metadata about the health check
    /// </summary>
    public Dictionary<string, object> Metadata { get; set; } = new();

    /// <summary>
    /// Get a summary of the health status
    /// </summary>
    /// <returns>Human-readable health summary</returns>
    public string GetSummary()
    {
        var healthyComponents = 0;
        var totalComponents = ComponentHealths.Count;

        foreach (var component in ComponentHealths)
        {
            if (component.IsHealthy)
                healthyComponents++;
        }

        return $"{Status}: {healthyComponents}/{totalComponents} components healthy - {Message}";
    }

    /// <summary>
    /// Add a component health result
    /// </summary>
    /// <param name="componentName">Name of the component</param>
    /// <param name="isHealthy">Whether the component is healthy</param>
    /// <param name="message">Health message</param>
    /// <param name="metadata">Additional metadata</param>
    public void AddComponentHealth(string componentName, bool isHealthy, string message = "", Dictionary<string, object> metadata = null)
    {
        ComponentHealths.Add(new ComponentHealth
        {
            ComponentName = componentName,
            IsHealthy = isHealthy,
            Message = message,
            Metadata = metadata ?? new Dictionary<string, object>()
        });
    }
}

/// <summary>
/// Health status enumeration
/// </summary>
public enum HealthState
{
    Unknown,
    Healthy,
    Degraded,
    Unhealthy,
    Critical
}

/// <summary>
/// Health status of an individual component
/// </summary>
public class ComponentHealth
{
    /// <summary>
    /// Name of the component being checked
    /// </summary>
    public string ComponentName { get; set; } = "";

    /// <summary>
    /// Whether the component is healthy
    /// </summary>
    public bool IsHealthy { get; set; }

    /// <summary>
    /// Health message for this component
    /// </summary>
    public string Message { get; set; } = "";

    /// <summary>
    /// Additional metadata for this component
    /// </summary>
    public Dictionary<string, object> Metadata { get; set; } = new();

    /// <summary>
    /// Timestamp when this component was checked
    /// </summary>
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
}