defmodule BruceElixir.TTYHandler do
  @doc """
  Lê a entrada do TTY de forma segura.
  O timeout curto garante que o loop nunca fique parado esperando EOF.
  """
  def get_event do
    case IO.binread(:stdio, 3) do # As sequências de seta ANSI são de 3 bytes
      {:error, :timeout} -> :none
      :eof -> :quit
      data -> parse_input(data)
    end
  end

  # Pattern matching para as sequências ANSI de 3 bytes
  defp parse_input(<<0x1B, 0x5B, 0x41>>), do: :up
  defp parse_input(<<0x1B, 0x5B, 0x42>>), do: :down
  defp parse_input(<<0x1B, 0x5B, 0x43>>), do: :right
  defp parse_input(<<0x1B, 0x5B, 0x44>>), do: :left

  # Teclas simples
  defp parse_input(<<0x0D>>), do: :enter # \r
  defp parse_input(<<0x20>>), do: :space # ' '
  defp parse_input(<<0x71>>), do: :quit  # 'q'

  # Caso não case com nada (lixo ou tecla não tratada)
  defp parse_input(_), do: :none
end
