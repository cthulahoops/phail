defmodule Phail.Repo do
  use Ecto.Repo,
    otp_app: :phail,
    adapter: Ecto.Adapters.Postgres
end
