defmodule BruceElixir.Hardware do
  @moduledoc """
  Abstração de backend de build: PlatformIO, Nerves e Zephyr.

  Cada backend implementa o comportamento `BruceElixir.Hardware.Backend`
  e é registrado via `backends/0`. O dispatcher seleciona o backend
  correto baseado no `board_id`.
  """

  alias BruceElixir.Hardware.PlatformIO
  alias BruceElixir.Hardware.Nerves
  alias BruceElixir.Hardware.Zephyr

  @doc """
  Lista todos os backends disponíveis, em ordem de precedência.
  """
  def backends do
    [Nerves, PlatformIO, Zephyr]
  end

  @doc """
  Lista todas as placas suportadas por todos os backends.
  """
  def list_boards do
    backends()
    |> Enum.flat_map(& &1.list_boards/0)
    |> Enum.sort_by(& &1.name)
  end

  @doc """
  Retorna as placas agrupadas por backend, com labels para cada categoria.
  """
  def list_boards_grouped do
    backends()
    |> Enum.map(fn backend ->
      key = backend_key(backend)
      %{label: backend_label(key), key: key, icon: backend_icon(key)}
    end)
    |> Enum.map(fn group ->
      boards =
        backends()
        |> Enum.filter(&backend_key(&1) == group.key)
        |> Enum.flat_map(fn b -> b.list_boards() end)
        |> Enum.sort_by(& &1.name)

      Map.put(group, :boards, boards)
    end)
    |> Enum.reject(fn g -> g.boards == [] end)
  end

  @doc """
  Retorna uma árvore de placas: Backend → Fabricante → Modelo → Versões.

  Cada board é parseada para extrair fabricante (vendor), modelo e versão.
  O seletor em árvore permite navegar fabricante > modelo > versão.
  """
  def list_boards_tree do
    list_boards_grouped()
    |> Enum.map(fn group ->
      boards = add_parsed_fields(group.boards)
      manufacturers = group_by_manufacturer(boards)
      Map.put(group, :manufacturers, manufacturers) |> Map.drop([:boards])
    end)
  end

  defp backend_label(:platformio), do: "ESP32 (PlatformIO)"
  defp backend_label(:nerves), do: "Linux (Nerves)"
  defp backend_label(:zephyr), do: "Zephyr RTOS"

  defp backend_icon(:platformio), do: "🔌"
  defp backend_icon(:nerves), do: "🐧"
  defp backend_icon(:zephyr), do: "⚡"

  defp add_parsed_fields(boards) do
    boards
    |> Enum.map(&parse_board/1)
    |> Enum.sort_by(&"#{&1.vendor}_#{&1.model}_#{&1.variant || ""}")
  end

  defp parse_board(board) do
    name = board.name
    vendor = normalize_vendor(board.vendor || vendor_from_name(name) || vendor_from_id(board.id))

    model =
      if starts_with_ignore_case?(name, vendor) do
        name
        |> String.slice(String.length(vendor)..-1//1)
        |> strip_leading_chars([?-])
        |> String.trim()
      else
        name
      end

    {model, variant} =
      case Regex.run(~r/\s*\(([^)]+)\)\s*$/, model) do
        [_, inner] ->
          {String.trim(Regex.replace(~r/\s*\([^)]+\)\s*$/, model, "")), inner}
        nil ->
          {model, nil}
      end

    model = if model == "", do: board.name, else: String.trim(model)
    Map.merge(board, %{vendor: vendor, model: model, variant: variant})
  end

  @known_vendors ~w(M5Stack LilyGo LILYGO Espressif ELECROW Arduino Smoochiee SMOOCHIEE Zephyr Raspberry)

  defp vendor_from_name(name) do
    first = name |> String.split(" ") |> List.first()
    first && Enum.find(@known_vendors, fn v ->
      String.downcase(v) == String.downcase(first)
    end)
  end

  defp vendor_from_id(id) do
    case String.split(id, "-") do
      [first | _] ->
        uc = String.upcase(first)
        Enum.find(@known_vendors, &(String.upcase(&1) == uc)) || String.capitalize(first)
      _ ->
        "Unknown"
    end
  end

  defp group_by_manufacturer(boards) do
    boards
    |> Enum.map(fn b -> Map.put(b, :vendor, normalize_vendor(b.vendor)) end)
    |> Enum.group_by(& &1.vendor)
    |> Enum.map(fn {vendor, bs} ->
      %{
        name: vendor,
        boards: bs |> Enum.sort_by(&"#{&1.model}_#{&1.variant || ""}")
      }
    end)
    |> Enum.sort_by(& &1.name)
  end

  defp normalize_vendor("LILYGO"), do: "LilyGo"
  defp normalize_vendor("SMOOCHIEE"), do: "Smoochiee"
  defp normalize_vendor(v), do: v

  defp starts_with_ignore_case?(str, prefix) do
    String.length(str) >= String.length(prefix) &&
      String.downcase(String.slice(str, 0, String.length(prefix))) == String.downcase(prefix)
  end

  defp strip_leading_chars(str, chars) do
    str |> String.trim_leading() |> then(fn s ->
      Enum.reduce_while(chars, s, fn c, acc ->
        if String.starts_with?(acc, <<c>>),
          do: {:cont, String.trim_leading(acc, <<c>>)},
          else: {:halt, acc}
      end)
    end)
  end

  defp backend_key(BruceElixir.Hardware.PlatformIO), do: :platformio
  defp backend_key(BruceElixir.Hardware.Nerves), do: :nerves
  defp backend_key(BruceElixir.Hardware.Zephyr), do: :zephyr

  @doc """
  Retorna o módulo do backend responsável por uma `board_id`.
  O último backend registrado tem precedência (último a responder `true`).
  """
  def backend_for(board_id) do
    backends()
    |> Enum.find(& &1.supports?(board_id))
  end

  @doc """
  Compila o firmware para `board_id` com as `selected_features`.
  Delega para o backend apropriado.
  """
  def build(board_id, selected_features) do
    case backend_for(board_id) do
      nil ->
        publish(board_id, {:build_log, "No backend found for board: #{board_id}\n"})
        publish(board_id, {:build_done, 1})
        {:error, :no_backend}

      backend ->
        backend.build(board_id, selected_features)
    end
  end

  @doc """
  Retorna as features compatíveis com uma placa, considerando o backend.
  """
  def compatible_features(board_id) do
    case backend_for(board_id) do
      BruceElixir.Hardware.PlatformIO ->
        BruceElixir.Features.compatible_for(board_id)

      _ ->
        MapSet.new()
    end
  end

  defp publish(board_id, msg) do
    BruceElixir.PubSub.broadcast("build:#{board_id}", msg)
  rescue
    _ -> :ok
  end
end
