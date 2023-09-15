defmodule PhxGenOidcc.Patch.AddRoutesTest do
  use PhxGenOidcc.PatchCase, async: true

  alias PhxGenOidcc.Patch.AddRoutes

  doctest AddRoutes

  @opts %{
    app: :test_app,
    app_base: TestApp,
    web_base: TestAppWeb
  }

  describe inspect(&AddRoutes.apply/1) do
    test "adds routes to lib/app_web/router.ex" do
      {:ok, {_dir, file_path}} =
        create_context_file("lib/test_app_web/router.ex", """
        defmodule TestAppWeb.Router do
          use TestAppWeb, :router

          pipeline :browser do
            plug :accepts, ["html"]
          end

          pipeline :api do
            plug :accepts, ["json"]
          end

          scope "/", TestAppWeb do
            pipe_through :browser

            get "/", PageController, :home
          end

          # Other scopes may use custom stacks.
          # scope "/api", TestAppWeb do
          #   pipe_through :api
          # end
        end
        """)

      AddRoutes.apply(file_path, @opts)

      assert String.trim("""
             defmodule TestAppWeb.Router do
               use TestAppWeb, :router

               pipeline :browser do
                 plug :accepts, ["html"]
               end

               pipeline :api do
                 plug :accepts, ["json"]
               end

               scope "/", TestAppWeb do
                 pipe_through :browser

                 get "/", PageController, :home
               end

               scope("/oidcc", TestAppWeb) do
                 pipe_through :browser
                 get "/authorize", OidccController, :authorize
                 get "/callback", OidccController, :callback
                 post "/callback", OidccController, :callback
               end

               # Other scopes may use custom stacks.
               # scope "/api", TestAppWeb do
               #   pipe_through :api
               # end
             end
             """) == file_path |> File.read!() |> String.trim()
    end

    test "raises conflict on abnormal formatted router.ex" do
      {:ok, {_dir, file_path}} =
        create_context_file("mix.exs", """
        IO.inspect(:hello)
        """)

      assert :conflict = AddRoutes.apply(file_path, @opts)
    end
  end

  describe inspect(&AddRoutes.conflict_description/1) do
    test "works" do
      assert """
             Add the following to your router:

             scope("/oidcc", TestAppWeb) do
               pipe_through :browser
               get "/authorize", OidccController, :authorize
               get "/callback", OidccController, :callback
               post "/callback", OidccController, :callback
             end
             """ = AddRoutes.conflict_description(@opts)
    end
  end
end
