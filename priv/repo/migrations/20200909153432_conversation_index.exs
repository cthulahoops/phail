defmodule Phail.Repo.Migrations.ConversationIndex do
  use Ecto.Migration

  def change do
    create index(:messages, [:conversation_id])
  end
end
