defmodule Phail.Repo.Migrations.MessageIsDraft do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :is_draft, :boolean, default: false
    end

    create index(:messages, [:id], where: "is_draft is true")
  end
end
