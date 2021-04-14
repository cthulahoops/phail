defmodule Phail.Repo.Migrations.OriginalText do
  use Ecto.Migration

  def change do
    create table(:originals) do
      add :user_id, references(:users), null: false
      add :message_id, references(:messages), null: false
      add :text, :binary
    end
  end
end
