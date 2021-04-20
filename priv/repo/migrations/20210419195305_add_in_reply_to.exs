defmodule Phail.Repo.Migrations.AddInReplyTo do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :in_reply_to, :string
    end
  end
end
