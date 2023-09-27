defmodule Mix.Tasks.Phx.Gen.Oidcc do
  @shortdoc "Generates OpenID Login code for Phoenix project"

  @moduledoc """
  Generates OpenID Login code for Phoenix project

  ```console
  $ mix phx.gen.oidcc \\
      MyApp.ConfigProviderName \\\
      "https://isser.example.com" \\
      "client_id" \\
      "client_secret"
  ```

  ## Arguments

  1. The name of the OpenID Provider Configuration Worker
  1. The issuer URL of the OpenID Provider
  1. The Client ID
  1. The Client Secret
  """
  @moduledoc since: "0.1.0"

  use Mix.Task

  @switches []

  @impl Mix.Task
  def run(args) do
    Application.load(:phx_gen_oidcc)

    if Mix.Project.umbrella?() do
      Mix.raise("mix phx.gen.auth can only be run inside an application directory")
    end

    {opts, parsed} = OptionParser.parse!(args, strict: @switches)
    validate_args!(parsed)

    [provider_name, issuer, client_id, client_secret] = parsed

    app = Mix.Phoenix.otp_app()

    opts =
      opts
      |> Keyword.merge(
        app: app,
        app_base: Mix.Phoenix.base(),
        web_base: Mix.Phoenix.web_module(Mix.Phoenix.base()),
        provider_name: provider_name,
        issuer: issuer,
        client_id: client_id,
        client_secret: client_secret
      )
      |> Map.new()

    validate_required_dependencies!()

    # Apply patches to eisting Elixir Code
    Enum.each(
      [
        {"mix.exs", PhxGenOidcc.Patch.InjectMixDependency},
        {"config/runtime.exs", PhxGenOidcc.Patch.AddRuntimeConfig},
        {Mix.Phoenix.web_path(app, "router.ex"), PhxGenOidcc.Patch.AddRoutes},
        {Mix.Phoenix.context_lib_path(app, "application.ex"),
         PhxGenOidcc.Patch.AddConfigProviderWorker}
      ],
      fn {file, patch} ->
        case patch.apply(file, opts) do
          :conflict ->
            Mix.Shell.IO.error("""
            The file #{file} could not be patched automatically.

            #{patch.conflict_description(opts)}
            """)

          :ok ->
            :ok
        end
      end
    )

    # Move new Elixir Code into the project
    Enum.each(
      [
        {"oidcc_controller.exs", Mix.Phoenix.web_path(app, "controllers/oidcc_controller.ex")},
        {"oidcc_html.exs", Mix.Phoenix.web_path(app, "controllers/oidcc_html.ex")}
      ],
      fn {source, destination} ->
        {result, _bindings} =
          Code.eval_file(source, Application.app_dir(:phx_gen_oidcc, "priv/templates"))

        code = result.(opts)

        File.write!(destination, Macro.to_string(code))
      end
    )

    # Copy support files to the project
    Enum.each(
      [
        {"error.html.heex", Mix.Phoenix.web_path(app, "controllers/oidcc_html/error.html.heex")}
      ],
      fn {source, destination} ->
        destination |> Path.dirname() |> File.mkdir_p!()

        File.cp!(
          Path.join(Application.app_dir(:phx_gen_oidcc, "priv/templates"), source),
          destination
        )
      end
    )

    # Append to support files in project
    Enum.each(
      [
        {"home.html.heex", Mix.Phoenix.web_path(app, "controllers/page_html/home.html.heex")}
      ],
      fn {source, destination} ->
        contents =
          File.read!(Path.join(Application.app_dir(:phx_gen_oidcc, "priv/templates"), source))

        File.write!(destination, contents, [:append])
      end
    )
  end

  @spec validate_args!(args :: [String.t()]) :: :ok
  defp validate_args!(args)
  defp validate_args!([_, _, _, _]), do: :ok
  defp validate_args!(_), do: raise_with_help("Invalid arguments")

  @spec validate_required_dependencies!() :: :ok
  defp validate_required_dependencies! do
    if generated_with_no_html?() do
      raise_with_help("mix phx.gen.oidcc requires phoenix_html", :phx_generator_args)
    end

    :ok
  end

  @spec generated_with_no_html?() :: boolean()
  defp generated_with_no_html? do
    Mix.Project.config()
    |> Keyword.get(:deps, [])
    |> Enum.any?(fn
      {:phoenix_html, _} -> true
      {:phoenix_html, _, _} -> true
      _ -> false
    end)
    |> Kernel.not()
  end

  @dialyzer {:no_return, raise_with_help: 1}
  @spec raise_with_help(msg :: String.t(), type :: :general | :phx_generator_args) :: no_return()
  defp raise_with_help(msg, type \\ :general)

  defp raise_with_help(msg, :general) do
    Mix.raise("""
    #{msg}

    mix phx.gen.oidcc expects a provider configuration worker name, followed by
    the isser, client id and client secret.

    For example:

        mix phx.gen.oidcc \\
          MyApp.ConfigProviderName \\
          "https://isser.example.com" \\
          "client_id" \\
          "client_secret"
    """)
  end

  defp raise_with_help(msg, :phx_generator_args) do
    Mix.raise("""
    #{msg}

    mix phx.gen.oidcc must be installed into a Phoenix 1.7 app that
    contains html templates.

        mix phx.new my_app

    Apps generated with --no-html are not supported.
    """)
  end
end
