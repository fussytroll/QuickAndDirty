using PnP.Core.Auth;

using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Threading.Tasks;

namespace M365Functions.Services
{
    internal class PnPX509CertAuthServiceProvider : IServiceProvider
    {
        public object? GetService(Type serviceType)
        {
            //string? keyVaultUrl = Environment.GetEnvironmentVariable("KeyVaultUrl");
            //string? certificateSecretName = Environment.GetEnvironmentVariable("CertificateSecretName");
           

            return PnPX509CertAuthServiceProvider.GetX509AuthProviderWithAzureCertificate();
        }

        public static X509CertificateAuthenticationProvider GetX509AuthProviderWithLocalCertificate()
        {
            string? certificateThumbprint = KeyVaultService.GetCertificateThumbprint().Result;
       
            var certAuthProvider = new X509CertificateAuthenticationProvider(
                EnvironmentVariables.GetByName("ClientId"),
                EnvironmentVariables.GetByName("TenantId"),
                StoreName.My, StoreLocation.CurrentUser,
                certificateThumbprint
                );
            return certAuthProvider;
        }

        public static X509CertificateAuthenticationProvider GetX509AuthProviderWithAzureCertificate()
        {
            var certificate = KeyVaultService.GetCertificate().Result;

            var certAuthProvider = new X509CertificateAuthenticationProvider(
                EnvironmentVariables.GetByName("ClientId"),
                EnvironmentVariables.GetByName("TenantId"),
                certificate
                );
            return certAuthProvider;
        }
    }
}
