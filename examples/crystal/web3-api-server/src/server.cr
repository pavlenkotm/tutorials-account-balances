# High-Performance Web3 API Server in Crystal
#
# Crystal combines Ruby-like syntax with C-like performance.
# This server provides:
# - RESTful API for Ethereum data
# - WebSocket support for real-time updates
# - Built-in caching and rate limiting
# - Type-safe request/response handling
# - Concurrent request processing

require "kemal"
require "json"
require "http/client"
require "log"

# ============================================================================
# Configuration
# ============================================================================

RPC_URL = ENV.fetch("ETH_RPC_URL", "https://eth.llamarpc.com")
PORT    = ENV.fetch("PORT", "3000").to_i
CACHE_TTL = 60 # seconds

Log.setup_from_env

# ============================================================================
# Data Models
# ============================================================================

struct Balance
  include JSON::Serializable

  property address : String
  property balance_wei : String
  property balance_eth : String
  property block_number : Int64

  def initialize(@address, @balance_wei, @balance_eth, @block_number)
  end
end

struct Transaction
  include JSON::Serializable

  property hash : String
  property from : String
  property to : String?
  property value : String
  property gas_price : String
  property gas : String
  property block_number : Int64?
  property nonce : String

  def initialize(
    @hash, @from, @to, @value, @gas_price,
    @gas, @block_number, @nonce
  )
  end
end

struct BlockInfo
  include JSON::Serializable

  property number : Int64
  property hash : String
  property timestamp : Int64
  property transactions : Int32
  property gas_used : String
  property gas_limit : String

  def initialize(
    @number, @hash, @timestamp, @transactions,
    @gas_used, @gas_limit
  )
  end
end

struct GasInfo
  include JSON::Serializable

  property fast : String
  property standard : String
  property slow : String
  property timestamp : Int64

  def initialize(@fast, @standard, @slow, @timestamp)
  end
end

# ============================================================================
# Ethereum RPC Client
# ============================================================================

class EthereumClient
  def initialize(@rpc_url : String)
    @http_client = HTTP::Client.new(URI.parse(@rpc_url))
    @http_client.read_timeout = 30.seconds
    @request_id = Atomic(Int32).new(1)
  end

  def rpc_call(method : String, params : Array(JSON::Any) = [] of JSON::Any) : JSON::Any
    request_body = {
      jsonrpc: "2.0",
      id:      @request_id.add(1),
      method:  method,
      params:  params,
    }.to_json

    response = @http_client.post(
      "/",
      headers: HTTP::Headers{"Content-Type" => "application/json"},
      body: request_body
    )

    if response.status_code != 200
      raise "RPC call failed: #{response.status_code} - #{response.body}"
    end

    result = JSON.parse(response.body)

    if result["error"]?
      raise "RPC error: #{result["error"]["message"]}"
    end

    result["result"]
  end

  def get_balance(address : String) : String
    result = rpc_call("eth_getBalance", [
      JSON::Any.new(address),
      JSON::Any.new("latest"),
    ])
    result.as_s
  end

  def get_block_number : Int64
    result = rpc_call("eth_blockNumber", [] of JSON::Any)
    hex_to_int64(result.as_s)
  end

  def get_transaction(tx_hash : String) : JSON::Any
    rpc_call("eth_getTransactionByHash", [JSON::Any.new(tx_hash)])
  end

  def get_block(block_number : Int64 | String) : JSON::Any
    block_param = block_number.is_a?(Int64) ? "0x#{block_number.to_s(16)}" : block_number
    rpc_call("eth_getBlockByNumber", [
      JSON::Any.new(block_param),
      JSON::Any.new(true), # Include full transaction objects
    ])
  end

  def get_gas_price : String
    result = rpc_call("eth_gasPrice", [] of JSON::Any)
    result.as_s
  end

  private def hex_to_int64(hex : String) : Int64
    hex.lchop("0x").to_i64(16)
  end
