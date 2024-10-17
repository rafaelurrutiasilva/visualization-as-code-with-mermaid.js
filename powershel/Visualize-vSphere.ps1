<#
.SYNOPSIS
  PowerShell script that retrieves current information from vSphere vCenter and visualizes it using Mermaid.js.

.DESCRIPTION
  Retrieves datacenters, clusters, and associated ESXi hosts, then visualizes them using Mermaid.js.

.NOTES
  Author          : Rafael Urrutia
#>

# Debugging
$DEBUG=1

# Variable
$DebugFile="c:/temp/mermaid_diagram.txt"
$htmlFilePath = "c:/temp/vSphere_DC_Visualization.html"

# Get and define the name of the data center
$datacenterName =  (Get-Datacenter).Name

# Get all the data centers and clusters in them as well as the respective ESXi server in each cluster
$clusters = Get-Cluster -Location $datacenterName

$mermaidCode = @()
$mermaidCode += "flowchart TD;"
$mermaidCode += "    subgraph $datacenterName [vSphere Datacenter $datacenterName]"

# Loop through each cluster
foreach ($cluster in $clusters) {
    $clusterName=$cluster.Name
    # Get all ESXi servers in the cluster   
    $esxiHosts=Get-VMhost -Location $clusterName
    # Match the charactecs you need to match.
    if ($esxiHosts -match "esx*"){
        $mermaidCode += "    subgraph  $($clusterName) [vSphere cluster $($clusterName)]"
        # Remove the domain name if you what to.
        $esxiHosts = $esxiHosts -replace ".domain.yours",""
        $mermaidCode += "        cluster-$clusterName($esxiHosts)"
        $mermaidCode += "        style $clusterName stroke:blue,stroke-width:1px"
        $mermaidCode += "    end"
    }
}
$mermaidCode += " end"

# Print the Mermaid code to file for debugging if desired
if ($DEBUG -eq 1){$mermaidCode -join "`n" | Out-File $DebugFile}

# Generate HTML-code
$htmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title> vSphere Datacenter $datacenterName </title>
    <center> The diagrams are generated using Mermaid.js code and rendered in your browser! </center
    <script type="module" src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            mermaid.initialize({ startOnLoad: true });
        });
    </script>
</head>
<body>
    <h2><center> vSphere Datacenter $datacenterName </center></h2>
    <div class="mermaid">
$($mermaidCode -join "`n")
    </div>
</body>
</html>
"@

# Save HTML-fil
$htmlContent | Out-File -FilePath $htmlFilePath -Encoding utf8

Write-Host "The HTML diagram has been created on: $htmlFilePath"
Start-Process $htmlFilePath
