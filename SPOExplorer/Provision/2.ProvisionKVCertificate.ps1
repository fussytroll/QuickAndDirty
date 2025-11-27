$KVName = "kv-spexplorer"
$certPolicy = az keyvault certificate get-default-policy | ConvertFrom-Json
$certPolicyJson = $($certPolicy | ConvertTo-Json -Depth 100 -Compress).Replace('"', '\"')
az keyvault certificate create --vault-name $KVName -n "Cert1" -p $certPolicyJson

















