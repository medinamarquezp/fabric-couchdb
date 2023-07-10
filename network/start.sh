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