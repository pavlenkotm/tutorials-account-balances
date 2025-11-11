defmodule Web3Dashboard.Application do
  @moduledoc """
  Main application supervisor for Web3 Dashboard.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Telemetry supervisor
      Web3DashboardWeb.Telemetry,
      # PubSub system
      {Phoenix.PubSub, name: Web3Dashboard.PubSub},
      # Web3 connection pool
      {Web3Dashboard.EthereumClient, []},
      # Blockchain event listener
      {Web3Dashboard.BlockchainListener, []},
      # Endpoint (HTTP/WS server)
      Web3DashboardWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Web3Dashboard.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    Web3DashboardWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
