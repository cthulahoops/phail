defmodule Phail.Repo.Migrations.Timestamptz do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      modify :date, :timestamptz, from: :utc_datetime
    end
  end
end
