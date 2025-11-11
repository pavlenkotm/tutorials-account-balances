defmodule Web3DashboardWeb.DashboardLive do
  @moduledoc """
  Phoenix LiveView component for real-time Web3 dashboard.
  Displays account balances, blockchain stats, and live updates.
  """

  use Web3DashboardWeb, :live_view
  require Logger

  alias Web3Dashboard.{EthereumClient, BlockchainListener}

  @impl true
  def mount(_params, _session, socket) do
    # Subscribe to blockchain updates
    if connected?(socket) do
      BlockchainListener.subscribe()
    end

    # Load initial stats
    {:ok, stats} = BlockchainListener.get_stats()

    socket =
      socket
      |> assign(:address, "")
      |> assign(:balance, nil)
      |> assign(:loading, false)
      |> assign(:error, nil)
      |> assign(:block_number, stats.last_block)
      |> assign(:gas_price, stats.gas_price)
      |> assign(:watched_addresses, [])
      |> assign(:page_title, "Web3 Dashboard")

    {:ok, socket}
  end

  @impl true
  def handle_event("check_balance", %{"address" => address}, socket) do
    socket = assign(socket, :loading, true, :error, nil)

    send(self(), {:fetch_balance, address})

    {:noreply, socket}
  end

  @impl true
  def handle_event("add_to_watchlist", %{"address" => address}, socket) do
    if valid_address?(address) and address not in socket.assigns.watched_addresses do
      watched = [%{address: address, balance: nil} | socket.assigns.watched_addresses]
      socket = assign(socket, :watched_addresses, watched)

      # Fetch balance for new address
      send(self(), {:update_watchlist, address})

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("remove_from_watchlist", %{"address" => address}, socket) do
    watched = Enum.reject(socket.assigns.watched_addresses, &(&1.address == address))
    {:noreply, assign(socket, :watched_addresses, watched)}
  end

  @impl true
  def handle_info({:fetch_balance, address}, socket) do
    case EthereumClient.get_balance(address) do
      {:ok, balance_hex} ->
        balance_eth = hex_to_eth(balance_hex)

        socket =
          socket
          |> assign(:address, address)
          |> assign(:balance, balance_eth)
          |> assign(:loading, false)
          |> assign(:error, nil)

        {:noreply, socket}

      {:error, reason} ->
        Logger.error("Failed to fetch balance: #{inspect(reason)}")

        socket =
          socket
          |> assign(:loading, false)
          |> assign(:error, "Failed to fetch balance: #{inspect(reason)}")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:update_watchlist, address}, socket) do
    case EthereumClient.get_balance(address) do
      {:ok, balance_hex} ->
        balance_eth = hex_to_eth(balance_hex)

        watched =
          Enum.map(socket.assigns.watched_addresses, fn item ->
            if item.address == address do
              %{item | balance: balance_eth}
            else
              item
            end
          end)

        {:noreply, assign(socket, :watched_addresses, watched)}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:blockchain_update, data}, socket) do
    socket =
      socket
      |> assign(:block_number, data.block_number)
      |> assign(:gas_price, data.gas_price)

    # Update all watched addresses
    Enum.each(socket.assigns.watched_addresses, fn item ->
      send(self(), {:update_watchlist, item.address})
    end)

    {:noreply, socket}
  end

  # Private functions

  defp hex_to_eth("0x" <> hex) do
    {wei, ""} = Integer.parse(hex, 16)
    # Convert wei to ETH (divide by 10^18)
    Decimal.div(Decimal.new(wei), Decimal.new(1_000_000_000_000_000_000))
    |> Decimal.round(6)
    |> Decimal.to_string()
  end

  defp valid_address?("0x" <> address) when byte_size(address) == 40 do
    String.match?(address, ~r/^[0-9a-fA-F]+$/)
  end

  defp valid_address?(_), do: false

  # Template rendering

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-purple-900 via-blue-900 to-indigo-900 text-white p-8">
      <div class="max-w-7xl mx-auto">
        <!-- Header -->
        <div class="mb-8">
          <h1 class="text-5xl font-bold mb-2 bg-clip-text text-transparent bg-gradient-to-r from-cyan-400 to-purple-400">
            ⚡ Web3 Dashboard
          </h1>
          <p class="text-gray-300">Real-time Ethereum blockchain monitoring with Phoenix LiveView</p>
        </div>

        <!-- Blockchain Stats -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
          <div class="bg-white/10 backdrop-blur-lg rounded-xl p-6 border border-white/20">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-gray-400 text-sm mb-1">Latest Block</p>
                <p class="text-3xl font-bold">
                  <%= if @block_number, do: Number.Delimit.number_to_delimited(@block_number), else: "Loading..." %>
                </p>
              </div>
              <div class="w-12 h-12 bg-blue-500/20 rounded-full flex items-center justify-center">
                <span class="text-2xl">🔗</span>
              </div>
            </div>
          </div>

          <div class="bg-white/10 backdrop-blur-lg rounded-xl p-6 border border-white/20">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-gray-400 text-sm mb-1">Gas Price</p>
                <p class="text-3xl font-bold">
                  <%= if @gas_price, do: "#{@gas_price} Gwei", else: "Loading..." %>
                </p>
              </div>
              <div class="w-12 h-12 bg-green-500/20 rounded-full flex items-center justify-center">
                <span class="text-2xl">⛽</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Balance Checker -->
        <div class="bg-white/10 backdrop-blur-lg rounded-xl p-8 mb-8 border border-white/20">
          <h2 class="text-2xl font-bold mb-4">💰 Check Balance</h2>

          <form phx-submit="check_balance" class="mb-6">
            <div class="flex gap-4">
              <input
                type="text"
                name="address"
                value={@address}
                placeholder="Enter Ethereum address (0x...)"
                class="flex-1 bg-white/5 border border-white/20 rounded-lg px-4 py-3 text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-cyan-400"
                required
              />
              <button
                type="submit"
                class="bg-gradient-to-r from-cyan-500 to-blue-500 hover:from-cyan-600 hover:to-blue-600 px-8 py-3 rounded-lg font-semibold transition-all disabled:opacity-50"
                disabled={@loading}
              >
                <%= if @loading, do: "Loading...", else: "Check" %>
              </button>
            </div>
          </form>

          <%= if @balance do %>
            <div class="bg-green-500/20 border border-green-500/50 rounded-lg p-4">
              <p class="text-sm text-gray-300 mb-1">Balance</p>
              <p class="text-3xl font-bold text-green-400"><%= @balance %> ETH</p>
            </div>
          <% end %>

          <%= if @error do %>
            <div class="bg-red-500/20 border border-red-500/50 rounded-lg p-4">
              <p class="text-red-300"><%= @error %></p>
            </div>
          <% end %>
        </div>

        <!-- Watchlist -->
        <div class="bg-white/10 backdrop-blur-lg rounded-xl p-8 border border-white/20">
          <h2 class="text-2xl font-bold mb-4">👁️ Watchlist</h2>

          <%= if Enum.empty?(@watched_addresses) do %>
            <p class="text-gray-400">No addresses in watchlist. Add addresses to monitor their balances in real-time.</p>
          <% else %>
            <div class="space-y-3">
              <%= for item <- @watched_addresses do %>
                <div class="flex items-center justify-between bg-white/5 rounded-lg p-4 border border-white/10">
                  <div class="flex-1">
                    <p class="font-mono text-sm text-gray-300"><%= item.address %></p>
                    <%= if item.balance do %>
                      <p class="text-lg font-semibold text-cyan-400"><%= item.balance %> ETH</p>
                    <% else %>
                      <p class="text-sm text-gray-500">Loading...</p>
                    <% end %>
                  </div>
                  <button
                    phx-click="remove_from_watchlist"
                    phx-value-address={item.address}
                    class="text-red-400 hover:text-red-300 transition-colors"
                  >
                    ✕
                  </button>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
