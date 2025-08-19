# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
use Mix.Config

database_url = System.get_env("DATABASE_URL") || "ecto://USER:PASS@HOST/DATABASE"

config :functional_vote, FunctionalVote.Repo,
  # ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  socket_options: [:inet6]

secret_key_base = System.get_env("SECRET_KEY_BASE") || "mix phx.gen.secret"

config :functional_vote, FunctionalVoteWeb.Endpoint,
  http: [
    port: String.to_integer(System.get_env("PORT") || "4000"),
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: secret_key_base

# prod uses reCAPTCHA environment variables
recaptcha_public_key =
	System.get_env("RECAPTCHA_PUBLIC_KEY") || "RECAPTCHA_PUBLIC_KEY"

recaptcha_secret =
	System.get_env("RECAPTCHA_PRIVATE_KEY") || "RECAPTCHA_PRIVATE_KEY"

config :recaptcha,
    public_key: recaptcha_public_key,
    secret: recaptcha_secret,
    json_library: Jason

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :functional_vote, FunctionalVoteWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
