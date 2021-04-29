defmodule Phail.Fetchmail.Worker do
  use GenServer
  require Logger

  @getmail "/usr/bin/getmail"

  def start_link([mail_account]) do
    GenServer.start_link(__MODULE__, [mail_account],
      name: {:via, Registry, {Phail.Fetchmail.Registry, mail_account.id}}
    )
  end

  def init([mail_account]) do
    {:ok, filename} = Phail.Fetchmail.gen_config(mail_account)
    {:ok, open_port(filename)}
  end

  def open_port(filename) do
    stdin_killer = Application.fetch_env!(:phail, :stdin_killer)
    args = [@getmail, "-r", filename, "--idle", "INBOX"]
    Port.open({:spawn_executable, stdin_killer}, [:binary, :exit_status, args: args])
  end

  def handle_info({port, {:data, text}}, state) do
    Logger.info("Fetchmail: #{inspect(port)} #{text}")

    {:noreply, state}
  end

  def handle_info({port, exit_status = {:exit_status, _}}, state) do
    {:stop, {:port_exit, port, exit_status}, state}
  end
end
