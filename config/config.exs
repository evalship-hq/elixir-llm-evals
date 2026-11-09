import Config

# The worker's stdout carries the replies, so logs go to stderr.
config :logger, :default_handler, config: [type: :standard_error]
