defmodule PhxGenOidcc.Patch.AddConfigProviderWorkerTest do
  use PhxGenOidcc.PatchCase, async: true

  alias PhxGenOidcc.Patch.AddConfigProviderWorker

  doctest AddConfigProviderWorker

  @opts %{
    app: :test_app,
    app_base: TestApp
  }

  describe inspect(&AddConfigProviderWorker.apply/1) do
    test "replaces in normal phoenix lib/test_app/application.ex" do
      {:ok, {_dir, file_path}} =
        create_context_file("lib/test_app/application.ex", """
        defmodule TestWorks.Application do
          # See https://hexdocs.pm/elixir/Application.html
          # for more information on OTP Applications
          @moduledoc false

          use Application

          @impl true
          def start(_type, _args) do
            children = [
              # Start the Telemetry supervisor
              TestWorksWeb.Telemetry,
              # Start the PubSub system
              {Phoenix.PubSub, name: TestWorks.PubSub},
              # Start the Endpoint (http/https)
              TestWorksWeb.Endpoint
              # Start a worker by calling: TestWorks.Worker.start_link(arg)
              # {TestWorks.Worker, arg}
            ]

            # See https://hexdocs.pm/elixir/Supervisor.html
            # for other strategies and supported options
            opts = [strategy: :one_for_one, name: TestWorks.Supervisor]
            Supervisor.start_link(children, opts)
          end

          # Tell Phoenix to update the endpoint configuration
          # whenever the application is updated.
          @impl true
          def config_change(changed, _new, removed) do
            TestWorksWeb.Endpoint.config_change(changed, removed)
            :ok
          end
        end
        """)

      assert :ok = AddConfigProviderWorker.apply(file_path, @opts)

      assert String.trim("""
             defmodule TestWorks.Application do
               # See https://hexdocs.pm/elixir/Application.html
               # for more information on OTP Applications
               @moduledoc false

               use Application

               @impl true
               def start(_type, _args) do
                 children = [
                   # Start the Telemetry supervisor
                   TestWorksWeb.Telemetry,
                   # Start the PubSub system
                   {Phoenix.PubSub, name: TestWorks.PubSub},
                   {Oidcc.ProviderConfiguration.Worker,
                    %{
                      issuer: Application.fetch_env!(:test_app, Oidcc)[:issuer],
                      name: TestApp.OpenIdConfigurationProvider
                    }},
                   # Start the Endpoint (http/https)
                   TestWorksWeb.Endpoint

                   # Start a worker by calling: TestWorks.Worker.start_link(arg)
                   # {TestWorks.Worker, arg}
                 ]

                 # See https://hexdocs.pm/elixir/Supervisor.html
                 # for other strategies and supported options
                 opts = [strategy: :one_for_one, name: TestWorks.Supervisor]
                 Supervisor.start_link(children, opts)
               end

               # Tell Phoenix to update the endpoint configuration
               # whenever the application is updated.
               @impl true
               def config_change(changed, _new, removed) do
                 TestWorksWeb.Endpoint.config_change(changed, removed)
                 :ok
               end
             end
             """) == file_path |> File.read!() |> String.trim()
    end

    test "raises conflict on abnormal formatted mix.exs" do
      {:ok, {_dir, file_path}} =
        create_context_file("mix.exs", """
        defmodule TestWorks.Application do
          # See https://hexdocs.pm/elixir/Application.html
          # for more information on OTP Applications
          @moduledoc false

          use Application

          @impl true
          def start(_type, _args) do
            # See https://hexdocs.pm/elixir/Supervisor.html
            # for other strategies and supported options
            opts = [strategy: :one_for_one, name: TestWorks.Supervisor]
            Supervisor.start_link([], opts)
          end

          # Tell Phoenix to update the endpoint configuration
          # whenever the application is updated.
          @impl true
          def config_change(changed, _new, removed) do
            TestWorksWeb.Endpoint.config_change(changed, removed)
            :ok
          end
        end
        """)

      assert :conflict = AddConfigProviderWorker.apply(file_path, @opts)
    end
  end

  describe inspect(&AddConfigProviderWorker.conflict_description/1) do
    test "works" do
      assert """
             Add the following GenServer to your application supervisor before the TestApp.OpenIdConfigurationProvider:

             {Oidcc.ProviderConfiguration.Worker,
              %{
                issuer: Application.fetch_env!(:test_app, Oidcc)[:issuer],
                name: TestApp.OpenIdConfigurationProvider
              }}
             """ = AddConfigProviderWorker.conflict_description(@opts)
    end
  end
end
