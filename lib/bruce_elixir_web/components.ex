defmodule BruceElixirWeb.Components do
  use Phoenix.Component

  def build_layout(assigns) do
    ~H"""
    <div style="min-height:100vh;display:flex;flex-direction:column">
      <header style="background:var(--bg2);border-bottom:1px solid var(--border);padding:1rem 2rem">
        <div style="max-width:1200px;margin:0 auto;display:flex;align-items:center;gap:1rem">
          <span style="font-size:1.5rem">🦈</span>
          <h1 style="font-size:1.25rem;font-weight:700;background:var(--grad);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text">
            Bruce Firmware Builder
          </h1>
          <span style="margin-left:auto;font-size:.75rem;font-family:var(--mono);color:var(--text2);background:var(--card);padding:.25rem .75rem;border-radius:999px;border:1px solid var(--border)">
            v0.1.0
          </span>
        </div>
      </header>
      <main style="flex:1;max-width:1200px;width:100%;margin:2rem auto;padding:0 2rem">
        {@inner_block}
      </main>
    </div>
    """
  end

  attr :feature, :map, required: true
  attr :selected, :boolean, required: true

  def feature_toggle(assigns) do
    ~H"""
    <div
      phx-click={"toggle_feature:" <> @feature.id}
      style={"display:flex;align-items:center;gap:.625rem;padding:.4rem .5rem;border-radius:var(--radius-sm);cursor:pointer;transition:background .15s" <>
        (if @selected, do: ";background:var(--hover)", else: "")}
    >
      <input
        type="checkbox"
        checked={@selected}
        style="accent-color:var(--purple);width:1rem;height:1rem;pointer-events:none"
      />
      <span style="flex-shrink:0;font-size:1.1rem">{icon_for(@feature.id)}</span>
      <div style="flex:1;min-width:0">
        <div style="font-size:.875rem;font-weight:500">{@feature.name}</div>
        <div style="font-size:.75rem;color:var(--text3)">{@feature.description}</div>
      </div>
      <span style="font-size:.625rem;font-weight:600;text-transform:uppercase;padding:.125rem .375rem;border-radius:3px;background:rgba(139,92,246,.15);color:var(--purple)">
        {@feature.category}
      </span>
    </div>
    """
  end

  defp icon_for("Bad_Usb_Lib"), do: "⌨️"
  defp icon_for("CYD-touch"), do: "👆"
  defp icon_for("HAL"), do: "⚙️"
  defp icon_for("PN532_SRIX"), do: "📡"
  defp icon_for("RTC"), do: "⏰"
  defp icon_for("TFT_eSPI"), do: "🖥️"
  defp icon_for("TFT_eSPI_QRcode"), do: "📱"
  defp icon_for("utility"), do: "🔋"
  defp icon_for(_), do: "🔌"
end