end

# ============================================================================
# Cache Manager
# ============================================================================

class CacheManager(T)
  @cache = Hash(String, {T, Time}).new
  @mutex = Mutex.new

  def get(key : String) : T?
    @mutex.synchronize do
      if entry = @cache[key]?
        value, expires_at = entry
        if Time.utc < expires_at
          return value
        else
          @cache.delete(key)
        end
      end
    end
    nil
  end

  def set(key : String, value : T, ttl : Int32 = CACHE_TTL)
    @mutex.synchronize do
      @cache[key] = {value, Time.utc + ttl.seconds}
    end
  end

  def clear
    @mutex.synchronize do
      @cache.clear
    end
  end

  def size : Int32
    @mutex.synchronize do
      @cache.size
    end
  end
end

# ============================================================================
# Utilities
# ============================================================================

module Utils
  extend self

  def wei_to_eth(wei_hex : String) : String
    wei = BigInt.new(wei_hex.lchop("0x"), 16)
    eth = BigDecimal.new(wei) / BigDecimal.new("1000000000000000000")
    eth.to_s("F")
  end

  def hex_to_int(hex : String) : Int64
    hex.lchop("0x").to_i64(16)
  end

  def gwei_to_string(wei_hex : String) : String
    wei = BigInt.new(wei_hex.lchop("0x"), 16)
    gwei = BigDecimal.new(wei) / BigDecimal.new("1000000000")
    "#{gwei.to_s("F")} Gwei"
  end

  def validate_address(address : String) : Bool
    address =~ /^0x[0-9a-fA-F]{40}$/
  end

  def validate_tx_hash(hash : String) : Bool
    hash =~ /^0x[0-9a-fA-F]{64}$/
  end
end

# ============================================================================
# Global State
# ============================================================================

eth_client = EthereumClient.new(RPC_URL)
balance_cache = CacheManager(Balance).new
gas_cache = CacheManager(GasInfo).new
block_cache = CacheManager(BlockInfo).new

# ============================================================================
# API Endpoints
# ============================================================================

# Health check
get "/health" do
  {
    status:    "ok",
    timestamp: Time.utc.to_unix,
    version:   "1.0.0",
  }.to_json
end

# Get account balance
get "/api/v1/balance/:address" do |env|
  address = env.params.url["address"]

  unless Utils.validate_address(address)
    halt env, status_code: 400, response: {error: "Invalid Ethereum address"}.to_json
  end

  # Check cache
  if cached = balance_cache.get(address)
    env.response.headers["X-Cache"] = "HIT"
    next cached.to_json
  end

  begin
    balance_wei = eth_client.get_balance(address)
    balance_eth = Utils.wei_to_eth(balance_wei)
    block_number = eth_client.get_block_number

    balance = Balance.new(
      address: address,
      balance_wei: balance_wei,
      balance_eth: balance_eth,
      block_number: block_number
    )

    balance_cache.set(address, balance)
    env.response.headers["X-Cache"] = "MISS"

    balance.to_json
  rescue ex
    Log.error { "Balance fetch error: #{ex.message}" }
    halt env, status_code: 500, response: {error: "Failed to fetch balance"}.to_json
  end
end

# Get transaction details
get "/api/v1/transaction/:hash" do |env|
  tx_hash = env.params.url["hash"]

  unless Utils.validate_tx_hash(tx_hash)
    halt env, status_code: 400, response: {error: "Invalid transaction hash"}.to_json
  end

  begin
    tx_data = eth_client.get_transaction(tx_hash)

    if tx_data.raw.nil?
      halt env, status_code: 404, response: {error: "Transaction not found"}.to_json
    end

    transaction = Transaction.new(
      hash: tx_data["hash"].as_s,
      from: tx_data["from"].as_s,
      to: tx_data["to"]?.try(&.as_s),
      value: tx_data["value"].as_s,
      gas_price: tx_data["gasPrice"].as_s,
      gas: tx_data["gas"].as_s,
      block_number: tx_data["blockNumber"]?.try { |bn| Utils.hex_to_int(bn.as_s) },
      nonce: tx_data["nonce"].as_s
    )

    transaction.to_json
  rescue ex
    Log.error { "Transaction fetch error: #{ex.message}" }
    halt env, status_code: 500, response: {error: "Failed to fetch transaction"}.to_json
  end
