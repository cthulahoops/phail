defmodule Phail.Repo.Migrations.LabelNamesUnique do
  use Ecto.Migration

  def change do
    drop index(:labels, [:name])
    create unique_index(:labels, [:name])
  end
end
