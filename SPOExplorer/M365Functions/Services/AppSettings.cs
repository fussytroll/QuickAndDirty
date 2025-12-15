using Microsoft.Extensions.Configuration;

using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;

namespace M365Functions.Services
{
    internal class AppSettings
    {
        private static AppSettings _instance;
        public static AppSettings Instance
        {
            get
            {
                if (_instance == null)
                {
                    _instance = GetAppSettings();
                }
                return _instance;
            }
        }

        public string TenantId { get; set; }
        public string ClientId { get; set; }
        public string KeyVaultUrl { get; set; }
        public string CertificateSecretName { get; set; }

        public static AppSettings GetSettingsFromEnvVars()
        {
            return new AppSettings
            {
                TenantId = EnvironmentVariables.GetByName("TenantId"),
                KeyVaultUrl = EnvironmentVariables.GetByName("KeyVaultUrl"),
                CertificateSecretName = EnvironmentVariables.GetByName("CertificateSecretName"),
                ClientId = EnvironmentVariables.GetByName("ClientId")
            };
        }

        public static AppSettings GetAppSettings()
        {
            IConfigurationRoot localConfig = new ConfigurationBuilder()
            .AddEnvironmentVariables()
            .AddJsonFile("local.settings.json", optional:true, reloadOnChange:true)
            .AddUserSecrets(Assembly.GetExecutingAssembly(), optional:true)
            .Build();

            AppSettings appSettings = new AppSettings();
            localConfig.Bind(appSettings);
            return appSettings;
        }
    }
}
