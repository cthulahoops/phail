defmodule Phail.Repo.Migrations.AddConversations do
  use Ecto.Migration

  def change do
    create table(:conversations) do
      add :subject, :text
    end

    alter table(:messages) do
      add :message_id, :text
      add :conversation_id, references(:conversations)
    end

    create table(:message_references, primary_key: false) do
      add :message_id, references(:messages, on_delete: :delete_all)
      add :reference, :text
    end

    create unique_index(:message_references, [:message_id, :reference])
    create index(:message_references, [:reference])
    create index(:message_references, [:message_id])
  end
end
