defmodule Phail.Repo.Migrations.AddLabels do
  use Ecto.Migration

  def change do
    create table(:labels) do
      add :name, :text
    end

    create table(:message_labels, primary_key: false) do
      add :message_id, references(:messages, on_delete: :delete_all)
      add :label_id, references(:labels)
    end

    create unique_index(:message_labels, [:message_id, :label_id])
    create index(:labels, [:name])
  end
end
