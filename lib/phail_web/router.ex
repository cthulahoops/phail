defmodule PhailWeb.Router do
  use PhailWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PhailWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PhailWeb do
    pipe_through :browser

    live "/", Live.Phail
    live "/search/:search_filter/", Live.Phail, :search
    live "/label/:label/", Live.Phail, :label

    live "/compose/", Live.Compose
    live "/compose/:message_id/", Live.Compose, :message_id
    live "/reply/:reply_to/", Live.Compose, :reply_to
    live "/reply/:reply_to/:message_id/", Live.Compose, :reply_to_draft
  end

  # Other scopes may use custom stacks.
  # scope "/api", PhailWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: PhailWeb.Telemetry
    end
  end

  if Mix.env() == :dev do
    forward "/sent_emails", Bamboo.SentEmailViewerPlug
  end
end
