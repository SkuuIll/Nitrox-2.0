using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using NitroxModel.Logger;
using NitroxServer.Docker.Logging;

namespace NitroxServer.Docker.ErrorHandling;

/// <summary>
/// Centralized error handling for Docker deployment operations
/// </summary>
public class DockerErrorHandler
{
    private readonly IDockerLogger dockerLogger;
    private readonly Dictionary<Type, Func<Exception, Task<bool>>> errorHandlers;
    private readonly Dictionary<string, RetryPolicy> retryPolicies;

    public DockerErrorHandler(IDockerLogger dockerLogger = null)
    {
        this.dockerLogger = dockerLogger;
        this.errorHandlers = new Dictionary<Type, Func<Exception, Task<bool>>>();
        this.retryPolicies = new Dictionary<string, RetryPolicy>();
        
        InitializeDefaultHandlers();
        InitializeDefaultRetryPolicies();
    }

    /// <summary>
    /// Execute an operation with comprehensive error handling and retry logic
    /// </summary>
    /// <typeparam name="T">Return type</typeparam>
    /// <param name="operation">Operation to execute</param>
    /// <param name="operationName">Name of the operation for logging</param>
    /// <param name="retryPolicyName">Name of retry policy to use</param>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>Operation result</returns>
    public async Task<T> ExecuteWithHandlingAsync<T>(
        Func<Task<T>> operation,
        string operationName,
        string retryPolicyName = "default",
        CancellationToken cancellationToken = default)
    {
        var retryPolicy = retryPolicies.GetValueOrDefault(retryPolicyName, retryPolicies["default"]);
        var attempt = 0;
        Exception lastException = null;

        while (attempt <= retryPolicy.MaxRetries)
        {
            try
            {
                dockerLogger?.LogDebug($"Executing operation: {operationName} (attempt {attempt + 1})");
                
                var result = await operation();
                
                if (attempt > 0)
                {
                    dockerLogger?.LogInfo($"Operation succeeded after {attempt + 1} attempts: {operationName}");
                }
                
                return result;
            }
            catch (Exception ex) when (ShouldRetry(ex, attempt, retryPolicy))
            {
                lastException = ex;
                attempt++;
                
                dockerLogger?.LogWarning($"Operation failed (attempt {attempt}): {operationName} - {ex.Message}");
                
                if (attempt <= retryPolicy.MaxRetries)
                {
                    var delay = CalculateDelay(attempt, retryPolicy);
                    dockerLogger?.LogDebug($"Retrying in {delay.TotalSeconds} seconds...");
                    
                    try
                    {
                        await Task.Delay(delay, cancellationToken);
                    }
                    catch (OperationCanceledException)
                    {
                        dockerLogger?.LogInfo($"Operation cancelled during retry delay: {operationName}");
                        throw;
                    }
                }
            }
            catch (Exception ex)
            {
                // Handle non-retryable exceptions
                await HandleExceptionAsync(ex, operationName);
                throw;
            }
        }

        // All retries exhausted
        dockerLogger?.LogError($"Operation failed after {retryPolicy.MaxRetries + 1} attempts: {operationName}", lastException);
        await HandleExceptionAsync(lastException, operationName);
        throw lastException;
    }

    /// <summary>
    /// Execute an operation with error handling (no return value)
    /// </summary>
    /// <param name="operation">Operation to execute</param>
    /// <param name="operationName">Name of the operation for logging</param>
    /// <param name="retryPolicyName">Name of retry policy to use</param>
    /// <param name="cancellationToken">Cancellation token</param>
    public async Task ExecuteWithHandlingAsync(
        Func<Task> operation,
        string operationName,
        string retryPolicyName = "default",
        CancellationToken cancellationToken = default)
    {
        await ExecuteWithHandlingAsync(async () =>
        {
            await operation();
            return true;
        }, operationName, retryPolicyName, cancellationToken);
    }

    /// <summary>
    /// Register a custom error handler for a specific exception type
    /// </summary>
    /// <typeparam name="TException">Exception type</typeparam>
    /// <param name="handler">Error handler function</param>
    public void RegisterErrorHandler<TException>(Func<TException, Task<bool>> handler) where TException : Exception
    {
        errorHandlers[typeof(TException)] = ex => handler((TException)ex);
    }

    /// <summary>
    /// Register a custom retry policy
    /// </summary>
    /// <param name="name">Policy name</param>
    /// <param name="policy">Retry policy</param>
    public void RegisterRetryPolicy(string name, RetryPolicy policy)
    {
        retryPolicies[name] = policy;
    }

    private void InitializeDefaultHandlers()
    {
        // Network-related errors
        RegisterErrorHandler<System.Net.NetworkInformation.NetworkInformationException>(async ex =>
        {
            dockerLogger?.LogError("Network connectivity issue detected", ex, new Dictionary<string, object>
            {
                ["error_type"] = "network",
                ["error_code"] = ex.HResult
            });
            return true; // Retryable
        });

        // File system errors
        RegisterErrorHandler<System.IO.IOException>(async ex =>
        {
            dockerLogger?.LogError("File system operation failed", ex, new Dictionary<string, object>
            {
                ["error_type"] = "filesystem",
                ["error_code"] = ex.HResult
            });
            return true; // Retryable
        });

        // Unauthorized access
        RegisterErrorHandler<UnauthorizedAccessException>(async ex =>
        {
            dockerLogger?.LogSecurityEvent(SecurityEventType.AccessDenied, "Unauthorized access attempt", new Dictionary<string, object>
            {
                ["error_type"] = "security",
                ["message"] = ex.Message
            });
            return false; // Not retryable
        });

        // Timeout errors
        RegisterErrorHandler<TimeoutException>(async ex =>
        {
            dockerLogger?.LogWarning("Operation timed out", new Dictionary<string, object>
            {
                ["error_type"] = "timeout",
                ["message"] = ex.Message
            });
            return true; // Retryable
        });

        // Task cancellation
        RegisterErrorHandler<OperationCanceledException>(async ex =>
        {
            dockerLogger?.LogInfo("Operation was cancelled", new Dictionary<string, object>
            {
                ["error_type"] = "cancellation",
                ["message"] = ex.Message
            });
            return false; // Not retryable
        });
    }

