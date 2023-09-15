defmodule PhxGenOidcc.Patch.AddConfigProviderWorker do
  @moduledoc false

  @behaviour PhxGenOidcc.Patch

  @impl PhxGenOidcc.Patch
  def apply(file, opts) do
    file
    |> File.read!()
    |> Sourceror.parse_string!()
    |> Sourceror.postwalk(false, fn
      {:__block__, block_meta,
       [[{:__aliases__, _telemetry_meta, [_base, :Telemetry]} | _rest] = all_workers]},
      state ->
        {after_endpoint, before_endpoint} =
          Enum.split_with(
            all_workers,
            &match?({:__aliases__, _endpoint_meta, [_base, :Endpoint]}, &1)
          )

        {{:__block__, block_meta, [before_endpoint ++ [code(opts)] ++ after_endpoint]},
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

    # |> dbg()
  end

  defp code(%{app: app_name, app_base: app_base}) do
    quote do
      {Oidcc.ProviderConfiguration.Worker,
       %{
         issuer: Application.fetch_env!(unquote(app_name), Oidcc)[:issuer],
         name: unquote(Module.concat(app_base, OpenIdConfigurationProvider))
       }}
    end
  end

  @impl PhxGenOidcc.Patch
  def conflict_description(%{app_base: app_base} = opts),
    do: """
    Add the following GenServer to your application supervisor before the #{inspect(Module.concat(app_base, OpenIdConfigurationProvider))}:

    #{Sourceror.to_string(code(opts))}
    """
end
