defmodule Phail.Repo.Migrations.ConversationLabels do
  use Ecto.Migration

  def change do
    execute "create extension if not exists citext;"

    create table(:labels) do
      add :name, :citext
    end

    create table(:conversation_labels, primary_key: false) do
      add :conversation_id, references(:conversations, on_delete: :delete_all)
      add :label_id, references(:labels)
    end

    create index(:conversation_labels, [:label_id])
    create unique_index(:conversation_labels, [:conversation_id, :label_id])
    create unique_index(:labels, [:name])
  end
end
