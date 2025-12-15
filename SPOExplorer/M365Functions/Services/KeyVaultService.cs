using Azure.Identity;
using Azure.Security.KeyVault.Certificates;

using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Threading.Tasks;


namespace M365Functions.Services
{
    internal class KeyVaultService
    {
        public static async Task<string> GetCertificateThumbprint()
        {
            var appSettings = AppSettings.Instance;

            //https://learn.microsoft.com/en-us/azure/key-vault/secrets/quick-create-net?tabs=azure-cli

            var keyVaultCertificateClient = new Azure.Security.KeyVault.Certificates.CertificateClient(new Uri(appSettings.KeyVaultUrl), new DefaultAzureCredential());

            KeyVaultCertificate certificate = await keyVaultCertificateClient.GetCertificateAsync(appSettings.CertificateSecretName);
            string thumbprint = certificate.Properties.X509ThumbprintString;

            return thumbprint;

            //Other ways to retrieve certificate.
            //X509Certificate2 x509Certificate = await keyVaultCertificateClient.DownloadCertificateAsync(certificateSecretName);

            //get public key as byte array
            //var cerFormattedCert = certificate.Cer;
            //var b64Cert = Convert.ToBase64String(cerFormattedCert);
        }

        public static async Task<X509Certificate2> GetCertificate()
        {
            var appSettings = AppSettings.Instance;

            //https://learn.microsoft.com/en-us/azure/key-vault/secrets/quick-create-net?tabs=azure-cli

            var keyVaultCertificateClient = new Azure.Security.KeyVault.Certificates.CertificateClient(new Uri(appSettings.KeyVaultUrl), new DefaultAzureCredential());

            //Other ways to retrieve certificate.
            X509Certificate2 x509Certificate = await keyVaultCertificateClient.DownloadCertificateAsync(appSettings.CertificateSecretName);
            return x509Certificate;
            //get public key as byte array
            //var cerFormattedCert = certificate.Cer;
            //var b64Cert = Convert.ToBase64String(cerFormattedCert);
        }
    }
}
