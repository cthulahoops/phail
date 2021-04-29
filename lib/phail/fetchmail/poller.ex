defmodule Phail.Fetchmail.Poller do
  use GenServer
  require Logger
  alias Phail.Fetchmail

  def start_link([]) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(state) do
    :timer.send_after(60_000, :start_workers)
    :timer.send_interval(600_000, :start_workers)
    {:ok, state}
  end

  def handle_info(:start_workers, state) do
    Fetchmail.start_workers()
    {:noreply, state}
  end
end
