defmodule Phail.Repo.Migrations.AddMailAccount do
  use Ecto.Migration

  def change do
    create table(:mail_accounts) do
      add :user_id, references(:users), null: false
      add :email, :text, null: false
      add :name, :text, null: false

      add :smtp_server, :text
      add :smtp_port, :integer
      add :smtp_ssl, :boolean
      add :smtp_username, :text
      add :smtp_password, :text

      add :fetch_protocol, :text
      add :fetch_server, :text
      add :fetch_port, :integer
      add :fetch_ssl, :boolean
      add :fetch_username, :text
      add :fetch_password, :text
    end
  end
end
