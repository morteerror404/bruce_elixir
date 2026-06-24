defmodule BruceElixir.Hardware.Backend do
  @moduledoc """
  Comportamento que todos os backends de build devem implementar.

  Callbacks:
    - `list_boards/0` — retorna lista de `%{id:, name:, mcu:}`
    - `supports?/1` — se o backend aceita uma `board_id`
    - `build/2` — executa o build e publica via PubSub
  """

  @callback list_boards() :: [%{id: String.t(), name: String.t(), mcu: String.t()}]

  @callback supports?(board_id :: String.t()) :: boolean()

  @callback build(board_id :: String.t(), selected_features :: [String.t()]) ::
              :ok | {:error, term()}
end
