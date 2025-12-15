using Azure.Core;
using Azure.Identity;

using Microsoft.Graph;

using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Threading.Tasks;



namespace M365Functions.Services
{
    internal class GraphService
    {

        public static GraphServiceClient GetGraphClient()
        {
            var appSettings = AppSettings.Instance;

            var certificate = KeyVaultService.GetCertificate().Result;

            var options = new ClientCertificateCredentialOptions
            {
                AuthorityHost = AzureAuthorityHosts.AzurePublicCloud,
            };

            var clientCertCreds = new ClientCertificateCredential(appSettings.TenantId,
                appSettings.ClientId,
                certificate,
                options);

            var scopes = new[] { "https://graph.microsoft.com/.default" };

            var graphClient = new GraphServiceClient(clientCertCreds, scopes);

            return graphClient;
        }

        private static async Task<string> GetAccessTokenWithClientCertificateAsync(string resourceUrl,
            string tenantId,
            string clientId,
            X509Certificate2 certificate)
        {
            var clientCertCreds = new ClientCertificateCredential(tenantId,
                clientId,
                certificate);

            return await GetToken(clientCertCreds,
                resourceUrl);
        }

        private static async Task<string> GetToken(TokenCredential credential,
            string resourceUrl)
        {
            return (await credential.GetTokenAsync(new TokenRequestContext(scopes: [resourceUrl + "/.default"]) { }, new CancellationToken())).Token;
        }
    }
}
