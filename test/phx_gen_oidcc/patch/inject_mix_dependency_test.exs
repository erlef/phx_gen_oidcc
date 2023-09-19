defmodule PhxGenOidcc.Patch.InjectMixDependencyTest do
  use PhxGenOidcc.PatchCase, async: true

  alias PhxGenOidcc.Patch.InjectMixDependency

  doctest InjectMixDependency

  @opts %{}

  describe inspect(&InjectMixDependency.apply/1) do
    test "replaces in normal phoenix mix.exs" do
      {:ok, {_dir, file_path}} =
        create_context_file("mix.exs", """
        defmodule TestApp.MixProject do
          use Mix.Project

          # Specifies your project dependencies.
          #
          # Type `mix help deps` for examples and options.
          defp deps do
            [
              {:plug_cowboy, "~> 2.5"}
            ]
          end
        end
        """)

      InjectMixDependency.apply(file_path, @opts)

      assert String.trim("""
             defmodule TestApp.MixProject do
               use Mix.Project

               # Specifies your project dependencies.
               #
               # Type `mix help deps` for examples and options.
               defp deps do
                 [
                   {:plug_cowboy, "~> 2.5"},
                   {:oidcc_plug, "~> 0.1.0-rc"}
                 ]
               end
             end
             """) == file_path |> File.read!() |> String.trim()
    end

    test "raises conflict on abnormal formatted mix.exs" do
      {:ok, {_dir, file_path}} =
        create_context_file("mix.exs", """
        defmodule TestApp.MixProject do
          use Mix.Project

          def project do
           [
             deps: [
               {:plug_cowboy, "~> 2.5"}
             ]
           ]
          end
        end
        """)

      assert :conflict = InjectMixDependency.apply(file_path, @opts)
    end
  end

  describe inspect(&InjectMixDependency.conflict_description/1) do
    test "works" do
      assert """
             Add {:oidcc_plug, "~> 0.1.0-rc"} to your project mix.exs.
             """ = InjectMixDependency.conflict_description(@opts)
    end
  end
end
