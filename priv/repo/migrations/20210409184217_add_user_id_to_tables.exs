defmodule Phail.Repo.Migrations.AddUserIdToTables do
  use Ecto.Migration

  def change do
    alter table(:conversations) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
    end

    alter table(:messages) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
    end

    alter table(:message_addresses) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
    end
  end
end
