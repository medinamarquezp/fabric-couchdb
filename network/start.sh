#!/bin/bash

function clearExistingNetworks() {
    # Delete traces of previously created networks
    # 🔥 Caution, the following Docker commands delete all Docker data. You should not run them if you have other containers running that you do not want to delete.
    echo 'Removing all previously existing networks configurations'
    docker stop $(docker ps -a -q)
    docker rm $(docker ps -a -q)
    docker volume prune
    docker network prune
    rm -rf organizations/peerOrganizations
    rm -rf organizations/ordererOrganizations
    sudo rm -rf organizations/fabric-ca/org1/
    sudo rm -rf organizations/fabric-ca/org2/
    sudo rm -rf organizations/fabric-ca/ordererOrg/
    rm -rf channel-artifacts/
    mkdir channel-artifacts
}

function startCAs() {
    echo 'Starting CA'
    docker-compose -f ./docker/docker-compose-ca.yaml up -d
}

function registerNodes() {
    echo 'Registering certificates for each node'
    . ./organizations/fabric-ca/registerEnroll.sh && createorderer
    . ./organizations/fabric-ca/registerEnroll.sh && createorg1
    . ./organizations/fabric-ca/registerEnroll.sh && createorg2
}

function startNetwork() {
    echo 'Starting all network nodes'
    docker-compose -f ./docker/docker-compose-network.yaml -f ./docker/docker-compose-couchdb.yaml up -d
}

function startGeneralChannel() {
    # Orderer node starts and joins general channel
    echo 'Orderer node starts and joins general channel'
    export FABRIC_CFG_PATH=${PWD}/configtx
    configtxgen -profile ChannelsGenesis -outputBlock ./channel-artifacts/generalchannel.block -channelID generalchannel
    export FABRIC_CFG_PATH=${PWD}/../config
    export ORDERER_CA=${PWD}/organizations/ordererOrganizations/network.com/orderers/orderer.network.com/msp/tlscacerts/tlsca.network.com-cert.pem
    export ORDERER_ADMIN_TLS_SIGN_CERT=${PWD}/organizations/ordererOrganizations/network.com/orderers/orderer.network.com/tls/server.crt
    export ORDERER_ADMIN_TLS_PRIVATE_KEY=${PWD}/organizations/ordererOrganizations/network.com/orderers/orderer.network.com/tls/server.key
    osnadmin channel join --channelID generalchannel --config-block ./channel-artifacts/generalchannel.block -o localhost:7053 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY"

    # org1 node joins general channel
    echo 'org1 node joins general channel'
    export CORE_PEER_TLS_ENABLED=true
    export PEER0_org1_CA=${PWD}/organizations/peerOrganizations/org1.network.com/peers/peer0.org1.network.com/tls/ca.crt
    export CORE_PEER_LOCALMSPID="org1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_org1_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.network.com/users/Admin@org1.network.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
    peer channel join -b ./channel-artifacts/generalchannel.block

    # org2 node joins general channel
    echo 'org2 node joins general channel'
    export CORE_PEER_TLS_ENABLED=true
    export PEER1_org2_CA=${PWD}/organizations/peerOrganizations/org2.network.com/peers/peer1.org2.network.com/tls/ca.crt
    export CORE_PEER_LOCALMSPID="org2MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER1_org2_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.network.com/users/Admin@org2.network.com/msp
    export CORE_PEER_ADDRESS=localhost:9051
    peer channel join -b ./channel-artifacts/generalchannel.block
}