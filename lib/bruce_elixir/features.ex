defmodule BruceElixir.Features do
  @moduledoc """
  Mapeamento centralizado feature → build flags.

  Cada feature (lib em `src_bruce/lib/`) pode habilitar múltiplas flags
  de compilação, dependências extras ou configurações de linker.
  """

  @type feature_id :: String.t()
  @type flag :: String.t()

  @doc """
  Retorna as build flags para uma lista de feature IDs ou feature única.
  """
  def build_flags(feature_ids) when is_list(feature_ids) do
    feature_ids
    |> Enum.flat_map(&build_flags/1)
    |> Enum.uniq()
  end

  def build_flags(feature_id) do
    case feature_id do
      "Bad_Usb_Lib" ->
        [
          "-DUSB_as_HID=1",
          "-DBAD_TX=GROVE_SDA",
          "-DBAD_RX=GROVE_SCL"
        ]

      "CYD-touch" ->
        [
          "-DHAS_TOUCH=1",
          "-DTOUCH_CS=33"
        ]

      "RTC" ->
        [
          "-DHAS_RTC=1"
        ]

      "PN532_SRIX" ->
        [
          "-DPN532_SRIX=1"
        ]

      "TFT_eSPI" ->
        [
          "-DUSER_SETUP_LOADED=1",
          "-DSMOOTH_FONT=1"
        ]

      "TFT_eSPI_QRcode" ->
        [
          "-DENABLE_QRCODE=1"
        ]

      "HAL" ->
        [
          "-DHAL_DISPLAY=1",
          "-DHAL_SD_CARD=1"
        ]

      "utility" ->
        [
          "-DUTILITY_LIBS=1"
        ]

      _ ->
        []
    end
  end

  @doc """
  Lista todas as features conhecidas com seus IDs e nomes para exibição.
  """
  def all do
    [
      %{id: "Bad_Usb_Lib", name: "Bad USB Library", category: :library, description: "Teclado HID USB/BLE, CH9329"},
      %{id: "CYD-touch", name: "CYD Touchscreen", category: :driver, description: "Drivers touch CYD28 (resistivo/capacitivo)"},
      %{id: "HAL", name: "Hardware Abstraction Layer", category: :library, description: "Display, IO expander, SD card abstraction"},
      %{id: "PN532_SRIX", name: "PN532 NFC/RFID", category: :driver, description: "Leitura/gravação RFID 125kHz via PN532"},
      %{id: "RTC", name: "Real-Time Clock", category: :driver, description: "Drivers RTC (cplus_RTC, pcf85063)"},
      %{id: "TFT_eSPI", name: "TFT Graphics Library", category: :display, description: "TFT_eSPI v2.5.43 com suporte a múltiplos drivers"},
      %{id: "TFT_eSPI_QRcode", name: "QR Code Generator", category: :display, description: "Geração de QR codes para telas TFT"},
      %{id: "utility", name: "Utility Helpers", category: :util, description: "Gerenciamento de energia AXP192, bq27220, teclado"}
    ]
  end

  @doc """
  Mapa de features para serem usadas em testes de build sem depender do filesystem.
  Usado em vez de `Mix.Tasks.Mapper.run/0` quando não há Mix disponível.
  """
  def builtin do
    all()
    |> Enum.map(&{&1.id, &1.category, false})
  end

  @doc """
  Retorna um `MapSet` com as features compatíveis para uma dada placa.
  Usa heurísticas baseadas no ID da placa para pré-selecionar features relevantes.
  """
  def compatible_for(board_id) do
    board_id
    |> board_patterns()
    |> Enum.flat_map(&feature_rules/1)
    |> MapSet.new()
  end

  defp board_patterns(board_id) do
    patterns = [board_id]

    patterns
    |> maybe_add_pattern(board_id, &String.starts_with?(&1, "CYD-"), :cyd)
    |> maybe_add_pattern(board_id, &String.starts_with?(&1, "lilygo-t-"), :lilygo_t)
    |> maybe_add_pattern(board_id, &String.starts_with?(&1, "m5stack-"), :m5stack)
    |> maybe_add_pattern(board_id, &String.starts_with?(&1, "elecrow-"), :elecrow)
    |> maybe_add_pattern(board_id, &String.contains?(&1, "watch"), :watch)
    |> maybe_add_pattern(board_id, &String.contains?(&1, "cardputer"), :cardputer)
  end

  defp maybe_add_pattern(acc, board_id, condition, tag) do
    if condition.(board_id), do: [tag | acc], else: acc
  end

  defp feature_rules(:cyd), do: ["CYD-touch", "TFT_eSPI", "TFT_eSPI_QRcode"]
  defp feature_rules(:lilygo_t), do: ["TFT_eSPI", "TFT_eSPI_QRcode"]
  defp feature_rules(:m5stack), do: ["TFT_eSPI", "TFT_eSPI_QRcode", "RTC"]
  defp feature_rules(:elecrow), do: ["TFT_eSPI", "TFT_eSPI_QRcode"]
  defp feature_rules(:watch), do: ["TFT_eSPI", "TFT_eSPI_QRcode", "RTC"]
  defp feature_rules(:cardputer), do: ["TFT_eSPI", "TFT_eSPI_QRcode", "utility"]
  defp feature_rules(_), do: []
end
