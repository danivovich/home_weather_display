defmodule HomeWeatherDisplay do
  @moduledoc false
  use GenServer
  require Logger

  defstruct [:dht]

  alias GrovePi.{RGBLCD, DHT}

  def start_link(pin) do
    GenServer.start_link(__MODULE__, pin)
  end

  def init(dht_pin) do
    Logger.info "Init!"
    state = %HomeWeatherDisplay{dht: dht_pin}

    flash_rgb(0.0)
    RGBLCD.set_text("Ready!")
    Logger.info "Ready!"

    DHT.subscribe(dht_pin, :changed)
    Logger.info "Subscribed to updates!"
    {:ok, state}
  end

  def handle_info({_pin, :changed, %{temp: tempc, humidity: humidity}}, state) do
    Logger.info "Updating.."
    temp = far(tempc)
    text = format_text(temp, humidity)

    flash_rgb(temp)

    # Update LCD with new data
    RGBLCD.set_text(text)
    Logger.info text
    {:noreply, state}
  end

  def handle_info(_message, state) do
    {:noreply, state}
  end

  defp flash_rgb(temp) do
    {red, green, blue} = case temp do
      z when z == 0 ->
        {0, 128, 64}
      h when h >= 70 ->
        r = scale_hot_value(temp)
        {r, 0, 255 - r}
      c when c < 70 ->
        b = scale_cold_value(temp)
        {255 - b, 0, b}
    end
    Logger.info "R: #{Integer.to_string(red)} G: #{Integer.to_string(green)} B: #{Integer.to_string(blue)}"
    RGBLCD.set_rgb(0, 255, 0)
    RGBLCD.set_rgb(red, green, blue)
  end

  defp scale_hot_value(temp) when temp >= 80 do
    255
  end
  defp scale_hot_value(temp) do
    over = 80.0 - temp
    v = (10.0 - over) * 255.0 / 10.0
    trunc(v)
  end

  defp scale_cold_value(temp) when temp <= 60 do
    255
  end
  defp scale_cold_value(temp) do
    over = temp - 60.0
    v = (10.0 - over) * 255.0 / 10.0
    trunc(v)
  end

  defp far(temp) do
    Float.round(temp*(9.0/5.0)+32.0, 1)
  end

  defp format_text(temp, humidity) do
    "T: #{Float.to_string(temp)}F H: #{Float.to_string(humidity)}%"
  end
end
