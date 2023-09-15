defmodule PhxGenOidcc.Patch.AddRuntimeConfigTest do
  use PhxGenOidcc.PatchCase, async: true

  alias PhxGenOidcc.Patch.AddRuntimeConfig

  doctest AddRuntimeConfig

  @opts %{
    app: :test_app,
    issuer: "https://accounts.google.com",
    client_id: "client_id",
    client_secret: "client_secret"
  }

  describe inspect(&AddRuntimeConfig.apply/1) do
    test "replaces in normal phoenix config/runtime.exs" do
      {:ok, {_dir, file_path}} =
        create_context_file("config/runtime.exs", """
        import Config

        if System.get_env("PHX_SERVER") do
          config :test_app, TestAppWeb.Endpoint, server: true
        end
        """)

      AddRuntimeConfig.apply(file_path, @opts)

      assert String.trim("""
             import Config

             if System.get_env("PHX_SERVER") do
               config :test_app, TestAppWeb.Endpoint, server: true
             end

             config :test_app, Oidcc,
               issuer: "https://accounts.google.com",
               client_id: "client_id",
               client_secret: "client_secret"
             """) == file_path |> File.read!() |> String.trim()
    end
  end

  describe inspect(&AddRuntimeConfig.conflict_description/1) do
    test "works" do
      assert """
             Add the following to your config:

             config :test_app, Oidcc,
               issuer: "https://accounts.google.com",
               client_id: "client_id",
               client_secret: "client_secret"
             """ = AddRuntimeConfig.conflict_description(@opts)
    end
  end
end