    private void InitializeDefaultRetryPolicies()
    {
        // Default retry policy
        retryPolicies["default"] = new RetryPolicy
        {
            MaxRetries = 3,
            BaseDelay = TimeSpan.FromSeconds(1),
            MaxDelay = TimeSpan.FromSeconds(30),
            BackoffMultiplier = 2.0,
            UseJitter = true
        };

        // Network operations
        retryPolicies["network"] = new RetryPolicy
        {
            MaxRetries = 5,
            BaseDelay = TimeSpan.FromSeconds(2),
            MaxDelay = TimeSpan.FromMinutes(2),
            BackoffMultiplier = 1.5,
            UseJitter = true
        };

        // File operations
        retryPolicies["file"] = new RetryPolicy
        {
            MaxRetries = 3,
            BaseDelay = TimeSpan.FromMilliseconds(500),
            MaxDelay = TimeSpan.FromSeconds(10),
            BackoffMultiplier = 2.0,
            UseJitter = false
        };

        // Critical operations (fewer retries, faster failure)
        retryPolicies["critical"] = new RetryPolicy
        {
            MaxRetries = 1,
            BaseDelay = TimeSpan.FromSeconds(1),
            MaxDelay = TimeSpan.FromSeconds(5),
            BackoffMultiplier = 1.0,
            UseJitter = false
        };

        // Long-running operations
        retryPolicies["long-running"] = new RetryPolicy
        {
            MaxRetries = 10,
            BaseDelay = TimeSpan.FromSeconds(5),
            MaxDelay = TimeSpan.FromMinutes(5),
            BackoffMultiplier = 1.2,
            UseJitter = true
        };
    }

    private bool ShouldRetry(Exception exception, int attempt, RetryPolicy policy)
    {
        if (attempt >= policy.MaxRetries)
            return false;

        // Check if we have a specific handler for this exception type
        var exceptionType = exception.GetType();
        if (errorHandlers.TryGetValue(exceptionType, out var handler))
        {
            try
            {
                return handler(exception).Result;
            }
            catch (Exception handlerEx)
            {
                dockerLogger?.LogError("Error handler failed", handlerEx);
                return false;
            }
        }

        // Check base exception types
        foreach (var kvp in errorHandlers)
        {
            if (kvp.Key.IsAssignableFrom(exceptionType))
            {
                try
                {
                    return kvp.Value(exception).Result;
                }
                catch (Exception handlerEx)
                {
                    dockerLogger?.LogError("Error handler failed", handlerEx);
                    return false;
                }
            }
        }

        // Default: retry for most exceptions except critical ones
        return !(exception is ArgumentException ||
                exception is ArgumentNullException ||
                exception is InvalidOperationException ||
                exception is NotSupportedException ||
                exception is OperationCanceledException);
    }

    private TimeSpan CalculateDelay(int attempt, RetryPolicy policy)
    {
        var delay = TimeSpan.FromTicks((long)(policy.BaseDelay.Ticks * Math.Pow(policy.BackoffMultiplier, attempt - 1)));
        
        if (delay > policy.MaxDelay)
            delay = policy.MaxDelay;

        if (policy.UseJitter)
        {
            var jitter = Random.Shared.NextDouble() * 0.1; // ±10% jitter
            delay = TimeSpan.FromTicks((long)(delay.Ticks * (1 + jitter - 0.05)));
        }

        return delay;
    }

    private async Task HandleExceptionAsync(Exception exception, string operationName)
    {
        try
        {
            // Log the exception with context
            dockerLogger?.LogError($"Unhandled exception in operation: {operationName}", exception, new Dictionary<string, object>
            {
                ["operation"] = operationName,
                ["exception_type"] = exception.GetType().Name,
                ["stack_trace"] = exception.StackTrace
            });

            // Try to find and execute a specific handler
            var exceptionType = exception.GetType();
            if (errorHandlers.TryGetValue(exceptionType, out var handler))
            {
                await handler(exception);
            }
            else
            {
                // Check base types
                foreach (var kvp in errorHandlers)
                {
                    if (kvp.Key.IsAssignableFrom(exceptionType))
                    {
                        await kvp.Value(exception);
                        break;
                    }
                }
            }
        }
        catch (Exception handlerException)
        {
            // Prevent exception handling from causing more exceptions
            dockerLogger?.LogError("Exception occurred while handling another exception", handlerException);
            Log.Error(handlerException, "Critical error in exception handler");
        }
    }
}

/// <summary>
/// Retry policy configuration
/// </summary>
public class RetryPolicy
{
    /// <summary>
    /// Maximum number of retry attempts
    /// </summary>
    public int MaxRetries { get; set; } = 3;

    /// <summary>
    /// Base delay between retries
    /// </summary>
    public TimeSpan BaseDelay { get; set; } = TimeSpan.FromSeconds(1);

    /// <summary>
    /// Maximum delay between retries
    /// </summary>
    public TimeSpan MaxDelay { get; set; } = TimeSpan.FromSeconds(30);

    /// <summary>
    /// Backoff multiplier for exponential backoff
    /// </summary>
    public double BackoffMultiplier { get; set; } = 2.0;

    /// <summary>
    /// Whether to add random jitter to delays
    /// </summary>
    public bool UseJitter { get; set; } = true;
}