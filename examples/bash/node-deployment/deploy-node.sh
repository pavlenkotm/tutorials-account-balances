#!/bin/bash

###############################################################################
# Ethereum Node Deployment Script
# Automates the deployment and management of Ethereum nodes
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
NODE_TYPE="${NODE_TYPE:-geth}"  # geth, besu, nethermind
NETWORK="${NETWORK:-sepolia}"
DATA_DIR="${DATA_DIR:-./ethereum-data}"
HTTP_PORT="${HTTP_PORT:-8545}"
WS_PORT="${WS_PORT:-8546}"
P2P_PORT="${P2P_PORT:-30303}"

###############################################################################
# Helper Functions
###############################################################################

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    log_info "Docker found: $(docker --version)"
}

check_ports() {
    log_info "Checking if ports are available..."

    for port in $HTTP_PORT $WS_PORT $P2P_PORT; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            log_warn "Port $port is already in use"
        else
            log_info "Port $port is available"
        fi
    done
}

###############################################################################
# Deployment Functions
###############################################################################

deploy_geth() {
    log_info "Deploying Geth node for $NETWORK..."

    docker run -d \
        --name ethereum-geth-$NETWORK \
        -v $DATA_DIR:/root/.ethereum \
        -p $HTTP_PORT:8545 \
        -p $WS_PORT:8546 \
        -p $P2P_PORT:30303 \
        ethereum/client-go:latest \
        --$NETWORK \
        --http \
        --http.addr "0.0.0.0" \
        --http.api "eth,net,web3,personal" \
        --ws \
        --ws.addr "0.0.0.0" \
        --ws.api "eth,net,web3"

    log_info "Geth node deployed successfully!"
}

deploy_besu() {
    log_info "Deploying Besu node for $NETWORK..."

    docker run -d \
        --name ethereum-besu-$NETWORK \
        -v $DATA_DIR:/var/lib/besu \
        -p $HTTP_PORT:8545 \
        -p $WS_PORT:8546 \
        -p $P2P_PORT:30303 \
        hyperledger/besu:latest \
        --network=$NETWORK \
        --rpc-http-enabled \
        --rpc-http-host="0.0.0.0" \
        --rpc-ws-enabled \
        --rpc-ws-host="0.0.0.0"

    log_info "Besu node deployed successfully!"
}

###############################################################################
# Management Functions
###############################################################################

node_status() {
    log_info "Checking node status..."

    container_name="ethereum-$NODE_TYPE-$NETWORK"

    if docker ps --filter "name=$container_name" --format '{{.Names}}' | grep -q $container_name; then
        log_info "Node is running"
        docker stats --no-stream $container_name
    else
        log_warn "Node is not running"
    fi
}

node_logs() {
    log_info "Fetching node logs..."
    docker logs -f ethereum-$NODE_TYPE-$NETWORK
}

node_stop() {
    log_info "Stopping node..."
    docker stop ethereum-$NODE_TYPE-$NETWORK
    log_info "Node stopped"
}

node_start() {
    log_info "Starting node..."
    docker start ethereum-$NODE_TYPE-$NETWORK
    log_info "Node started"
}

node_remove() {
    log_warn "Removing node and data..."
    read -p "Are you sure? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker rm -f ethereum-$NODE_TYPE-$NETWORK
        rm -rf $DATA_DIR
        log_info "Node removed"
    fi
}

###############################################################################
# Health Checks
###############################################################################

health_check() {
    log_info "Performing health check..."

    # Check if node is syncing
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
        http://localhost:$HTTP_PORT)

    log_info "Sync status: $response"

    # Check block number
    block_response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
        http://localhost:$HTTP_PORT)

    log_info "Latest block: $block_response"
}

###############################################################################
# Main Script
###############################################################################

show_usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  deploy    - Deploy new Ethereum node"
    echo "  status    - Check node status"
    echo "  logs      - View node logs"
    echo "  start     - Start stopped node"
    echo "  stop      - Stop running node"
    echo "  remove    - Remove node and data"
    echo "  health    - Perform health check"
    echo ""
    echo "Environment variables:"
    echo "  NODE_TYPE   - Node client (geth, besu) [default: geth]"
    echo "  NETWORK     - Network (mainnet, sepolia, goerli) [default: sepolia]"
    echo "  DATA_DIR    - Data directory [default: ./ethereum-data]"
    echo "  HTTP_PORT   - HTTP RPC port [default: 8545]"
    echo "  WS_PORT     - WebSocket port [default: 8546]"
    echo "  P2P_PORT    - P2P port [default: 30303]"
}

main() {
    local command="${1:-}"

    if [ -z "$command" ]; then
        show_usage
        exit 0
    fi

    log_info "Ethereum Node Deployment Tool"
    log_info "=============================="
    log_info "Node Type: $NODE_TYPE"
    log_info "Network: $NETWORK"
    log_info ""

    case "$command" in
        deploy)
            check_docker
            check_ports
            case "$NODE_TYPE" in
                geth) deploy_geth ;;
                besu) deploy_besu ;;
                *) log_error "Unknown node type: $NODE_TYPE"; exit 1 ;;
            esac
            ;;
        status) node_status ;;
        logs) node_logs ;;
        start) node_start ;;
        stop) node_stop ;;
        remove) node_remove ;;
        health) health_check ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
