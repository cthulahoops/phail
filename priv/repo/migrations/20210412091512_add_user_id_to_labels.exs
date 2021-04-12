defmodule Phail.Repo.Migrations.AddUserIdToLabels do
  use Ecto.Migration

  def change do
    alter table(:labels) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
    end
  end
end
