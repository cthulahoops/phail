defmodule Phail.Repo.Migrations.MessageId do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      modify :message_id, :text, null: false
    end
  end
end
