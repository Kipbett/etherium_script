# Define container names
$geth1Name = "geth-node-1"
$geth2Name = "geth-node-2"

# Start first Geth node
docker run -d --name $geth1Name --network mynet ethereum/geth:latest --datadir /data/geth1 --mine --rpc --rpc.addr 0.0.0.0:8545 --rpc.port 8545 --unlock 0xACCOUNT1_PUBLIC_KEY --password password1

# Start second Geth node
docker run -d --name $geth2Name --network mynet ethereum/geth:latest --datadir /data/geth2 --rpc --rpc.addr 0.0.0.0:8546 --rpc.port 8546 --unlock 0xACCOUNT2_PUBLIC_KEY --password password2

# Simulate connecting nodes
docker exec $geth1Name admin.addPeer "enode://NODE1_ENODE_URL@"
docker exec $geth2Name admin.addPeer "enode://NODE2_ENODE_URL@"

# Define account balances (replace with actual account public keys)
$account1 = "0xACCOUNT1_PUBLIC_KEY"
$account2 = "0xACCOUNT2_PUBLIC_KEY"

# Simulate transaction (replace with actual values)
$amount = 10

# Get current balance of account 1
$balance1 = docker exec $geth1Name eth.getBalance $account1

# Insufficient balance check (optional)
if ($balance1 -lt $amount) {
  Write-Host "Error: Insufficient balance in account 1."
  exit
}

# Simulate transaction by setting account 2 balance
docker exec $geth1Name eth.sendTransaction {from: $account1, to: $account2, value: $amount}

# Get balance of account 1 after transaction
$balance1After = docker exec $geth1Name eth.getBalance $account1

Write-Host "Account 1 Balance Before: $balance1"
Write-Host "Account 1 Balance After: $balance1After"

# Stop Geth nodes
docker stop $geth1Name $geth2Name

# Remove Geth containers (optional)
docker rm $geth1Name $geth2Name

Write-Host "Script completed."
