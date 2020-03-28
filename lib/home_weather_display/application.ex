defmodule HomeWeatherDisplay.Application do
  @moduledoc false
  use Application
  require Logger

  # RGB LCD Screen should use the IC2-1 port
  @dht_pin 16 # Use port 7 for the DHT
  @dht_poll_interval 1_000 # poll every 1 second

  def start(_type, _args) do
    Logger.info "Starting..."

    import Supervisor.Spec, warn: false

    children = [
      # Start the GrovePi sensor we want
      worker(GrovePi.DHT, [@dht_pin, [poll_interval: @dht_poll_interval]]),

      # Start the main app
      worker(HomeWeatherDisplay, [@dht_pin]),
    ]

    Logger.info "Starting Children ..."
    opts = [strategy: :rest_for_one, name: HomeWeatherDisplay.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
