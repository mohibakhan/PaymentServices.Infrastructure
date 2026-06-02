using Evolve.Digital.LimitsService.Shared.Internal;
using Evolve.Digital.LimitsService.Shared.Internal.Models;
using Microsoft.Extensions.Logging;
using PaymentServices.Shared.Messages;

namespace PaymentServices.Transfer.Services;

/// <summary>
/// Limit check backed by the Evolve.Digital.LimitsService NuGet. Evaluates all
/// limits in the "Send" category for the FBO account against the payment amount.
/// Read-only: UpdateUsage is false (we don't increment usage from the check).
/// </summary>
public sealed class EvolveLimitService : ILimitService
{
    private const string SendCategory = "Send";

    private readonly ILimitsInternalClient _limitsClient;
    private readonly ILogger<EvolveLimitService> _logger;

    public EvolveLimitService(
        ILimitsInternalClient limitsClient,
        ILogger<EvolveLimitService> logger)
    {
        _limitsClient = limitsClient;
        _logger = logger;
    }

    public async Task<CheckResult> CheckAsync(PaymentMessage message, CancellationToken cancellationToken = default)
    {
        if (!decimal.TryParse(message.Amount, out var amount))
        {
            _logger.LogError("Invalid amount '{Amount}' for limit check. EvolveId={EvolveId}",
                message.Amount, message.EvolveId);
            return CheckResult.Deny($"Amount '{message.Amount}' is not a valid decimal");
        }

        var partitionKey = message.FboAccount ?? string.Empty;
        if (string.IsNullOrWhiteSpace(partitionKey))
        {
            _logger.LogError("No FBO account for limit check. EvolveId={EvolveId}", message.EvolveId);
            return CheckResult.Deny("No FBO account available for limit evaluation");
        }

        var request = new EvaluateCategoryRequest(
            PartitionKey: partitionKey,
            Category: SendCategory,
            Amount: amount,
            UpdateUsage: false);

        var response = await _limitsClient.EvaluateCategoryLimitsAsync(request);

        if (response.Approved)
        {
            _logger.LogInformation(
                "Limit check approved. EvolveId={EvolveId} Pk={Pk} Amount={Amount}",
                message.EvolveId, partitionKey, amount);
            return CheckResult.Pass();
        }

        var reason = $"Limit denied ({response.FailedLimit?.LimitType}): {response.Message}";
        _logger.LogWarning(
            "Limit check DENIED. EvolveId={EvolveId} FailedLimit={LimitType} Message={Message}",
            message.EvolveId, response.FailedLimit?.LimitType, response.Message);
        return CheckResult.Deny(reason);
    }
}
