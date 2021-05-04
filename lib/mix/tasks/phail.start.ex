defmodule Mix.Tasks.Phail.Start do
  use Mix.Task

  def run(_) do
    Application.put_env(:phail, :start_account_pollers, persistent: true)
    Mix.Task.run("phx.server")
  end
end
