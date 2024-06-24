try{
  $url = 'https://www.cradlepointecm.com/api/v2'
  $limit = 50
  $flags = @(
    '-s',
    '--retry', $Env:attempts,
    '--retry-connrefused',
    '--retry-max-time', '30',
    '-H', "X-ECM-API-ID:$Env:X_ECM_API_ID",
    '-H', "X-ECM-API-KEY:$Env:X_ECM_API_KEY",
    '-H', "X-CP-API-ID:$Env:X_CP_API_ID",
    '-H', "X-CP-API-KEY:$Env:X_CP_API_KEY"
  )
  function Clean {
    param(
      [Parameter(Mandatory)]
      [string]$Name
    )
    $Name = $Name -replace '[^ \w\-\.]', '_'
    $Name = $Name.Trim()
    $Name
  }
  $req = "$url/routers/?limit=$limit&fields=id,serial_number,group,name,mac,state,description,config_status,ipv4_address,full_product_name"
  $groupNames = @{}
  $count = 0
  while ($null -ne $req){
    if ($count -gt 50){
      $count = 0
      Start-Sleep 10
    }
    $x = curl.exe '-X' 'GET' @flags $req
    if ($?){
      $count++
    }else{
      Write-Host "Request failed: $req"
      $x
      exit 1
    }
    $x = $x | ConvertFrom-Json -AsHashtable -NoEnumerate
    $req = $x['meta']['next']
    foreach ($router in $x['data']){
      if ($router['state'] -ne 'initialized'){
        if ($null -eq $router['group']){
          $group = 'null'
        }elseif ($groupNames.ContainsKey($router['group'])){
          $group = $groupNames[$router['group']]
        }else{
          if ($count -gt 50){
            $count = 0
            Start-Sleep 10
          }
          $req2 = "$($router['group'])?fields=name,configuration,id"
          $groupConfig = curl.exe '-X' 'GET' @flags $req2
          if ($?){
            $count++
          }else{
            Write-Host "Request failed: $req2"
            $groupConfig
            exit 1
          }
          $groupConfig_ = $groupConfig | ConvertFrom-Json -AsHashtable -NoEnumerate
          $group = "$(Clean -Name $groupConfig_['name']) - $($groupConfig_['id']).json"
          $groupNames[$router['group']] = $group
          $groupFile = Join-Path -Path $Env:data -ChildPath "groups\$group"
          $groupConfig | Out-File -FilePath $groupFile -Force -Encoding utf8
        }
        if ($count -gt 50){
          $count = 0
          Start-Sleep 10
        }
        $req2 = "$url/configuration_managers/?fields=configuration&router=$($router['id'])"
        $config = curl.exe '-X' 'GET' @flags $req2
        if ($?){
          $count++
        }else{
          Write-Host "Request failed: $req2"
          $config
          exit 1
        }
        $config = $config | ConvertFrom-Json -AsHashtable -NoEnumerate
        $config['id'] = $router['id']
        $config['name'] = $router['name']
        $config['description'] = $router['description']
        $config['full_product_name'] = $router['full_product_name']
        $config['serial_number'] = $router['serial_number']
        $config['mac'] = $router['mac']
        $config['group'] = $group
        $config['state'] = $router['state']
        $config['config_status'] = $router['config_status']
        $config['ipv4_address'] = $router['ipv4_address']
        $config = $config | ConvertTo-Json -Compress -Depth 64
        $routerFile = Join-Path -Path $Env:data -ChildPath "routers\$(Clean -Name $router['name']) - $($router['id']).json"
        $config | Out-File -FilePath $routerFile -Force -Encoding utf8
      }
    }
  }
}catch{
  $_
  exit 1
}
exit 0