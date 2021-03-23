defmodule Phail.Repo.Migrations.MultipleAddresses do
  use Ecto.Migration

  def change do
    create table(:message_addresses, primary_key: true) do
      add :order, :serial
      add :type, :text, null: false
      add :address, :text, null: false
      add :name, :text
      add :message_id, references(:messages, on_delete: :delete_all)
    end

    create index(:message_addresses, [:address, :name])
  end
end
