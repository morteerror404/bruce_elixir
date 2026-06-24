defmodule BruceElixir.CLI.Main do
  def main(_args) do
    ExRatatui.Native.ensure_loaded()

    {:ok, pid} = BruceElixir.CLI.start_link([])
    ref = Process.monitor(pid)
    receive do
      {:DOWN, ^ref, :process, ^pid, _reason} ->
        case :persistent_term.get({:bruce, :final_state}, :none) do
          :none -> :ok
          state ->
            selected = Map.get(state, :selected_features, [])
            board = Map.get(state, :board_selected)
            if board && selected != [] do
              BruceElixir.Builder.build(board, selected)
            end
        end
    end
  rescue
    e ->
      IO.puts("\e[31mErro ao carregar NIF do ExRatatui.\e[0m")
      IO.puts("")
      IO.puts("Motivo: #{Exception.message(e)}")
      IO.puts("")
      IO.puts("\e[33mUse:\e[0m")
      IO.puts("  mix bruce")
      System.stop(1)
  end
end
