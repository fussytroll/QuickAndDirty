using M365Functions.Services;

using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace M365Functions;

public class AzureTest
{
    private readonly ILogger<AzureTest> _logger;

    public AzureTest(ILogger<AzureTest> logger)
    {
        _logger = logger;
    }

    [Function("AzureTest")]
    public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Function, "get", "post")] HttpRequest req)
    {
        try
        {
            _logger.LogInformation("C# HTTP trigger function processed a request.");
            var thumbprint = await KeyVaultService.GetCertificateThumbprint();
            var AuthProvider = PnPX509CertAuthServiceProvider.GetX509AuthProviderWithAzureCertificate();
            var graphClient = GraphService.GetGraphClient();
            var sites = await SPSiteCollection.GetAllSiteCollections(graphClient);
            return new OkObjectResult($"Welcome to Azure Functions! {thumbprint};{sites}");
        }
        catch (Exception ex)
        {
            return new OkObjectResult(ex.ToString());
        }
    }
}