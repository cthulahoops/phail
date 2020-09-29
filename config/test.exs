use Mix.Config

import_config "test.secret.exs"
# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
#
# We don't run a server during test. If one is required,
# you can enable the server option below.
config :phail, PhailWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :phail, domain: "phail_test_message"
config :phail, email_sender: {"Phail Test Account", "phail-test-sender@example.com"}

config :phail, Phail.Mailer,
  adapter: Bamboo.TestAdapter
