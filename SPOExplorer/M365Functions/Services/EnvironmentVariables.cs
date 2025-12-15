using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace M365Functions.Services
{
    internal class EnvironmentVariables
    {
        public static string GetByName(string name)
        {
            string? val = System.Environment.GetEnvironmentVariable(name);
            if (val == null)
            {
                throw new InvalidDataException($"Value empty or null for Environment Variable: {name}");
            }
            return val;
        }
    }
}
