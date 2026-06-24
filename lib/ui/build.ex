defmodule BruceElixir.UI.Build do
  def render(model) do
    # Limpa a tela e reseta o cursor
    IO.write([IO.ANSI.clear(), IO.ANSI.home()])

    # Cabeçalho estilizado
    IO.write([
      IO.ANSI.cyan(), IO.ANSI.bright(),
      "=== Bruce Firmware Installer ===\n",
      IO.ANSI.reset(),
      "Seta [Cima/Baixo] para navegar, [Espaço] para alternar, [Enter] para Confirmar.\n\n"
    ])

    model.features
    |> Enum.with_index()
    |> Enum.each(fn {{name, category, status}, index} ->
      is_selected = index == model.selected

      # Lógica de seleção e status
      cursor = if is_selected, do: "> ", else: "  "
      checked = if status, do: "[x]", else: "[ ]"
      {color, _} = if status, do: {IO.ANSI.green(), nil}, else: {IO.ANSI.default_color(), nil}

      # Formatação da linha
      tag = " #{IO.ANSI.faint()}[#{String.upcase(Atom.to_string(category))}]#{IO.ANSI.reset()}"
      line = "#{cursor} #{checked} #{name}#{tag}"

      # Impressão com destaque de seleção
      if is_selected do
        IO.puts([IO.ANSI.reverse(), color, line, IO.ANSI.reset()])
      else
        IO.puts([color, line, IO.ANSI.reset()])
      end
    end)
  end
end
