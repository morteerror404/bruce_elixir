defmodule BruceElixir.Hardware.Zephyr do
  @moduledoc """
  Backend de build para placas Zephyr RTOS via `west build`.

  Detecta placas Zephyr executando `west boards` e filtra
  pelo prefixo `zephyr-`. O build executa:
      west build -b <board_id> <src_dir>
  """

  @behaviour BruceElixir.Hardware.Backend

  @zephyr_prefix "zephyr-"

  @impl true
  def list_boards do
    case detect_zephyr_boards() do
      {:ok, boards} -> boards
      _ -> []
    end
  end

  @impl true
  def supports?(board_id), do: String.starts_with?(board_id, @zephyr_prefix)

  @impl true
  def build(board_id, _selected_features) do
    publish(board_id, {:build_log, "\e[33m▶ Compilando #{board_id} com Zephyr...\e[0m\n"})

    if west_installed?() do
      board = String.trim_leading(board_id, @zephyr_prefix)
      src_dir = zephyr_src_dir()

      publish(board_id, {:build_log, "  Board: #{board}\n"})
      publish(board_id, {:build_log, "  Source: #{src_dir}\n"})

      port =
        Port.open(
          {:spawn, "west build -b #{board} #{src_dir}"},
          [:binary, :exit_status, cd: to_charlist(File.cwd!())]
        )

      result = stream_build(port, board_id)

      case result do
        :ok ->
          publish(board_id, {:build_log, "\e[32m✔ Build Zephyr concluído\e[0m\n"})
          publish(board_id, {:build_done, 0})
          :ok

        {:error, code} ->
          publish(board_id, {:build_log, "\e[31m✖ Build Zephyr falhou (exit #{code})\e[0m\n"})
          publish(board_id, {:build_done, code})
          {:error, code}
      end
    else
      publish(board_id, {:build_log, "\e[31m✖ west CLI não encontrado. Instale Zephyr RTOS.\e[0m\n"})
      publish(board_id, {:build_done, 1})
      {:error, :west_not_found}
    end
  end

  defp stream_build(port, board_id) do
    receive do
      {^port, {:data, data}} ->
        data
        |> String.split("\n")
        |> Enum.each(fn
          "" -> :ok
          line -> publish(board_id, {:build_log, "  \e[90m│\e[0m #{line}\n"})
        end)

        stream_build(port, board_id)

      {^port, {:exit_status, 0}} ->
        :ok

      {^port, {:exit_status, code}} ->
        {:error, code}
    end
  end

  defp detect_zephyr_boards do
    case System.cmd("west", ["boards"], stderr: :close) do
      {output, 0} ->
        boards =
          output
          |> String.split("\n", trim: true)
          |> Enum.map(fn name ->
            %{id: "#{@zephyr_prefix}#{name}", name: "Zephyr: #{name}", mcu: "Zephyr", vendor: "Zephyr"}
          end)

        {:ok, boards}

      {_, _} ->
        :error
    end
  rescue
    _ -> :error
  end

  defp west_installed? do
    System.find_executable("west") != nil
  end

  defp zephyr_src_dir do
    case File.cwd!() do
      cwd -> Path.join(cwd, "src_zephyr")
    end
  end

  defp publish(board_id, msg) do
    BruceElixir.PubSub.broadcast("build:#{board_id}", msg)
  rescue
    _ -> :ok
  end
end
