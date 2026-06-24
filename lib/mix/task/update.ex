defmodule Mix.Tasks.Update do
  @moduledoc """
  Atualiza o submódulo do Bruce para a versão mais recente do repositório remoto.

  Uso: `mix update`
  """
  use Mix.Task

  @shortdoc "Atualiza o submódulo src_bruce do GitHub."
  @submodule_path "src_bruce"

  def run(_args) do
    Mix.shell().info("=== Iniciando atualização do submódulo: #{@submodule_path} ===")

    # 1. Verifica se o submódulo existe
    if !File.exists?(@submodule_path) do
      Mix.shell().error("Pasta #{@submodule_path} não encontrada. Você inicializou os submódulos?")
      exit({:shutdown, 1})
    end

    # 2. Atualiza a referência do submódulo (git submodule update --remote --merge)
    # --remote: busca a branch principal do repositório remoto
    # --merge: integra as alterações automaticamente
    {_output, exit_code} = System.cmd("git", ["submodule", "update", "--remote", "--merge", @submodule_path])

    if exit_code == 0 do
      Mix.shell().info("✓ Submódulo atualizado com sucesso.")

      # 3. Informa o próximo passo para o usuário
      Mix.shell().info("=== Próximo passo ===")
      Mix.shell().info("Agora você pode rodar 'git add #{@submodule_path}' e 'git commit' para salvar essa nova versão no seu histórico.")
    else
      Mix.shell().error("Falha ao atualizar o submódulo. Verifique sua conexão ou conflitos no Git.")
    end
  end
end
