# Define data directories for the nodes
$node1DataDir = "C:\EthNode1"
$node2DataDir = "C:\EthNode2"

# Create the data directories if they don't exist
if (!(Test-Path $node1DataDir)) { New-Item -ItemType Directory -Path $node1DataDir }
if (!(Test-Path $node2DataDir)) { New-Item -ItemType Directory -Path $node2DataDir }

# Initialize both nodes with a genesis block
$genesisFile = "C:\Genesis\genesis.json"

if (!(Test-Path $genesisFile)) {
    Write-Host "Genesis file not found. Create a genesis.json file and place it in C:\Genesis."
    exit
}


# Function to check if a process is running
function Is-ProcessRunning {
    param(
        [string]$processName
    )
    $process = Get-Process -Name $processName -ErrorAction SilentlyContinue
    return $process -ne $null
}

# Kill any running geth processes
if (Is-ProcessRunning -processName "geth") {
    Stop-Process -Name "geth" -Force
    Start-Sleep -Seconds 5
}
# Initialize nodes with the genesis file
Start-Process -NoNewWindow -FilePath "geth" -ArgumentList "init", $genesisFile, "--datadir", $node1DataDir
Start-Process -NoNewWindow -FilePath "geth" -ArgumentList "init", $genesisFile, "--datadir", $node2DataDir

# Function to get the enode of a node
function Get-GethEnode {
    param(
        [string]$DataDir
    )
    $enode = & geth --exec "admin.nodeInfo.enode" attach ipc:$DataDir\geth.ipc
    return $enode
}

if (-not (Test-Path "C:\prysm")) {
    git clone https://github.com/prysmaticlabs/prysm.git C:\prysm
    cd C:\prysm
    git checkout tags/v2.0.0-alpha.8
    ./prysm.bat beacon-chain --download-only
    ./prysm.bat validator --download-only
}

#Configure and run Prysm
$configFilePath = "C:\Prysm\config.yml"
$configContent = @"
network: "mainnet"
datadir: "C:\prysm"
execution-endpoint: "http://127.0.0.1:8545"
jwt-secret: "$jwtFilePath"
"@
Set-Content -Path $configFilePath -Value $configContent

function Start-BeaconChain {
    cd C:\prysm
    Start-Process -FilePath ".\prysm.bat" -ArgumentList "beacon-chain --datadir=C:\beacon\data --interop-eth1-endpoints=YOUR_ETH1_NODE_URL" -NoNewWindow -Wait
}

Start-BeaconChain

#Create JWT secret file if it doesn't exist
$jwtFilePath = "C:\prysm\jwt.hex"
if (!(Test-Path $jwtFilePath)) {
    $jwtSecret = openssl rand -hex 32
    Set-Content -Path $jwtFilePath -Value $jwtSecret
}

# Start the first node
Start-Process -NoNewWindow -FilePath "geth" -ArgumentList "--datadir $node1DataDir --networkid 15 --port 30303 --http --http.addr 127.0.0.1 --http.port 8545 --http.api eth,net,web3 --http.corsdomain * --authrpc.jwtsecret $jwtFilePath --nodiscover" -Wait

# Wait for the first node to start
Start-Sleep -Seconds 30

# Get the enode address of the first node
$enode1 = Get-GethEnode -DataDir $node1DataDir

# Start the second node and connect to the first node
Start-Process -NoNewWindow -FilePath "geth" -ArgumentList "--datadir $node2DataDir --networkid 15 --port 30304 --http --http.addr 127.0.0.1 --http.port 8546 --http.api eth,net,web3 --http.corsdomain * --allow-insecure-unlock --bootnodes enode://$(Get-GethEnode -DataDir $node1DataDir)@127.0.0.1:30303 --nodiscover"

# Wait for the second node to start
Start-Sleep -Seconds 30

# Create temporary password files
$passwordFile1 = [System.IO.Path]::GetTempFileName()
$passwordFile2 = [System.IO.Path]::GetTempFileName()
Add-Content -Path $passwordFile1 -Value ""
Add-Content -Path $passwordFile2 -Value ""

# Create accounts on both nodes
$account1 = & geth --datadir $node1DataDir account new --password $passwordFile1
$account2 = & geth --datadir $node2DataDir account new --password $passwordFile2

# Wait for account creation
Start-Sleep -Seconds 40

# Extract account addresses from the output
if ($account1Output -match "Address: \{([^}]*)\}") {
    $account1 = $matches[0]
} else {
    Write-Host "Failed to create account on node 1"
    exit
}

if ($account2Output -match "Address: \{([^}]*)\}") {
    $account2 = $matches[1]
} else {
    Write-Host "Failed to create account on node 2"
    exit
}

# Unlock accounts
& geth --exec "personal.unlockAccount('$account1', '', 0)" attach http://127.0.0.1:8545
& geth --exec "personal.unlockAccount('$account2', '', 0)" attach http://127.0.0.1:8546

# Send a transaction from account1 to account2
$transactionHash = & geth --exec "eth.sendTransaction({from: '$account1', to: '$account2', value: web3.toWei(1, 'ether')})" attach http://127.0.0.1:8545

# Output the transaction hash
Write-Host "Transaction Hash: $transactionHash"

#Configure and run Prysm
$configFilePath = "C:\Prysm\config.yml"
$configContent = @"
network: "mainnet"
datadir: "C:\prysm"
execution-endpoint: "http://localhost:8551"
jwt-secret: "$jwtFilePath"
"@
Set-Content -Path $configFilePath -Value $configContent

# cd C:\Prysm
# Start-Process -NoNewWindow -FilePath ".\prysm.bat" -ArgumentList "beacon-chain --config-file=$configFilePath" -Wait