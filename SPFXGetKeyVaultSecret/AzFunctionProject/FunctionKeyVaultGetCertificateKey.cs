using Azure.Identity;
using Azure.Security.KeyVault.Certificates;
using Azure.Security.KeyVault.Secrets;

using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace CloudFunctions;

public class FunctionKeyVaultGetCertificateKey
{
    private readonly ILogger<FunctionKeyVaultGetCertificateKey> _logger;

    public FunctionKeyVaultGetCertificateKey(ILogger<FunctionKeyVaultGetCertificateKey> logger)
    {
        _logger = logger;
    }

    [Function("FunctionKeyVaultGetCertificateKey")]
    public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Function, "get", "post")] HttpRequest req)
    {
        //i am sure there is a better way to get the certificate key.
        //if you know it please share.
        string returnValue = "Nothing";
        try
        {
            string? keyVaultUrl = Environment.GetEnvironmentVariable("KeyVaultUrl");
            string? certificateSecretName = Environment.GetEnvironmentVariable("CertificateSecretName");
            if (String.IsNullOrEmpty(keyVaultUrl) || String.IsNullOrEmpty(certificateSecretName))
            {
                returnValue = "Error:Invalid Environment Variables";
                _logger.LogError("Invalid Environment Variables");
            }
            else
            {
                //https://learn.microsoft.com/en-us/azure/key-vault/secrets/quick-create-net?tabs=azure-cli

                var secretClient = new Azure.Security.KeyVault.Secrets.SecretClient(new Uri(keyVaultUrl), new DefaultAzureCredential());
                var response = await secretClient.GetSecretAsync(certificateSecretName);
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