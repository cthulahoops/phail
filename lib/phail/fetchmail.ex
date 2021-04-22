defmodule Phail.Fetchmail do
  alias Phail.MailAccount
  def gen_config_file(filename) do
    mda = Application.fetch_env!(:phail, :mda)
    file = File.open!(filename, [:write])
    for account <- MailAccount.all() do
      IO.puts(file, "poll #{inspect account.fetch_server} protocol #{Atom.to_string account.fetch_protocol} user #{inspect account.fetch_username} there with password #{inspect account.fetch_password} mda \"#{ mda } #{ account.user.email }\" fetchall\n")
    end
    File.close(file)
    File.chmod(filename, 0o700)
  end
end
