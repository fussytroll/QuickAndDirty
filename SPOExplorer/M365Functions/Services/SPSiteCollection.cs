using Microsoft.Graph;
using Microsoft.Graph.Models;
using Microsoft.IdentityModel.Tokens;

using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading.Tasks;

namespace M365Functions.Services
{
    internal class SPSiteCollection
    {
        public static async Task<string> GetAllSiteCollections(GraphServiceClient graphClient)
        {
            var siteCollections = await graphClient.Sites.GetAsync();
            StringBuilder siteTitles = new StringBuilder();
            foreach(var site in siteCollections?.Value)
            {
                siteTitles.Append(site.Id);

            }
            return siteTitles.ToString();
            /*
            var requestInformation = graphClient.Sites.ToGetRequestInformation(requestConfiguration =>
            {
                requestConfiguration.QueryParameters.Select = new[] { "Id", "WebUrl", "Name", "DisplayName" };
                requestConfiguration.QueryParameters.Top = 200;
            });
            requestInformation.UrlTemplate = requestInformation.UrlTemplate.Replace("%24search", "search");
            requestInformation.QueryParameters.Add("search", "*");
            var sites = await graphClient.RequestAdapter.SendAsync<SiteCollectionResponse>(requestInformation, SiteCollectionResponse.CreateFromDiscriminatorValue);
            return "all";
            */
        }
    }
}
