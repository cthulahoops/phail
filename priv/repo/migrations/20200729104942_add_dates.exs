defmodule Phail.Repo.Migrations.AddDates do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :date, :utc_datetime
    end
  end
end
