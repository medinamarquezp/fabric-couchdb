# Fabric's network example with CA and CouchDB

This Hyperledger Fabric network consists of the following components:

- 2 peer nodes, whose ledgers use couchdb.
- 1 Raft orderer node.
- All nodes have their own CA.

## Instalation instructions

```sh
# Before begin we must set some environment variables in network folder
cd ./network
export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}/../config

# Next, we need to execute the following scripts to start the network
. ./start.sh && clearExistingNetworks
. ./start.sh && startCAs
. ./start.sh && registerNodes
. ./start.sh && startNetwork
. ./start.sh && startGeneralChannel
```

## Testing couchdb and transactions

This step is optional but recommended in order to review chain code transactions saved in couchdb ledger.

```sh
# Compiling nodejs application
cd ../application
npm i
cd ../network
peer lifecycle chaincode package basic.tar.gz --path ../application/ --lang node --label basic_1.0

# Installing chaincodes
export CORE_PEER_TLS_ENABLED=true
export PEER0_org1_CA=${PWD}/organizations/peerOrganizations/org1.network.com/peers/peer0.org1.network.com/tls/ca.crt
export CORE_PEER_LOCALMSPID="org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_org1_CA
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.network.com/users/Admin@org1.network.com/msp
export CORE_PEER_ADDRESS=localhost:7051
peer lifecycle chaincode install basic.tar.gz

# ⚠️ If this error occurs: Failed to pull hyperledger/fabric-nodeenv:2.3
docker pull --platform linux/x86_64 hyperledger/fabric-nodeenv:2.3

export CORE_PEER_TLS_ENABLED=true
export PEER1_org2_CA=${PWD}/organizations/peerOrganizations/org2.network.com/peers/peer1.org2.network.com/tls/ca.crt
export CORE_PEER_LOCALMSPID="org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PEER1_org2_CA
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.network.com/users/Admin@org2.network.com/msp
export CORE_PEER_ADDRESS=localhost:9051
peer lifecycle chaincode install basic.tar.gz

# Approve and operate
peer lifecycle chaincode queryinstalled
export CC_PACKAGE_ID={!!!PREV INSTRUCTION PACKAGE ID!!!}
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.network.com --channelID generalchannel --name basic --version 1.0 --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile ${PWD}/organizations/ordererOrganizations/network.com/orderers/orderer.network.com/msp/tlscacerts/tlsca.network.com-cert.pem

export CORE_PEER_TLS_ENABLED=true
export PEER0_org1_CA=${PWD}/organizations/peerOrganizations/org1.network.com/peers/peer0.org1.network.com/tls/ca.crt
export CORE_PEER_LOCALMSPID="org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_org1_CA
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.network.com/users/Admin@org1.network.com/msp
export CORE_PEER_ADDRESS=localhost:7051
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.network.com --channelID generalchannel --name basic --version 1.0 --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile ${PWD}/organizations/ordererOrganizations/network.com/orderers/orderer.network.com/msp/tlscacerts/tlsca.network.com-cert.pem


peer lifecycle chaincode checkcommitreadiness --channelID generalchannel --name basic --version 1.0 --sequence 1 --tls --cafile ${PWD}/organizations/ordererOrganizations/network.com/orderers/orderer.network.com/msp/tlscacerts/tlsca.network.com-cert.pem --output json
peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.network.com --channelID generalchannel --name basic --version 1.0 --sequence 1 --tls --cafile ${PWD}/organizations/ordererOrganizations/network.com/orderers/orderer.network.com/msp/tlscacerts/tlsca.network.com-cert.pem --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.network.com/peers/peer0.org1.network.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.network.com/peers/peer1.org2.network.com/tls/ca.crt

peer lifecycle chaincode querycommitted --channelID generalchannel --name basic --cafile ${PWD}/organizations/ordererOrganizations/network.com/orderers/orderer.network.com/msp/tlscacerts/tlsca.network.com-cert.pem
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.network.com --tls --cafile ${PWD}/organizations/ordererOrganizations/network.com/orderers/orderer.network.com/msp/tlscacerts/tlsca.network.com-cert.pem -C generalchannel -n basic --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.network.com/peers/peer0.org1.network.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.network.com/peers/peer1.org2.network.com/tls/ca.crt -c '{"function":"InitLedger","Args":[]}'

peer chaincode query -C generalchannel -n basic -c '{"Args":["GetAllAssets"]}'
```

## Access to couchdb

You can access and use couchdb for test purpose only by using next credentials:

- **URL:** http://localhost:5984/\_utils
- **Username:** admin
- **Password:** adminpw
