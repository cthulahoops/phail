defmodule Phail.Repo.Migrations.CreateMessageAddress do
  use Ecto.Migration

  def change do
    create table(:message_to_address, primary_key: false) do
      add :message_id, references(:messages, on_delete: :delete_all)
      add :address_id, references(:addresses)
    end

    create unique_index(:message_to_address, [:message_id, :address_id])

    create table(:message_from_address, primary_key: false) do
      add :message_id, references(:messages, on_delete: :delete_all)
      add :address_id, references(:addresses)
    end

    create unique_index(:message_from_address, [:message_id, :address_id])

    create table(:message_cc_address, primary_key: false) do
      add :message_id, references(:messages, on_delete: :delete_all)
      add :address_id, references(:addresses)
    end

    create unique_index(:message_cc_address, [:message_id, :address_id])
  end
end
