defmodule BruceElixirWeb.FirmwareController do
  use BruceElixirWeb, :controller

  def download(conn, %{"board_id" => board_id}) do
    backend = BruceElixir.Hardware.backend_for(board_id)
    path = firmware_path(backend, board_id)

    if path && File.exists?(path) do
      filename = "#{board_id}-firmware.bin"
      send_download(conn, {:file, path}, filename: filename)
    else
      conn
      |> put_status(:not_found)
      |> json(%{error: "Firmware not found for #{board_id}. Build it first."})
    end
  end

  defp firmware_path(BruceElixir.Hardware.PlatformIO, board_id) do
    "src_bruce/.pio/build/#{board_id}/firmware.bin"
  end

  defp firmware_path(BruceElixir.Hardware.Nerves, board_id) do
    Path.join(["_build", board_id, "dev", "nerves", "images", "bruce_elixir.fw"])
  end

  defp firmware_path(_, _), do: nil
end