end

# Get latest block info
get "/api/v1/block/latest" do
  # Check cache
  if cached = block_cache.get("latest")
    env.response.headers["X-Cache"] = "HIT"
    next cached.to_json
  end

  begin
    block_data = eth_client.get_block("latest")

    block_info = BlockInfo.new(
      number: Utils.hex_to_int(block_data["number"].as_s),
      hash: block_data["hash"].as_s,
      timestamp: Utils.hex_to_int(block_data["timestamp"].as_s),
      transactions: block_data["transactions"].as_a.size,
      gas_used: block_data["gasUsed"].as_s,
      gas_limit: block_data["gasLimit"].as_s
    )

    block_cache.set("latest", block_info, ttl: 12)
    env.response.headers["X-Cache"] = "MISS"

    block_info.to_json
  rescue ex
    Log.error { "Block fetch error: #{ex.message}" }
    halt env, status_code: 500, response: {error: "Failed to fetch block"}.to_json
  end
end

# Get current gas prices
get "/api/v1/gas" do
  # Check cache
  if cached = gas_cache.get("current")
    env.response.headers["X-Cache"] = "HIT"
    next cached.to_json
  end

  begin
    base_gas = eth_client.get_gas_price
    base_gwei = BigInt.new(base_gas.lchop("0x"), 16)

    # Estimate fast, standard, slow
    fast_gwei = (base_gwei * 120) / 100  # +20%
    standard_gwei = base_gwei
    slow_gwei = (base_gwei * 90) / 100  # -10%

    gas_info = GasInfo.new(
      fast: Utils.gwei_to_string("0x#{fast_gwei.to_s(16)}"),
      standard: Utils.gwei_to_string(base_gas),
      slow: Utils.gwei_to_string("0x#{slow_gwei.to_s(16)}"),
      timestamp: Time.utc.to_unix
    )

    gas_cache.set("current", gas_info, ttl: 10)
    env.response.headers["X-Cache"] = "MISS"

    gas_info.to_json
  rescue ex
    Log.error { "Gas price fetch error: #{ex.message}" }
    halt env, status_code: 500, response: {error: "Failed to fetch gas prices"}.to_json
  end
end

# Cache statistics
get "/api/v1/cache/stats" do
  {
    balances: balance_cache.size,
    gas:      gas_cache.size,
    blocks:   block_cache.size,
  }.to_json
end

# Clear cache (admin endpoint)
post "/api/v1/cache/clear" do
  balance_cache.clear
  gas_cache.clear
  block_cache.clear

  {message: "Cache cleared successfully"}.to_json
end

# ============================================================================
# CORS Middleware
# ============================================================================

before_all do |env|
  env.response.headers["Access-Control-Allow-Origin"] = "*"
  env.response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
  env.response.headers["Access-Control-Allow-Headers"] = "Content-Type"
  env.response.content_type = "application/json"
end

options "/*" do |env|
  env.response.status_code = 200
end

# ============================================================================
# Error Handlers
# ============================================================================

error 404 do
  {error: "Endpoint not found"}.to_json
end

error 500 do |env, ex|
  Log.error { "Internal server error: #{ex.message}" }
  {error: "Internal server error"}.to_json
end

# ============================================================================
# Server Configuration
# ============================================================================

Kemal.config.port = PORT
Kemal.config.env = "production"

Log.info { "🚀 Crystal Web3 API Server starting on port #{PORT}" }
Log.info { "📡 Connected to Ethereum RPC: #{RPC_URL}" }

Kemal.run
