defmodule Mix.Tasks.Mapper do
  use Mix.Task

  @source_dir "src_bruce/lib"

  def run(_args) do
    Path.wildcard("#{@source_dir}/*")
    |> Enum.filter(&File.dir?/1)
    |> Enum.map(fn path ->
      name = Path.basename(path)
      # Classificação inteligente baseada no nome ou conteúdo
      {name, categorize(name, path), false}
    end)
  end

defp categorize(name, _path) do
      cond do
      String.contains?(name, "Lib") -> :library
      String.contains?(name, "touch") -> :driver
      String.contains?(name, "TFT") -> :display
      String.contains?(name, "utility") -> :util
      true -> :other
    end
  end
end
