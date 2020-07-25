defmodule Phail.Repo.Migrations.CreateMessage do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :subject, :string
      add :body, :string
    end

    create table(:addresses) do
      add :address, :string, null: false
      add :name, :string
    end
  end
end
