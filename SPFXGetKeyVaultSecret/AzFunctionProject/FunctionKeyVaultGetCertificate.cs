using Azure.Identity;
using Azure.Security.KeyVault.Certificates;

using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Microsoft.Identity.Client;

using System.Security.Cryptography.X509Certificates;

namespace CloudFunctions;

public class FunctionKeyVaultGetCertificate
{
    private readonly ILogger<FunctionKeyVaultGetCertificate> _logger;

    public FunctionKeyVaultGetCertificate(ILogger<FunctionKeyVaultGetCertificate> logger)
    {
        _logger = logger;
    }

    [Function("FunctionKeyVaultGetCertificate")]
    public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Function, "get", "post")] HttpRequest req)
    {
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

                var certClient = new Azure.Security.KeyVault.Certificates.CertificateClient(new Uri(keyVaultUrl), new DefaultAzureCredential());
               
                KeyVaultCertificate certificate = await certClient.GetCertificateAsync(certificateSecretName);
                string thumbprint = certificate.Properties.X509ThumbprintString;

                returnValue = thumbprint;

                //Other ways to retrieve certificate.
                //X509Certificate2 x509Certificate = await certClient.DownloadCertificateAsync(certificateSecretName);

                //get public key as byte array
                var cerFormattedCert = certificate.Cer;
                var b64Cert = Convert.ToBase64String(cerFormattedCert);
                returnValue = $"{thumbprint}={b64Cert}";
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