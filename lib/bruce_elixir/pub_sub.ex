defmodule BruceElixir.PubSub do
  @moduledoc """
  PubSub leve usando `:pg` (Process Groups — OTP 29+).

  Arquitetura agnóstica: funciona com ExRatatui, Phoenix LiveView,
  ou qualquer processo Elixir que queira escutar eventos de build.

  ## Uso

      # Inscrever
      BruceElixir.PubSub.subscribe("build:logs")
      BruceElixir.PubSub.subscribe("build:\#{board_id}")

      # Publicar (qualquer processo)
      BruceElixir.PubSub.broadcast("build:logs", {:build_log, "compiling..."})
      BruceElixir.PubSub.broadcast("build:\#{board_id}", {:build_done, 0})

      # Receber
      receive do
        {:"$pg", "build:logs", {:build_log, line}} -> IO.write(line)
        {:"$pg", "build:\#{board_id}", {:build_done, code}} -> IO.puts("exit: \#{code}")
      end
  """

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor,
      restart: :permanent,
      shutdown: 500
    }
  end

  @doc false
  def start_link(_opts) do
    :pg.start_link()
  end

  @doc """
  Inscreve o processo atual em um tópico.
  """
  @spec subscribe(topic :: term()) :: :ok
  def subscribe(topic) do
    :pg.join(topic, self())
  end

  @doc """
  Remove inscrição do processo atual em um tópico.
  """
  @spec unsubscribe(topic :: term()) :: :ok
  def unsubscribe(topic) do
    :pg.leave(topic, self())
  end

  @doc """
  Publica uma mensagem para todos os inscritos em um tópico.
  A mensagem é entregue como `{:"$pg", topic, message}`.
  """
  @spec broadcast(topic :: term(), message :: term()) :: :ok
  def broadcast(topic, message) do
    :pg.get_members(topic)
    |> Enum.each(&send(&1, {:"$pg", topic, message}))
  end
end
