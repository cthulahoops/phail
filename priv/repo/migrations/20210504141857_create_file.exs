defmodule Phail.Repo.Migrations.CreateFile do
  use Ecto.Migration

  def change do
    create table(:files) do
      add :data, :binary
      add :content_type, :string
      add :filename, :string
      add :disposition, :string
      add :user_id, references(:users, on_delete: :nothing), null: false
      add :message_id, references(:messages, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:files, [:user_id])
    create index(:files, [:message_id])
  end
end
