defmodule PhxGenOidcc.Patch.InjectMixDependency do
  @moduledoc false

  @behaviour PhxGenOidcc.Patch

  @impl PhxGenOidcc.Patch
  def apply(file, _opts, dependency \\ default_dependency()) do
    file
    |> File.read!()
    |> Sourceror.parse_string!()
    |> Sourceror.postwalk(false, fn
      {:defp, meta, [{:deps, _, _} = fun, body]}, state ->
        [{{_, _, [:do]}, block_ast}] = body
        {:__block__, block_meta, [deps]} = block_ast

        dep_line =
          case List.last(deps) do
            {_, meta, _} ->
              meta[:line] || block_meta[:line]

            _ ->
              block_meta[:line]
          end + 1

        deps =
          deps ++
            [
              {:__block__, [line: dep_line], [dependency]}
            ]

        ast = {:defp, meta, [fun, [do: {:__block__, block_meta, [deps]}]]}
        {ast, %Sourceror.TraversalState{state | acc: true}}

      other, state ->
        {other, state}
    end)
    |> case do
      {ast, true} ->
        File.write!(file, Sourceror.to_string(ast))
        :ok

      {_ast, false} ->
        :conflict
    end
  end

  @impl PhxGenOidcc.Patch
  def conflict_description(_opts),
    do: """
    Add {:oidcc_plug, "~> 0.1.0-rc"} to your project mix.exs.
    """

  defp default_dependency do
    quote do
      {:oidcc_plug, "~> 0.1.0-rc"}
    end
  end
end
