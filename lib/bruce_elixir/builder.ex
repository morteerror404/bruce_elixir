defmodule BruceElixir.Builder do
  @moduledoc """
  Orquestra a compilação de firmware.

  Delega para o backend apropriado (`BruceElixir.Hardware`) baseado na placa:
    - ESP32 → `BruceElixir.Hardware.PlatformIO` (pio run)
    - Nerves → `BruceElixir.Hardware.Nerves` (mix firmware)
    - Zephyr → `BruceElixir.Hardware.Zephyr` (west build)
  """

  @doc """
  Lista todas as placas disponíveis (PlatformIO + Nerves + Zephyr).
  """
  def list_boards do
    BruceElixir.Hardware.list_boards()
  end

  @doc """
  Compila o firmware para `board_id` com as `selected_features`.
  """
  def build(board_id, selected_features) do
    BruceElixir.Hardware.build(board_id, selected_features)
  end

  @doc false
  def write_config(board_id, selected_features) do
    case BruceElixir.Hardware.backend_for(board_id) do
      BruceElixir.Hardware.PlatformIO ->
        BruceElixir.Hardware.PlatformIO.write_config(board_id, selected_features)

      BruceElixir.Hardware.Nerves ->
        BruceElixir.Hardware.Nerves.write_nerves_config(board_id, selected_features)

      _ ->
        nil
    end
  end
end
