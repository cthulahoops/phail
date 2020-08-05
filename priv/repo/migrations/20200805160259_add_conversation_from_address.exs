defmodule Phail.Repo.Migrations.AddConversationFromAddress do
  use Ecto.Migration

  def change do
    create table(:conversation_from_address, primary_key: false) do
      add :conversation_id, references(:conversations)
      add :address_id, references(:addresses)
    end

    create unique_index(:conversation_from_address, [:conversation_id, :address_id])
  end
end
