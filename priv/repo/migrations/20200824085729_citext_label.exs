defmodule Phail.Repo.Migrations.CitextLabel do
  use Ecto.Migration

  def change do
    execute "create extension if not exists citext;"

    alter table("labels") do
      modify :name, :citext
    end
  end
end
