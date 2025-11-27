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
    public IActionResult Run([HttpTrigger(AuthorizationLevel.Function, "get", "post")] HttpRequest req)
    {
        _logger.LogInformation("C# HTTP trigger function processed a request.");
        return new OkObjectResult("Welcome to Azure Functions!");
    }
}