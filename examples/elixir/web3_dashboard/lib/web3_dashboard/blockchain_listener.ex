defmodule Web3Dashboard.BlockchainListener do
  @moduledoc """
  Listens to new blocks and broadcasts updates via PubSub.
  Implements GenServer with automatic reconnection and error recovery.
  """

  use GenServer
  require Logger

  alias Web3Dashboard.EthereumClient

  @poll_interval 12_000  # 12 seconds (Ethereum block time)
  @pubsub Web3Dashboard.PubSub

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Subscribe to blockchain updates.
  """
  def subscribe do
    Phoenix.PubSub.subscribe(@pubsub, "blockchain:updates")
  end

  @doc """
  Get current blockchain stats.
  """
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  # Server callbacks

  @impl true
  def init(state) do
    Logger.info("Starting blockchain listener")

    initial_state = %{
      last_block: nil,
      gas_price: nil,
      block_count: 0,
      error_count: 0
    }

    # Schedule first poll
    schedule_poll()

    {:ok, Map.merge(initial_state, state)}
  end

  @impl true
  def handle_info(:poll_blockchain, state) do
    new_state = poll_and_broadcast(state)
    schedule_poll()
    {:noreply, new_state}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = %{
      last_block: state.last_block,
      gas_price: state.gas_price,
      blocks_processed: state.block_count,
      errors: state.error_count
    }

    {:reply, {:ok, stats}, state}
  end

  # Private functions

  defp schedule_poll do
    Process.send_after(self(), :poll_blockchain, @poll_interval)
  end

  defp poll_and_broadcast(state) do
    with {:ok, block_hex} <- EthereumClient.get_block_number(),
         {:ok, gas_price_hex} <- EthereumClient.get_gas_price() do

      block_number = hex_to_integer(block_hex)
      gas_price_gwei = hex_to_gwei(gas_price_hex)

      # Check if new block
      if state.last_block != block_number do
        broadcast_update(%{
          block_number: block_number,
          gas_price: gas_price_gwei,
          timestamp: DateTime.utc_now()
        })

        Logger.debug("New block: #{block_number}, Gas: #{gas_price_gwei} Gwei")

        %{state |
          last_block: block_number,
          gas_price: gas_price_gwei,
          block_count: state.block_count + 1
        }
      else
        %{state | gas_price: gas_price_gwei}
      end
    else
      {:error, reason} ->
        Logger.error("Failed to poll blockchain: #{inspect(reason)}")
        %{state | error_count: state.error_count + 1}
    end
  end

  defp broadcast_update(data) do
    Phoenix.PubSub.broadcast(@pubsub, "blockchain:updates", {:blockchain_update, data})
  end

  defp hex_to_integer("0x" <> hex) do
    {int, ""} = Integer.parse(hex, 16)
    int
  end

  defp hex_to_integer(hex) when is_binary(hex) do
    {int, ""} = Integer.parse(hex, 16)
    int
  end

  defp hex_to_gwei(hex_wei) do
    wei = hex_to_integer(hex_wei)
    # Convert wei to Gwei (divide by 10^9)
    Decimal.div(Decimal.new(wei), Decimal.new(1_000_000_000))
    |> Decimal.round(2)
    |> Decimal.to_float()
  end
end
