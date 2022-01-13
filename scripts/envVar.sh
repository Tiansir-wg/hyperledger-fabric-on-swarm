#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# This is a collection of bash functions used by different scripts

# imports
. scripts/utils.sh

export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export PEER0_ORG1_CA=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export PEER1_ORG1_CA=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/ca.crt
export PEER0_ORG2_CA=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export PEER1_ORG2_CA=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/tls/ca.crt

source .env

# Set environment variables for the peer org
setGlobals() {
    local USING_ORG=""
    local USING_PEER=""
    if [ -z "$OVERRIDE_ORG" ]; then
        USING_ORG=$1
        USING_PEER=$2
    else
        USING_ORG="${OVERRIDE_ORG}"
        USING_PEER=$2
    fi
    infoln "Using organization ${USING_ORG}"
    if [ $USING_ORG -eq 1 ]; then
        export CORE_PEER_LOCALMSPID="Org1MSP"
        export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
        infoln "Using peer ${USING_PEER}"
        if [ $USING_PEER -eq 0 ]; then
            export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
            export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
        else
            export CORE_PEER_TLS_ROOTCERT_FILE=$PEER1_ORG1_CA
            export CORE_PEER_ADDRESS=peer1.org1.example.com:8051
        fi

    elif [ $USING_ORG -eq 2 ]; then
        export CORE_PEER_LOCALMSPID="Org2MSP"
        export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
        infoln "Using peer ${USING_PEER}"
        if [ $USING_PEER -eq 0 ]; then
            export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG2_CA
            export CORE_PEER_ADDRESS=peer0.org2.example.com:9051
        else
            export CORE_PEER_TLS_ROOTCERT_FILE=$PEER1_ORG2_CA
            export CORE_PEER_ADDRESS=peer1.org2.example.com:10051
        fi
    else
        errorln "ORG Unknown"
    fi

    if [ "$VERBOSE" == "true" ]; then
        env | grep CORE
    fi
}

# Set environment variables for use in the CLI container
setGlobalsCLI() {
    setGlobals $1 0

    local USING_ORG=""
    if [ -z "$OVERRIDE_ORG" ]; then
        USING_ORG=$1
    else
        USING_ORG="${OVERRIDE_ORG}"
    fi
    if [ $USING_ORG -eq 1 ]; then
        export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
    elif [ $USING_ORG -eq 2 ]; then
        export CORE_PEER_ADDRESS=peer0.org2.example.com:7051
    else
        errorln "ORG Unknown"
    fi
}

# parsePeerConnectionParameters $@
# Helper function that sets the peer connection parameters for a chaincode
# operation
parsePeerConnectionParameters() {
    PEER_CONN_PARMS=""
    PEERS=""
    while [ "$#" -gt 0 ]; do
        setGlobals $1 $2
        PEER="peer$2.org$1"
        ## Set peer addresses
        PEERS="$PEERS $PEER"
        PEER_CONN_PARMS="$PEER_CONN_PARMS --peerAddresses $CORE_PEER_ADDRESS"
        ## Set path to TLS certificate
        TLSINFO=$(eval echo "--tlsRootCertFiles \$PEER0_ORG$1_CA")
        PEER_CONN_PARMS="$PEER_CONN_PARMS $TLSINFO"
        # shift by one to get to the next organization
        shift 2
    done
    # remove leading space for output
    PEERS="$(echo -e "$PEERS" | sed -e 's/^[[:space:]]*//')"
}

verifyResult() {
    if [ $1 -ne 0 ]; then
        fatalln "$2"
    fi
}
