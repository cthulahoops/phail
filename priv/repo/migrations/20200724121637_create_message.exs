defmodule Phail.Repo.Migrations.CreateMessage do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :subject, :text
      add :body, :text
    end

    create table(:addresses) do
      add :address, :text, null: false
      add :name, :text
    end
  end
end
