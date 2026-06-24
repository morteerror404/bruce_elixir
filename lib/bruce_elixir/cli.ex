defmodule BruceElixir.CLI do
  use ExRatatui.App

  @impl true
  def mount(_opts) do
    features = Mix.Tasks.Mapper.run([])
    boards = BruceElixir.Builder.list_boards()

    items =
      Enum.map(features, fn {name, category, checked} ->
        %{name: name, category: category, checked: checked || false}
      end)

    {:ok, %{
      cursor: 0,
      items: items,
      boards: boards,
      board_cursor: 0,
      board_selected: nil,
      mode: :features
    }}
  end

  @impl true
  def render(state, frame) do
    alias ExRatatui.Layout
    alias ExRatatui.Layout.Rect
    alias ExRatatui.Style
    alias ExRatatui.Widgets.{Block, Checkbox, Paragraph}

    area = %Rect{x: 0, y: 0, width: frame.width, height: frame.height}

    [header_area, main_area, footer_area] =
      Layout.split(area, :vertical, [{:length, 3}, {:min, 0}, {:length, 1}])

    header = %Paragraph{
      text: "=== Bruce Firmware Installer ===",
      block: %Block{
        borders: [:bottom],
        border_style: %Style{fg: :dark_gray}
      }
    }

    [left_area, right_area] =
      Layout.split(main_area, :horizontal, [{:percentage, 60}, {:percentage, 40}])

    _features_header = %Paragraph{
      text: " Features (Espaço para alternar):",
      style: %Style{fg: :cyan}
    }

    [_feat_header_area | feat_items_areas] =
      Layout.split(left_area, :vertical, [{:length, 1} | Enum.map(state.items, fn _ -> {:length, 1} end)] ++ [{:min, 0}])

    checkboxes =
      state.items
      |> Enum.with_index()
      |> Enum.map(fn {item, idx} ->
        selected? = idx == state.cursor and state.mode == :features

        label_style =
          if selected?, do: %Style{fg: :yellow, modifiers: [:bold]}, else: %Style{fg: :white}

        symbol_style =
          if item.checked,
            do: %Style{fg: :green, modifiers: [:bold]},
            else: %Style{fg: :dark_gray}

        prefix = if selected?, do: ">", else: " "

        checkbox = %Checkbox{
          label: "#{prefix} #{item.name} [#{item.category}]",
          checked: item.checked,
          style: label_style,
          checked_style: symbol_style,
          checked_symbol: "[x]",
          unchecked_symbol: "[ ]"
        }

        {checkbox, Enum.at(feat_items_areas, idx)}
      end)

    boards_header = %Paragraph{
      text: " Placa alvo (Enter para selecionar):",
      style: %Style{fg: :cyan}
    }

    [board_header_area | board_items_areas] =
      Layout.split(right_area, :vertical, [{:length, 1} | Enum.map(state.boards, fn _ -> {:length, 1} end)] ++ [{:min, 0}])

    board_items =
      state.boards
      |> Enum.with_index()
      |> Enum.map(fn {board, idx} ->
        selected? = idx == state.board_cursor
        is_chosen = state.board_selected == board.id

        label_style =
          cond do
            is_chosen -> %Style{fg: :green, modifiers: [:bold]}
            selected? -> %Style{fg: :yellow, modifiers: [:bold]}
            true -> %Style{fg: :white}
          end

        prefix =
          cond do
            is_chosen -> "*"
            selected? && state.mode == :boards -> ">"
            true -> " "
          end

        %Paragraph{
          text: "#{prefix} #{board.name} [#{board.mcu}]",
          style: label_style
        }
      end)

    board_pane = [
      {boards_header, board_header_area}
      | Enum.zip(board_items, board_items_areas)
    ]

    help = %Paragraph{
      text: " Tab = alternar painéis  |  q = sair  |  Enter = compilar firmware",
      style: %Style{fg: :dark_gray}
    }

    [{header, header_area}] ++ checkboxes ++ board_pane ++ [{help, footer_area}]
  end

  @impl true
  def handle_event(%ExRatatui.Event.Key{code: "q", kind: "press"}, state), do: {:stop, state}

  def handle_event(%ExRatatui.Event.Key{code: code, kind: "press"}, state)
      when code in ["down", "j"] do
    case state.mode do
      :features ->
        {:noreply, %{state | cursor: min(length(state.items) - 1, state.cursor + 1)}}
      :boards ->
        {:noreply, %{state | board_cursor: min(length(state.boards) - 1, state.board_cursor + 1)}}
    end
  end

  def handle_event(%ExRatatui.Event.Key{code: code, kind: "press"}, state)
      when code in ["up", "k"] do
    case state.mode do
      :features ->
        {:noreply, %{state | cursor: max(0, state.cursor - 1)}}
      :boards ->
        {:noreply, %{state | board_cursor: max(0, state.board_cursor - 1)}}
    end
  end

  def handle_event(%ExRatatui.Event.Key{code: "tab", kind: "press"}, state) do
    mode = if state.mode == :features, do: :boards, else: :features
    {:noreply, %{state | mode: mode}}
  end

  def handle_event(%ExRatatui.Event.Key{code: " ", kind: "press"}, state) do
    case state.mode do
      :features ->
        items =
          List.update_at(state.items, state.cursor, fn item ->
            %{item | checked: not item.checked}
          end)
        {:noreply, %{state | items: items}}
      :boards ->
        {:noreply, state}
    end
  end

  def handle_event(%ExRatatui.Event.Key{code: "enter", kind: "press"}, state) do
    case state.mode do
      :boards ->
        board = Enum.at(state.boards, state.board_cursor)
        {:noreply, %{state | board_selected: board.id}}
      :features ->
        names = Enum.map(Enum.filter(state.items, & &1.checked), & &1.name)

        cond do
          is_nil(state.board_selected) ->
            {:noreply, state}
          names == [] ->
            {:noreply, state}
          true ->
            final = Map.put(state, :selected_features, names)
            :persistent_term.put({:bruce, :final_state}, final)
            {:stop, state}
        end
    end
  end

  def handle_event(_event, state), do: {:noreply, state}
end
