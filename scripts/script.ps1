# EthereumNodeSetup.ps1
# This script sets up and runs an Ethereum PoS node.

# Variables
$GethPath = "C:\Program Files\Geth\geth.exe"
$DataDir = "C:\Ethereum\node"
$NetworkId = 1  # Mainnet
$NodeKey = "your-node-key"  # Replace with your node key
$RPCPort = 8545
$WSport = 8546
$RPCHost = "0.0.0.0"
$WShost = "0.0.0.0"

# Ensure the data directory exists
if (-Not (Test-Path -Path $DataDir)) {
    New-Item -ItemType Directory -Path $DataDir
}

# Command to start Geth
$startGeth = "$GethPath --datadir $DataDir --networkid $NetworkId --nodekeyhex $NodeKey --http --http.addr $RPCHost --http.port $RPCPort --ws --ws.addr $WShost --ws.port $WSport"

# Start the Geth node
Start-Process -NoNewWindow -FilePath $GethPath -ArgumentList "--datadir $DataDir --networkid $NetworkId --nodekeyhex $NodeKey --http --http.addr $RPCHost --http.port $RPCPort --ws --ws.addr $WShost --ws.port $WSport"

Write-Output "Ethereum node started with the following configuration:"
Write-Output "Data Directory: $DataDir"
Write-Output "Network ID: $NetworkId"
Write-Output "RPC Host: $RPCHost"
Write-Output "RPC Port: $RPCPort"
Write-Output "WS Host: $WShost"
Write-Output "WS Port: $WSport"