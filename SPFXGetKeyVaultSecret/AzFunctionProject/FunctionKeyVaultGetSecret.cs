using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace CloudFunctions;

public class FunctionKeyVaultGetSecret
{
    private readonly ILogger<FunctionKeyVaultGetSecret> _logger;

    public FunctionKeyVaultGetSecret(ILogger<FunctionKeyVaultGetSecret> logger)
    {
        _logger = logger;
    }

    [Function("FunctionKeyVaultGetSecret")]
    public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Function, "get", "post")] HttpRequest req)
    {
        string returnValue = "Nothing";
        try
        {
            string? keyVaultUrl = Environment.GetEnvironmentVariable("KeyVaultUrl");
            string? thumbprintSecretName = Environment.GetEnvironmentVariable("ThumbprintSecretName");
            if (String.IsNullOrEmpty(keyVaultUrl) || String.IsNullOrEmpty(thumbprintSecretName))
            {
                returnValue = "Error:Invalid Environment Variables";
                _logger.LogError("Invalid Environment Variables");
            }
            else
            {
                //https://learn.microsoft.com/en-us/azure/key-vault/secrets/quick-create-net?tabs=azure-cli

                var secretClient = new Azure.Security.KeyVault.Secrets.SecretClient(new Uri(keyVaultUrl), new DefaultAzureCredential());
                var response = await secretClient.GetSecretAsync(thumbprintSecretName);
                KeyVaultSecret secret = response.Value;
                returnValue = secret.Value.ToString();
            }
        }
        catch (Exception ex)
        {
            returnValue = $"Error:{ex.Message}";
            _logger.LogError(ex.ToString());
        }
        return new OkObjectResult(returnValue);
    }
}