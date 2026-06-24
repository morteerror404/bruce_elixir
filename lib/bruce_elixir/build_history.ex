defmodule BruceElixir.BuildHistory do
  @moduledoc """
  Armazena o histórico de compilações em memória via Agent.

  Cada registro contém:
    - `id` — timestamp-based identifier
    - `board_id` — placa alvo
    - `board_name` — nome amigável da placa
    - `features` — lista de features selecionadas
    - `status` — `:done` | `:error`
    - `result` — exit code
    - `backend` — `:platformio` | `:nerves` | `:zephyr`
    - `firmware_path` — caminho do .bin gerado (quando disponível)
    - `inserted_at` — DateTime
  """

  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  @doc """
  Adiciona um registro ao histórico.
  """
  def add(attrs) do
    record = %{
      id: System.system_time(:microsecond),
      board_id: attrs.board_id,
      board_name: attrs.board_name,
      features: attrs.features,
      status: attrs.status,
      result: attrs.result,
      backend: attrs.backend,
      firmware_path: attrs[:firmware_path],
      inserted_at: DateTime.utc_now()
    }

    Agent.update(__MODULE__, fn records -> [record | records] end)
    record
  end

  @doc """
  Lista todo o histórico, do mais recente ao mais antigo.
  """
  def list do
    Agent.get(__MODULE__, fn records -> records end)
  end

  @doc """
  Retorna os últimos N registros.
  """
  def recent(n \\ 10) do
    list() |> Enum.take(n)
  end

  @doc """
  Limpa o histórico.
  """
  def clear do
    Agent.update(__MODULE__, fn _ -> [] end)
  end
end
