# Install necessary dependencies using Chocolatey

function Install-Dependencies {
    # Install Chocolatey
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }
    
    # Install Git
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        choco install git -y
    }

    # Install Go programming language
    if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
        choco install golang -y
    }

    # Install Node.js
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        choco install nodejs -y
    }

    # Install Prysm Ethereum 2.0 Beacon Chain and Validator client
    if (-not (Test-Path "C:\prysm")) {
        git clone https://github.com/prysmaticlabs/prysm.git C:\prysm
        cd C:\prysm
        git checkout tags/v2.0.0-alpha.8
        ./prysm.bat beacon-chain --download-only
        ./prysm.bat validator --download-only
    }
}

# Start Ethereum 2.0 Beacon Chain
function Start-BeaconChain {
    cd C:\prysm
    Start-Process -FilePath ".\prysm.bat" -ArgumentList "beacon-chain --datadir=C:\beacon\data --interop-eth1-endpoints=YOUR_ETH1_NODE_URL" -NoNewWindow -Wait
}

# Start Validator
$ValidatorCount = 1
$WithdrawalAddress = Read-Host "Enter your withdrawal address: "  # Enter withdrawal address
$PasswordFile = "C:\prysm\validator\password.txt" # Get your password from the directory

function Start-Validator {
    cd C:\prysm
    Start-Process -FilePath ".\prysm.bat" -ArgumentList "validator --datadir=C:\validator\data --wallet-password=YOUR_WALLET_PASSWORD --wallet-dir=C:\wallets --accept-terms-of-use --launch-pad=true --keymanager=keystore" -NoNewWindow -Wait
    # Create password file
    "your-secure-password" | Out-File -FilePath $PasswordFile -Encoding ascii  # Replace with your actual secure password

    # Generate keys using Prysm deposit CLI
    docker run -it C:/prysim/keys gcr.io/prysmaticlabs/prysm/validator:latest accounts create --keystore-path=/keys --num-validators=$ValidatorCount --eth1-withdrawal-address=$WithdrawalAddress --keystore-password-file=/keys/password.txt
    # Create deposit data
    docker run -it -v C:/prysm/keys -v C:/prysm/deposits gcr.io/prysmaticlabs/prysm/validator:latest accounts create --keystore-path=/keys --deposit-datadir=/deposits --num-validators=$ValidatorCount --eth1-withdrawal-address=$WithdrawalAddress --keystore-password-file=/keys/password.txt

}

# Check node status
function Get-NodeStatus {
    $beaconStatus = Invoke-RestMethod -Uri "http://localhost:4000/eth/v1/node/version"
    $validatorStatus = Invoke-RestMethod -Uri "http://localhost:3500/eth/v1/node/version"
    
    Write-Output "Beacon Chain Status:"
    $beaconStatus
    Write-Output "Validator Status:"
    $validatorStatus
}

# Stop Beacon Chain and Validator
function Stop-EthereumNode {
    Stop-Process -Name prysm-beacon-chain -Force
    Stop-Process -Name prysm-validator -Force
}

# Main script execution starts here
Write-Output "Installing dependencies..."
Install-Dependencies

Write-Output "Starting Ethereum 2.0 Beacon Chain..."
Start-BeaconChain

Write-Output "Starting Ethereum 2.0 Validator..."
Start-Validator

# Optionally, you can monitor the node status continuously
# Uncomment the line below to monitor status continuously
while ($true) { Get-NodeStatus; Start-Sleep -Seconds 60 }

# Check status once and exit
Get-NodeStatus

# End of scripty
