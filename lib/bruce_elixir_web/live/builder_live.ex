defmodule BruceElixirWeb.BuilderLive do
  use BruceElixirWeb, :live_view

  alias BruceElixir.Features

  def mount(_params, _session, socket) do
    board_groups = BruceElixir.Hardware.list_boards_grouped()
    board_tree = BruceElixir.Hardware.list_boards_tree()
    features = Features.all()
    builds = BruceElixir.BuildHistory.recent()

    socket =
      socket
      |> assign(
        page: :build,
        board_groups: board_groups,
        board_tree: board_tree,
        tree_expanded: MapSet.new(),
        features: features,
        builds: builds,
        selected_board: nil,
        selected_board_info: nil,
        selected_features: MapSet.new(),
        build_status: :idle,
        build_result: nil,
        build_log_empty: true,
        flash_status: :idle,
        last_build_record: nil
      )
      |> stream(:build_log, [])

    {:ok, socket, temporary_assigns: [builds: []]}
  end

  def render(assigns) do
    ~H"""
    <nav style="display:flex;align-items:center;gap:.25rem;background:var(--bg2);border-bottom:1px solid var(--border);padding:0 2rem;position:sticky;top:0;z-index:10">
      <span style="font-size:1.25rem;margin-right:.5rem">🦈</span>
      <span style="font-weight:700;font-size:.875rem;background:var(--grad);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;margin-right:1.5rem">
        Bruce Firmware Builder
      </span>

      <button phx-click="goto_page" phx-value-page="build" style={nav_tab_style(@page == :build)}>
        🔨 Build
      </button>
      <button phx-click="goto_page" phx-value-page="history" style={nav_tab_style(@page == :history)}>
        📋 History
      </button>
      <button phx-click="goto_page" phx-value-page="help" style={nav_tab_style(@page == :help)}>
        ❓ Help
      </button>

      <div style="margin-left:auto;display:flex;align-items:center;gap:.75rem">
        <span style="font-size:.6875rem;font-family:var(--mono);color:var(--text3)">v0.1.0</span>
        <button onclick="toggleTheme()" style={nav_icon_btn()}>
          <span id="theme-icon">☀️</span>
        </button>
      </div>
    </nav>

    <div class="build-grid" style="display:grid;grid-template-columns:320px 1fr;gap:2rem;max-width:1400px;margin:0 auto;padding:2rem">

      <%= if @page == :build do %>
        <aside class="build-sidebar" style="display:flex;flex-direction:column;gap:1rem">
          <div style="display:flex;gap:.5rem;font-size:.6875rem;font-family:var(--mono);color:var(--text3)">
            <span style={step_style(@selected_board != nil, 1)}>① Select Board</span>
            <span style="color:var(--border)">→</span>
            <span style={step_style(@selected_board != nil, 2)}>② Features</span>
            <span style="color:var(--border)">→</span>
            <span style={step_style(@build_status in [:done, :error], 3)}>③ Build</span>
          </div>

          <div style="background:var(--card);border:1px solid var(--border);border-radius:var(--radius);padding:1.25rem">
            <h2 style="font-size:.75rem;font-weight:600;text-transform:uppercase;letter-spacing:.05em;color:var(--text2);margin-bottom:.75rem;display:flex;align-items:center;justify-content:space-between">
              Board
              <span :if={@selected_board_info} style={backend_badge_style(@selected_board_info.backend)}>
                {backend_label(@selected_board_info.backend)}
              </span>
            </h2>

            <.board_tree tree={@board_tree} expanded={@tree_expanded} selected={@selected_board} />

            <div :if={@selected_board_info} style="margin-top:.75rem;display:flex;flex-direction:column;gap:.35rem;font-size:.75rem;font-family:var(--mono);color:var(--text3)">
              <div style="display:flex;justify-content:space-between">
                <span>MCU</span>
                <span style="color:var(--text)">{@selected_board_info.mcu}</span>
              </div>
              <div style="display:flex;justify-content:space-between">
                <span>Backend</span>
                <span style="color:var(--text)">{backend_full_label(@selected_board_info.backend)}</span>
              </div>
            </div>
          </div>

          <div :if={@selected_board} style="background:var(--card);border:1px solid var(--border);border-radius:var(--radius);padding:1.25rem">
            <h2 style="font-size:.75rem;font-weight:600;text-transform:uppercase;letter-spacing:.05em;color:var(--text2);margin-bottom:.75rem">
              Features
            </h2>
            <div style="display:flex;flex-direction:column;gap:.5rem;max-height:320px;overflow-y:auto">
              <.feature_toggle
                :for={feature <- @features}
                feature={feature}
                selected={MapSet.member?(@selected_features, feature.id)}
              />
            </div>
          </div>

          <div :if={@selected_board} style="display:flex;flex-direction:column;gap:.5rem">
            <button
              phx-click="build"
              disabled={@build_status == :building}
              style={button_style(@build_status)}
            >
              {button_label(@build_status)}
            </button>

            <button
              :if={@build_status == :done and platformio_board?(@selected_board)}
              phx-click="flash"
              disabled={@flash_status == :flashing}
              style={flash_button_style(@flash_status)}
            >
              {flash_label(@flash_status)}
            </button>

            <a
              :if={@last_build_record && @last_build_record.firmware_path}
              href={"/firmware/download?board_id=#{@selected_board}"}
              target="_blank"
              style="display:block;text-align:center;padding:.625rem 1rem;border-radius:var(--radius);font-weight:600;font-size:.8125rem;background:var(--card);border:1px solid var(--border);color:var(--purple);text-decoration:none"
            >
              ⬇ Download Firmware
            </a>
          </div>

          <div :if={@builds != []} style="background:var(--card);border:1px solid var(--border);border-radius:var(--radius);padding:1.25rem">
            <h2 style="font-size:.75rem;font-weight:600;text-transform:uppercase;letter-spacing:.05em;color:var(--text2);margin-bottom:.75rem">
              Build History
            </h2>
            <div style="display:flex;flex-direction:column;gap:.375rem;max-height:300px;overflow-y:auto">
              <div
                :for={build <- @builds}
                style="display:flex;align-items:center;justify-content:space-between;padding:.35rem .5rem;border-radius:var(--radius-sm);font-size:.75rem;font-family:var(--mono)"
              >
                <div style="display:flex;align-items:center;gap:.5rem;min-width:0">
                  <span style={build_status_style(build.status)}>
                    {if build.status == :done, do: "✓", else: "✗"}
                  </span>
                  <span style="white-space:nowrap;overflow:hidden;text-overflow:ellipsis">{build.board_id}</span>
                </div>
                <span style="color:var(--text3);font-size:.6875rem">
                  {format_build_time(build.inserted_at)}
                </span>
              </div>
            </div>
          </div>
        </aside>

        <section class="build-main" style="display:flex;flex-direction:column;gap:1rem">
          <div style="background:var(--card);border:1px solid var(--border);border-radius:var(--radius);flex:1;display:flex;flex-direction:column;overflow:hidden;min-height:400px">
            <div style="display:flex;align-items:center;justify-content:space-between;padding:.75rem 1rem;border-bottom:1px solid var(--border);background:var(--bg2)">
              <h2 style="font-size:.75rem;font-weight:600;text-transform:uppercase;letter-spacing:.05em;color:var(--text2)">
                Build Output
              </h2>
              <div style="display:flex;align-items:center;gap:.5rem">
                <span style={status_dot_style(@build_status)}></span>
                <span style="font-size:.75rem;font-family:var(--mono);color:var(--text3)">
                  {status_label(@build_status, @build_result)}
                </span>
              </div>
            </div>
            <pre id="build-log" style="flex:1;overflow-y:auto;padding:1rem;margin:0;font-family:var(--mono);font-size:.8125rem;line-height:1.5;color:var(--text);background:var(--bg);white-space:pre-wrap;word-break:break-all">
              <span :if={@build_log_empty} style="color:var(--text3)">
                {empty_log_message(@selected_board)}
              </span>
              <span :for={{_id, line} <- @streams.build_log}><%= line %></span>
            </pre>
          </div>
        </section>

      <% else %>

        <div style="grid-column:1/-1">
          <%= if @page == :history do %>
            <.history_page builds={@builds} />
          <% else %>
            <.help_page />
          <% end %>
        </div>

      <% end %>

    </div>

    <script>
      function toggleTheme() {
        var html = document.documentElement;
        var current = html.className;
        var next = current === 'dark' ? 'light' : 'dark';
        html.className = next;
        localStorage.setItem('bruce-theme', next);
        document.getElementById('theme-icon').textContent = next === 'dark' ? '☀️' : '🌙';
      }
      document.addEventListener('DOMContentLoaded', function() {
        var theme = localStorage.getItem('bruce-theme') || 'dark';
        document.documentElement.className = theme;
        var icon = document.getElementById('theme-icon');
        if (icon) icon.textContent = theme === 'dark' ? '☀️' : '🌙';
      });
    </script>
    """
  end

  def history_page(assigns) do
    ~H"""
    <div style="max-width:800px">
      <h2 style="font-size:1rem;font-weight:700;margin-bottom:1.5rem">📋 Build History</h2>

      <%= if @builds == [] do %>
        <div style="background:var(--card);border:1px solid var(--border);border-radius:var(--radius);padding:2rem;text-align:center;color:var(--text3);font-size:.875rem">
          No builds yet. Select a board and click "Compile Firmware" to start.
        </div>
      <% else %>
        <div style="background:var(--card);border:1px solid var(--border);border-radius:var(--radius);overflow:hidden">
          <table style="width:100%;border-collapse:collapse;font-size:.8125rem">
            <thead>
              <tr style="background:var(--bg2);border-bottom:1px solid var(--border)">
                <th style="padding:.625rem .75rem;text-align:left;font-weight:600;color:var(--text2);text-transform:uppercase;font-size:.6875rem">Status</th>
                <th style="padding:.625rem .75rem;text-align:left;font-weight:600;color:var(--text2);text-transform:uppercase;font-size:.6875rem">Board</th>
                <th style="padding:.625rem .75rem;text-align:left;font-weight:600;color:var(--text2);text-transform:uppercase;font-size:.6875rem">Backend</th>
                <th style="padding:.625rem .75rem;text-align:left;font-weight:600;color:var(--text2);text-transform:uppercase;font-size:.6875rem">Features</th>
                <th style="padding:.625rem .75rem;text-align:right;font-weight:600;color:var(--text2);text-transform:uppercase;font-size:.6875rem">Time</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={build <- @builds} style="border-bottom:1px solid var(--border)">
                <td style="padding:.5rem .75rem">
                  <span style={build_status_style(build.status)}>
                    {if build.status == :done, do: "✓", else: "✗"}
                  </span>
                </td>
                <td style="padding:.5rem .75rem;font-family:var(--mono)">
                  <div style="font-weight:500">{build.board_id}</div>
                  <div style="font-size:.6875rem;color:var(--text3)">{build.board_name}</div>
                </td>
                <td style="padding:.5rem .75rem">
                  <span style={backend_badge_style(build.backend)}>{build.backend}</span>
                </td>
                <td style="padding:.5rem .75rem;color:var(--text3);font-size:.75rem">
                  {Enum.join(build.features, ", ") || "—"}
                </td>
                <td style="padding:.5rem .75rem;text-align:right;font-family:var(--mono);color:var(--text3);font-size:.75rem">
                  {format_build_time(build.inserted_at)}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      <% end %>

      <button :if={@builds != []} phx-click="clear_history" style="margin-top:.75rem;padding:.5rem 1rem;background:var(--card);border:1px solid var(--border);border-radius:var(--radius-sm);color:var(--red);font-size:.75rem;cursor:pointer">
        🗑 Clear History
      </button>
    </div>
    """
  end

  def help_page(assigns) do
    ~H"""
    <div style="max-width:800px">
      <h2 style="font-size:1rem;font-weight:700;margin-bottom:1.5rem">❓ Help / Quick Start</h2>

      <div style="display:flex;flex-direction:column;gap:1rem">
        <div style="background:var(--card);border:1px solid var(--border);border-radius:var(--radius);padding:1.25rem">
          <h3 style="font-size:.8125rem;font-weight:600;margin-bottom:.5rem">🎯 What is this?</h3>
          <p style="font-size:.8125rem;color:var(--text3);line-height:1.6">
            <strong>Bruce Firmware Builder</strong> compila firmware para dispositivos ESP32 e single-board computers.
            Selecione uma placa, escolha as features desejadas e clique em "Compile Firmware".
          </p>
        </div>

        <div style="background:var(--card);border:1px solid var(--border);border-radius:var(--radius);padding:1.25rem">
          <h3 style="font-size:.8125rem;font-weight:600;margin-bottom:.5rem">🔨 How to Build</h3>
          <ol style="font-size:.8125rem;color:var(--text3);line-height:1.8;padding-left:1.25rem">
            <li><strong>Select a board</strong> — Choose your target from the dropdown (ESP32, Nerves, or Zephyr)</li>
            <li><strong>Toggle features</strong> — Enable the libraries and drivers you need</li>
            <li><strong>Click "Compile Firmware"</strong> — Watch the live build log in real-time</li>
            <li><strong>Flash or Download</strong> — After success, flash via USB or download the .bin file</li>
          </ol>
        </div>

        <div style="background:var(--card);border:1px solid var(--border);border-radius:var(--radius);padding:1.25rem">
          <h3 style="font-size:.8125rem;font-weight:600;margin-bottom:.5rem">🔌 Backends</h3>
          <div style="display:flex;flex-direction:column;gap:.5rem;font-size:.8125rem">
            <div style="display:flex;align-items:center;gap:.5rem">
              <span style="font-size:1.25rem">🔌</span>
              <div>
                <div style="font-weight:500">ESP32 (PlatformIO)</div>
                <div style="color:var(--text3);font-size:.75rem">Compila firmware C++ para microcontroladores ESP32 via PlatformIO CLI</div>
              </div>
            </div>
            <div style="display:flex;align-items:center;gap:.5rem">
              <span style="font-size:1.25rem">🐧</span>
              <div>
                <div style="font-weight:500">Linux (Nerves)</div>
                <div style="color:var(--text3);font-size:.75rem">Gera imagens de sistema Linux completo para RPi, BeagleBone e outros SBCs</div>
              </div>
            </div>
            <div style="display:flex;align-items:center;gap:.5rem">
              <span style="font-size:1.25rem">⚡</span>
              <div>
                <div style="font-weight:500">Zephyr RTOS</div>
                <div style="color:var(--text3);font-size:.75rem">Compila para placas compatíveis com Zephyr RTOS via west build</div>
              </div>
            </div>
          </div>
        </div>

        <div style="background:var(--card);border:1px solid var(--border);border-radius:var(--radius);padding:1.25rem">
          <h3 style="font-size:.8125rem;font-weight:600;margin-bottom:.5rem">⌨️ CLI Alternative</h3>
          <p style="font-size:.8125rem;color:var(--text3);line-height:1.6">
            You can also build from the terminal without the web UI:
          </p>
          <pre style="margin-top:.5rem;padding:.75rem;background:var(--bg);border-radius:var(--radius-sm);font-size:.75rem;overflow-x:auto"><code>$ mix bruce</code></pre>
        </div>
      </div>
    </div>
    """
  end

  # --- Board Tree Component ---

  def board_tree(assigns) do
    ~H"""
    <div style="display:flex;flex-direction:column;gap:.25rem">
      <%= for group <- @tree do %>
        <div>
          <div style="display:flex;align-items:center;gap:.5rem;font-size:.6875rem;font-weight:600;text-transform:uppercase;letter-spacing:.04em;color:var(--text2);margin-bottom:.25rem">
            <span>{group.icon}</span>
            <span>{group.label}</span>
          </div>

          <%= for mfr <- group.manufacturers do %>
            <% path = "#{group.key}/#{mfr.name}" %>
            <% expanded = MapSet.member?(@expanded, path) %>

            <div>
              <div
                phx-click="tree_toggle"
                phx-value-path={path}
                style="display:flex;align-items:center;gap:.35rem;padding:.35rem .5rem;border-radius:var(--radius-sm);cursor:pointer;font-size:.8125rem;font-weight:500;color:var(--text);transition:background .12s"
                onmouseover="this.style.background='var(--bg2)'"
                onmouseout="this.style.background='transparent'"
              >
                <span style="font-size:.5rem;color:var(--text3);width:1em;text-align:center;transition:transform .15s" class={"arrow-" <> if expanded, do: "open", else: "closed"}>
                  {if expanded, do: "▼", else: "▶"}
                </span>
                <span>📁</span>
                <span>{mfr.name}</span>
                <span style="font-size:.6875rem;color:var(--text3);margin-left:auto">{length(mfr.boards)}</span>
              </div>

              <div :if={expanded} style="margin-left:.75rem;border-left:1px solid var(--border);padding-left:.35rem">
                <%= for board <- mfr.boards do %>
                  <% selected = board.id == @selected %>
                  <div
                    phx-click="select_board"
                    phx-value-board={board.id}
                    style={"display:flex;align-items:center;gap:.35rem;padding:.3rem .5rem;border-radius:var(--radius-sm);cursor:pointer;font-size:.75rem;font-family:var(--mono);transition:background .12s" <> if selected, do: ";background:rgba(139,92,246,.12);color:var(--purple)", else: ";color:var(--text)"}
                    onmouseover={unless selected, do: "this.style.background='var(--bg2)'"}
                    onmouseout={unless selected, do: "this.style.background='transparent'"}
                  >
                    <span style="color:var(--text3);font-size:.625rem">┆</span>
                    <span>{board.model}</span>
                    <span :if={board.variant} style="color:var(--text3);font-size:.6875rem;font-family:sans-serif">
                      ({board.variant})
                    </span>
                    <span style="margin-left:auto;font-size:.625rem;color:var(--text3)">{board.mcu}</span>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  # --- Navigation ---

  defp nav_tab_style(active?) do
    base = "padding:.625rem .875rem;border:none;background:transparent;color:var(--text3);font-size:.8125rem;font-weight:500;cursor:pointer;border-bottom:2px solid transparent;transition:all .15s"
    if active?, do: base <> ";color:var(--purple);border-bottom-color:var(--purple)", else: base
  end

  defp nav_icon_btn do
    "background:var(--card);border:1px solid var(--border);border-radius:var(--radius-sm);padding:.35rem .5rem;cursor:pointer;font-size:.875rem;line-height:1;color:var(--text)"
  end

  defp step_style(done, _step) do
    base = "transition:color .2s"
    if done, do: base <> ";color:var(--green)", else: base <> ";color:var(--text3)"
  end

  defp backend_badge_style(:platformio), do: "font-size:.625rem;font-weight:600;padding:.125rem .5rem;border-radius:999px;background:rgba(6,182,212,.15);color:var(--aqua)"
  defp backend_badge_style(:nerves), do: "font-size:.625rem;font-weight:600;padding:.125rem .5rem;border-radius:999px;background:rgba(34,197,94,.15);color:var(--green)"
  defp backend_badge_style(:zephyr), do: "font-size:.625rem;font-weight:600;padding:.125rem .5rem;border-radius:999px;background:rgba(234,179,8,.15);color:var(--yellow)"
  defp backend_badge_style(_), do: "font-size:.625rem;font-weight:600;padding:.125rem .5rem;border-radius:999px;background:rgba(136,136,170,.15);color:var(--text3)"

  defp backend_label(:platformio), do: "ESP32"
  defp backend_label(:nerves), do: "Nerves"
  defp backend_label(:zephyr), do: "Zephyr"
  defp backend_label(_), do: "?"

  defp backend_full_label(:platformio), do: "PlatformIO (ESP32)"
  defp backend_full_label(:nerves), do: "Nerves (Linux)"
  defp backend_full_label(:zephyr), do: "Zephyr RTOS"
  defp backend_full_label(_), do: "Unknown"

  # --- Helpers ---

  defp platformio_board?(board_id) do
    is_binary(board_id) and BruceElixir.Hardware.PlatformIO.supports?(board_id)
  end

  defp button_style(:building), do: "width:100%;padding:.75rem 1.5rem;border:none;border-radius:var(--radius);font-weight:600;font-size:.875rem;background:var(--text3);color:#fff;cursor:wait"
  defp button_style(_), do: "width:100%;padding:.75rem 1.5rem;border:none;border-radius:var(--radius);font-weight:600;font-size:.875rem;background:var(--grad);color:#fff;cursor:pointer"

  defp button_label(:building), do: "⏳ Compiling..."
  defp button_label(:done), do: "✓ Build Complete"
  defp button_label(:error), do: "✗ Build Failed"
  defp button_label(_), do: "🚀 Compile Firmware"

  defp flash_button_style(:flashing), do: "width:100%;padding:.625rem 1rem;border:none;border-radius:var(--radius);font-weight:600;font-size:.8125rem;background:var(--yellow);color:#fff;cursor:wait"
  defp flash_button_style(_), do: "width:100%;padding:.625rem 1rem;border:none;border-radius:var(--radius);font-weight:600;font-size:.8125rem;background:var(--green);color:#fff;cursor:pointer"

  defp flash_label(:flashing), do: "⏳ Flashing..."
  defp flash_label(_), do: "⚡ Flash Firmware"

  defp status_dot_style(:idle), do: "width:8px;height:8px;border-radius:50%;background:var(--text3)"
  defp status_dot_style(:building), do: "width:8px;height:8px;border-radius:50%;background:var(--yellow);animation:pulse 1s infinite"
  defp status_dot_style(:done), do: "width:8px;height:8px;border-radius:50%;background:var(--green)"
  defp status_dot_style(:error), do: "width:8px;height:8px;border-radius:50%;background:var(--red)"

  defp status_label(:idle, _), do: "idle"
  defp status_label(:building, _), do: "building"
  defp status_label(:done, code), do: "done (#{code})"
  defp status_label(:error, code), do: "error (#{code})"

  defp build_status_style(:done), do: "width:18px;height:18px;border-radius:50%;background:var(--green);display:inline-flex;align-items:center;justify-content:center;font-size:.625rem;color:#fff;flex-shrink:0"
  defp build_status_style(_), do: "width:18px;height:18px;border-radius:50%;background:var(--red);display:inline-flex;align-items:center;justify-content:center;font-size:.625rem;color:#fff;flex-shrink:0"

  defp format_build_time(dt) do
    dt |> DateTime.shift_zone!("Etc/UTC") |> Calendar.strftime("%H:%M:%S")
  end

  defp empty_log_message(nil), do: "Select a board to begin."
  defp empty_log_message(_), do: "Ready to build. Click 'Compile Firmware' to start."

  # --- Events ---

  def handle_event("goto_page", %{"page" => page}, socket) do
    {:noreply, assign(socket, page: String.to_existing_atom(page))}
  end

  def handle_event("tree_toggle", %{"path" => path}, socket) do
    expanded = socket.assigns.tree_expanded
    new_expanded = if MapSet.member?(expanded, path), do: MapSet.delete(expanded, path), else: MapSet.put(expanded, path)
    {:noreply, assign(socket, tree_expanded: new_expanded)}
  end

  def handle_event("select_board", %{"board" => board_id}, socket) do
    if connected?(socket), do: BruceElixir.PubSub.subscribe("build:#{board_id}")
    features = BruceElixir.Hardware.compatible_features(board_id)
    info = board_info(socket.assigns.board_groups, board_id)

    socket =
      socket
      |> assign(
        selected_board: board_id,
        selected_board_info: info,
        selected_features: features,
        build_log_empty: true,
        build_status: :idle,
        build_result: nil,
        flash_status: :idle,
        last_build_record: nil
      )
      |> stream(:build_log, [])

    {:noreply, socket}
  end

  def handle_event("toggle_feature:" <> feature_id, _, socket) do
    features = socket.assigns.selected_features
    features = if MapSet.member?(features, feature_id), do: MapSet.delete(features, feature_id), else: MapSet.put(features, feature_id)
    {:noreply, assign(socket, selected_features: features)}
  end

  def handle_event("build", _, socket) do
    board = socket.assigns.selected_board
    features = MapSet.to_list(socket.assigns.selected_features)

    if board do
      socket =
        socket
        |> assign(build_status: :building, build_log_empty: true, build_result: nil, last_build_record: nil)
        |> stream(:build_log, [])

      if connected?(socket) do
        BruceElixir.PubSub.subscribe("build:#{board}")
        Task.async(fn -> BruceElixir.Builder.build(board, features) end)
      end

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("flash", _, socket) do
    board = socket.assigns.selected_board

    if board do
      socket = assign(socket, flash_status: :flashing)

      if connected?(socket) do
        Task.async(fn -> do_flash(board) end)
      end

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("clear_history", _, socket) do
    BruceElixir.BuildHistory.clear()
    {:noreply, assign(socket, builds: [])}
  end

  # --- PubSub / Task messages ---

  def handle_info({:"$pg", _topic, {:build_log, line}}, socket) do
    {:noreply, socket |> assign(build_log_empty: false) |> stream_insert(:build_log, line, at: -1)}
  end

  def handle_info({:"$pg", _topic, {:flash_log, line}}, socket) do
    {:noreply, socket |> stream_insert(:build_log, line, at: -1)}
  end

  def handle_info({:"$pg", _topic, {:build_done, code}}, socket) do
    status = if code == 0, do: :done, else: :error
    board_id = socket.assigns.selected_board
    board_name = socket.assigns.selected_board_info[:name] || board_id
    backend = BruceElixir.Hardware.backend_for(board_id)
    firmware_path = firmware_path_for(backend, board_id)

    record = BruceElixir.BuildHistory.add(%{
      board_id: board_id,
      board_name: board_name,
      features: MapSet.to_list(socket.assigns.selected_features),
      status: status,
      result: code,
      backend: backend_name(backend),
      firmware_path: firmware_path
    })

    {:noreply,
     assign(socket,
       build_status: status,
       build_result: code,
       last_build_record: record,
       builds: BruceElixir.BuildHistory.recent(20)
     )}
  end

  def handle_info({:"$pg", _topic, {:flash_done, code}}, socket) do
    line = if code == 0, do: "\e[32m✔ Flash concluído\e[0m\n", else: "\e[31m✖ Flash falhou (exit #{code})\e[0m\n"
    {:noreply, socket |> assign(flash_status: :idle) |> stream_insert(:build_log, line, at: -1)}
  end

  def handle_info({ref, result}, socket) when is_reference(ref) do
    Process.demonitor(ref, [:flush])

    cond do
      socket.assigns.flash_status == :flashing ->
        code = if result == :ok, do: 0, else: 1
        BruceElixir.PubSub.broadcast("build:#{socket.assigns.selected_board}", {:flash_done, code})
        {:noreply, socket}

      true ->
        status = if result == :ok, do: :done, else: :error
        code = if result == :ok, do: 0, else: 1
        BruceElixir.PubSub.broadcast("build:#{socket.assigns.selected_board}", {:build_done, code})
        {:noreply, assign(socket, build_status: status, build_result: code)}
    end
  end

  # --- Privates ---

  defp do_flash(board_id) do
    BruceElixir.PubSub.broadcast("build:#{board_id}", {:flash_log, "\e[36m▶ Flashing #{board_id}...\e[0m\n"})

    port =
      Port.open(
        {:spawn, "pio run --target upload -e #{board_id}"},
        [:binary, :exit_status, cd: to_charlist("src_bruce")]
      )

    receive do
      {^port, {:data, data}} ->
        data
        |> String.split("\n")
        |> Enum.each(fn
          "" -> :ok
          line -> BruceElixir.PubSub.broadcast("build:#{board_id}", {:flash_log, "  \e[90m│\e[0m #{line}\n"})
        end)

      {^port, {:exit_status, 0}} ->
        BruceElixir.PubSub.broadcast("build:#{board_id}", {:flash_done, 0})
        :ok

      {^port, {:exit_status, code}} ->
        BruceElixir.PubSub.broadcast("build:#{board_id}", {:flash_done, code})
        {:error, code}
    end
  end

  defp board_info(groups, board_id) do
    group = Enum.find(groups, fn g ->
      Enum.any?(g.boards, &(&1.id == board_id))
    end)

    if group do
      board = Enum.find(group.boards, &(&1.id == board_id))
      %{name: board.name, mcu: board.mcu, backend: group.key}
    end
  end

  defp backend_name(BruceElixir.Hardware.PlatformIO), do: :platformio
  defp backend_name(BruceElixir.Hardware.Nerves), do: :nerves
  defp backend_name(BruceElixir.Hardware.Zephyr), do: :zephyr
  defp backend_name(_), do: :unknown

  defp firmware_path_for(BruceElixir.Hardware.PlatformIO, board_id) do
    path = "src_bruce/.pio/build/#{board_id}/firmware.bin"
    if File.exists?(path), do: path
  end

  defp firmware_path_for(BruceElixir.Hardware.Nerves, board_id) do
    path = Path.join(["_build", board_id, "dev", "nerves", "images", "bruce_elixir.fw"])
    if File.exists?(path), do: path
  end

  defp firmware_path_for(_, _), do: nil
end
