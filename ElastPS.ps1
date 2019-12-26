function elk {
              param(
                    $srv,
                    $port = "9200",
                    $user,
                    $pass,
                    $https = $false,
                    $ignore_ssl = $false,

                    $metod = "POST", # 'GET','POST','DELETE','PUT'
                    $ContentType = "application/json; charset=UTF-8",
                    $index,
                    $uri_param,

                    [Parameter(Mandatory=$true)]
                    [ValidateSet('search','search_partition','index_create','index_delete','insert_single','insert_bulk','delete_by_query','custom')]
                    $action, # search|search_partition|index_create|index_delete|insert_single|insert_bulk|delete_by_query
                    $query, #search|search_partition|delete_by_query|custom
                    $ins_json_data, # insert_single|insert_bulk
                    $partition = $null
                    
                    )
                    function Ignore-SelfSignedCerts{
                                try
                                    {
                                    Write-Host "Adding TrustAllCertsPolicy type." -ForegroundColor White
                                    Add-Type -TypeDefinition @"
                                    using System.Net;
                                    using System.Security.Cryptography.X509Certificates;
                                    public class TrustAllCertsPolicy : ICertificatePolicy
                                    {
                                    public bool CheckValidationResult(
                                    ServicePoint srvPoint, X509Certificate certificate,
                                    WebRequest request, int certificateProblem)
                                    {
                                    return true;
                                    }
                                    }
"@
                                    Write-Host "TrustAllCertsPolicy type added." -ForegroundColor White}
                               catch
                                    {Write-Host $_ -ForegroundColor "Yellow"}
                               [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}

                    $result = @()
                    $Header = @{Authorization=("Basic {0}" -f ([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $user, $pass)))))}

                    if($https -eq $true){$h = "https"
                                         if($ignore_ssl -eq $true) {
                                                Ignore-SelfSignedCerts;
                                                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
                                                }
                                        }
                    else{$h = "http"}

                    $url = "{0}://{1}:{2}/{3}{4}" -f $h,$srv,$port,$index,$uri_param

                    switch ($action){
                    "search" {
                              $payload = $query
                              $url = "{0}/_search" -f $url
                              $result += Invoke-RestMethod -Method $metod -Uri $url -ContentType $ContentType -Headers $Header -body $payload
                              }
                    "search_partition" {
                              $payloads = @()
                              for ($i = 0; $i -lt $partition; $i ++){
                                $rep = '"partition": '+$i+',"num_partitions": '+$partition
                                $payloads+=[regex]::replace($q,"`"partition`": \d+,`"num_partitions`": \d+",$rep)
                              }
                              $url = "{0}/_search" -f $url
                              foreach ($payload in $payloads)
                                {$result += Invoke-RestMethod -Method $metod -Uri $url -ContentType $ContentType -Headers $Header -body $payload}
                              }
                    "index_create" {
                                    $metod = "PUT"
                                    $result += Invoke-RestMethod -Method $metod -Uri $url -ContentType $ContentType -Headers $Header
                                    }
                    "index_delete" {
                                    $metod = "DELETE"
                                    $result += Invoke-RestMethod -Method $metod -Uri $url -ContentType $ContentType -Headers $Header
                                    }
                    "insert_single" {
                                     $payload = $ins_json_data
                                     $url = "{0}/_doc" -f $url
                                     $result += Invoke-RestMethod -Method $metod -Uri $url -ContentType $ContentType -Headers $Header -body $payload
                                     }
                    "insert_bulk" {
                                   
                                   $url = "{0}/_doc/_bulk" -f $url
                                   $newLine = "`r`n" 	
                                   $indexInfo = "{""index"":{}}" + $newLine
                                   $count = 0
                                   $payload = [System.Text.StringBuilder]::new()
                                   foreach ($i in $ins_json_data){
                                        $payload.AppendLine($indexInfo + $i)
                                        $count++
                                        if(($count % $partition) -eq 0) {
                                            $result += Invoke-WebRequest -Method $metod -ContentType $ContentType -Uri $url -Headers $Header -body ($payload.ToString())
                                   	        $payload.Clear()
			                                }	  	
                                          }
                                   if($payload.Length -gt 0) {
                                        $result += Invoke-WebRequest -Method $metod -ContentType $ContentType -Uri $url -Headers $Header -body ($payload.ToString())
                                   	    $payload.Clear()
                                        }
                                   }
                    "delete_by_query" {$payload = $query
                                       $url = "{0}/_delete_by_query" -f $url
                                       $result += Invoke-RestMethod -Method $metod -Uri $url -ContentType $ContentType -Headers $Header -body $payload
                                        }
                    default { 
                             $payload = $query
                             $result += Invoke-RestMethod -Method $metod -Uri $url -ContentType $ContentType -Headers $Header -body $payload
                             }
                    }



                    return $result

              
              }
