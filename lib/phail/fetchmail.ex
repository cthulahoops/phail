defmodule Phail.Fetchmail do
  require Logger

  def start_workers() do
    for mail_account <- Phail.MailAccount.all() do
      DynamicSupervisor.start_child(
        Phail.Fetchmail.Supervisor,
        {Phail.Fetchmail.Worker, [mail_account]}
      )
    end
  end

  def stop_worker(mail_account_id) do
    case Registry.lookup(Phail.Fetchmail.Registry, mail_account_id) do
      [{pid, _}] ->
        DynamicSupervisor.terminate_child(Phail.Fetchmail.Supervisor, pid)

      [] ->
        :ok
    end
  end

  def workers() do
    Registry.select(Phail.Fetchmail.Registry, [{{:"$1", :"$2", :_}, [], [{{:"$1", :"$2"}}]}])
  end

  def gen_config(mail_account) do
    mda = Application.fetch_env!(:phail, :mda)
    fetchmail_dir = Application.fetch_env!(:phail, :fetchmail_dir)
    filename = Path.join(fetchmail_dir, "#{mail_account.id}.config")
    file = File.open!(filename, [:write])
    gen_config(:getmail, file, mail_account, mda)
    File.close(file)
    File.chmod(filename, 0o700)
    {:ok, filename}
  end

  defp gen_config(:getmail, file, mail_account, mda) do
    {mda_path, mda_args} = split_mda(mda, mail_account.user.email)

    IO.puts(file, "[options]")
    IO.puts(file, "delete = true")
    IO.puts(file, "\n[retriever]")
    IO.puts(file, "type = SimpleIMAPSSLRetriever")
    IO.puts(file, "server = #{mail_account.fetch_server}")
    IO.puts(file, "username = #{mail_account.fetch_username}")
    IO.puts(file, "password = #{mail_account.fetch_password}")
    IO.puts(file, "\n[destination]")
    IO.puts(file, "type = MDA_external")
    IO.puts(file, "path = #{mda_path}")
    IO.puts(file, "arguments = #{mda_args}")
  end

  defp gen_config(:fetchmail, file, mail_account, mda) do
    IO.puts(
      file,
      "poll #{inspect(mail_account.fetch_server)} protocol #{
        Atom.to_string(mail_account.fetch_protocol)
      } user #{inspect(mail_account.fetch_username)} there with password #{
        inspect(mail_account.fetch_password)
      } mda \"#{mda} #{mail_account.user.email}\" fetchall idle\n"
    )
  end

  defp split_mda(mda, deliver_to_email) do
    [path | args] = String.split(mda)

    args =
      for arg <- args ++ [deliver_to_email] do
        "'#{arg}'"
      end
      |> Enum.join(", ")

    {path, "(#{args})"}
  end
end
