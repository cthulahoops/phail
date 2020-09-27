defmodule Phail.Repo.Migrations.MessageStatus do
  use Ecto.Migration
  alias Phail.Message.MessageStatus

  def change do
    MessageStatus.create_type

    alter table(:messages) do
      add :status, MessageStatus.type()
    end

    create index(:messages, :status)

    execute(
       "update messages set status = 'draft' where is_draft",
       "update messages set is_draft = 't' where status = 'draft'"
     )

    drop index(:messages, [:id], where: "is_draft is true")

    alter table(:messages) do
       remove :is_draft, :boolean, default: false
    end
  end
end
