defmodule Phail.MailAccount do
  use Ecto.Schema
  import Ecto.Changeset
  import EctoEnum
  alias Phail.Accounts.User
  alias Phail.Repo

  defenum(FetchProtocol, :fetch_protocol, [:imap, :pop3])

  schema "mail_accounts" do
    field :email, :string
    field :name, :string

    field :smtp_server, :string
    field :smtp_port, :integer
    field :smtp_ssl, :boolean
    field :smtp_username, :string
    field :smtp_password, :string

    field :fetch_protocol, FetchProtocol
    field :fetch_server, :string
    field :fetch_port, :integer
    field :fetch_ssl, :boolean
    field :fetch_username, :string
    field :fetch_password, :string

    belongs_to :user, User
  end

  def create(attrs) do
    %Phail.MailAccount{}
    |> cast(attrs, [
      :user_id,
      :email,
      :name,
      :smtp_server,
      :smtp_port,
      :smtp_ssl,
      :smtp_username,
      :smtp_password,
      :fetch_protocol,
      :fetch_server,
      :fetch_port,
      :fetch_ssl,
      :fetch_username,
      :fetch_password
    ])
    |> Phail.Repo.insert()
  end

  def get_by_email(email) do
    Phail.MailAccount |> Repo.get_by!(email: email)
  end

  def get_by_user(user) do
    Phail.MailAccount |> Repo.get_by!(user_id: user.id)
  end

  defimpl Bamboo.Formatter, for: Phail.MailAccount do
    def format_email_address(account, _opts) do
      {account.name, account.email}
    end
  end
end
