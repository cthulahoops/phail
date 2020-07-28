defmodule Phail.Repo.Migrations.AddFtIndex do
  use Ecto.Migration

  def change do
    # Create a tsvector GIN index on PostgreSQL
    create index("messages", ["(to_tsvector('english', body || ' ' || subject))"],
             name: :messages_ft_vector,
             using: "GIN"
           )
  end
end
