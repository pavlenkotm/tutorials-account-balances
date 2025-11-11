defmodule Web3Dashboard.EthereumClient do
  @moduledoc """
  Ethereum JSON-RPC client with connection pooling and retry logic.
  """

  use GenServer
  require Logger

  @rpc_url Application.compile_env(:web3_dashboard, :rpc_url, "https://eth.llamarpc.com")
  @max_retries 3
  @retry_delay 1000

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Get account balance with automatic retry.
  """
  def get_balance(address) when is_binary(address) do
    GenServer.call(__MODULE__, {:get_balance, address})
  end

  @doc """
  Get current block number.
  """
  def get_block_number do
    GenServer.call(__MODULE__, :get_block_number)
  end

  @doc """
  Get transaction by hash.
  """
  def get_transaction(tx_hash) when is_binary(tx_hash) do
    GenServer.call(__MODULE__, {:get_transaction, tx_hash})
  end

  @doc """
  Get gas price in wei.
  """
  def get_gas_price do
    GenServer.call(__MODULE__, :get_gas_price)
  end

  # Server callbacks

  @impl true
  def init(state) do
    Logger.info("Starting Ethereum client with RPC: #{@rpc_url}")
    {:ok, state}
  end

  @impl true
  def handle_call({:get_balance, address}, _from, state) do
    result = retry_rpc_call(fn ->
      Ethereumex.HttpClient.eth_get_balance(address, "latest")
    end)

    {:reply, result, state}
  end

  @impl true
  def handle_call(:get_block_number, _from, state) do
    result = retry_rpc_call(fn ->
      Ethereumex.HttpClient.eth_block_number()
    end)

    {:reply, result, state}
  end

  @impl true
  def handle_call({:get_transaction, tx_hash}, _from, state) do
    result = retry_rpc_call(fn ->
      Ethereumex.HttpClient.eth_get_transaction_by_hash(tx_hash)
    end)

    {:reply, result, state}
  end

  @impl true
  def handle_call(:get_gas_price, _from, state) do
    result = retry_rpc_call(fn ->
      Ethereumex.HttpClient.eth_gas_price()
    end)

    {:reply, result, state}
  end

  # Private functions

  defp retry_rpc_call(func, attempt \\ 1) do
    case func.() do
      {:ok, result} ->
        {:ok, result}

      {:error, reason} = error ->
        if attempt < @max_retries and retryable_error?(reason) do
          Logger.warn("RPC call failed (attempt #{attempt}/#{@max_retries}): #{inspect(reason)}")
          Process.sleep(@retry_delay * attempt)
          retry_rpc_call(func, attempt + 1)
        else
          Logger.error("RPC call failed after #{attempt} attempts: #{inspect(reason)}")
          error
        end
    end
  end

  defp retryable_error?(reason) do
    error_string = to_string(reason)

    String.contains?(error_string, ["timeout", "network", "connection", "unavailable"]) or
      is_tuple(reason) and elem(reason, 0) in [:timeout, :econnrefused, :nxdomain]
  end
end
