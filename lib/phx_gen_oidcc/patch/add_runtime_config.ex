defmodule PhxGenOidcc.Patch.AddRuntimeConfig do
  @moduledoc false

  @behaviour PhxGenOidcc.Patch

  @impl PhxGenOidcc.Patch
  def apply(file, opts) do
    file
    |> File.read!()
    |> Sourceror.parse_string!()
    |> Sourceror.postwalk(false, fn
      {:__block__, meta,
       [{:import, _import_meta, [{:__aliases__, _alias_meta, [:Config]}]} | _rest] = contents},
      %Sourceror.TraversalState{acc: false} = state ->
        ast =
          {:__block__, meta,
           contents ++
             [code(opts)]}

        {ast, %Sourceror.TraversalState{state | acc: true}}

      ast, state ->
        {ast, state}
    end)
    |> case do
      {ast, true} ->
        File.write!(file, Sourceror.to_string(ast))
        :ok

      {_ast, false} ->
        :conflict
    end
  end

  defp code(%{app: app_name, issuer: issuer, client_id: client_id, client_secret: client_secret}) do
    quote do
      config unquote(app_name), Oidcc,
        issuer: unquote(issuer),
        client_id: unquote(client_id),
        client_secret: unquote(client_secret)
    end
  end

  @impl PhxGenOidcc.Patch
  def conflict_description(opts),
    do: """
    Add the following to your config:

    #{Sourceror.to_string(code(opts))}
    """
end
