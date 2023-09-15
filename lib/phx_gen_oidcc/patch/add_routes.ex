defmodule PhxGenOidcc.Patch.AddRoutes do
  @moduledoc false

  @behaviour PhxGenOidcc.Patch

  @impl PhxGenOidcc.Patch
  def apply(file, opts) do
    file
    |> File.read!()
    |> Sourceror.parse_string!()
    |> Sourceror.postwalk(false, fn
      {:defmodule, meta,
       [
         {:__aliases__, _, _} = aliases,
         [{{:__block__, _, [:do]} = do_block, {:__block__, content_meta, contents}}]
       ]},
      %Sourceror.TraversalState{acc: false} = state ->
        {{:defmodule, meta,
          [aliases, [{do_block, {:__block__, content_meta, contents ++ [code(opts)]}}]]},
         %Sourceror.TraversalState{state | acc: true}}

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

  defp code(%{web_base: web_base}) do
    quote do
      scope "/oidcc", unquote(web_base) do
        pipe_through :browser

        get "/authorize", OidccController, :authorize
        get "/callback", OidccController, :callback
        post "/callback", OidccController, :callback
      end
    end
  end

  @impl PhxGenOidcc.Patch
  def conflict_description(opts),
    do: """
    Add the following to your router:

    #{Sourceror.to_string(code(opts))}
    """
end
