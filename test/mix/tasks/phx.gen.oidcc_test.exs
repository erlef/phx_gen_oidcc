defmodule Mix.Tasks.Phx.Gen.OidccTest do
  use ExUnit.Case, async: false

  @moduletag :integration
  @moduletag timeout: :timer.minutes(10)

  import ExUnit.CaptureIO

  alias PhxGenOidcc.Patch.InjectMixDependency

  @fixture_dir Application.app_dir(:phx_gen_oidcc, "priv/test/projects")

  setup %{test: test} = tags do
    cwd = File.cwd!()

    app_name = test |> Atom.to_string() |> String.replace(~r/[^\w]/iu, "_") |> String.to_atom()

    app_dir = Path.join(@fixture_dir, to_string(app_name))

    File.rm_rf!(app_dir)
    File.mkdir_p!(@fixture_dir)

    File.cd!(@fixture_dir)

    phx_new_opts =
      Map.get(tags, :phx_new_opts, [
        "--no-assets",
        "--no-dashboard",
        "--no-ecto",
        "--no-mailer"
      ])

    capture_io(fn ->
      Mix.Task.rerun("phx.new", [
        to_string(app_name),
        "--install" | phx_new_opts
      ])
    end)

    File.cd!(cwd)

    on_exit(fn ->
      File.rm_rf!(app_dir)
    end)

    {:ok, app_dir: app_dir, app_name: app_name}
  end

  test "works", %{app_dir: app_dir} do
    %{"clientId" => client_id, "clientSecret" => client_secret} =
      :phx_gen_oidcc
      |> Application.app_dir("priv/test/fixtures/zitadel-client.json")
      |> File.read!()
      |> Jason.decode!()

    in_project(app_dir, fn ->
      assert {_out, 0} =
               System.cmd(
                 "mix",
                 [
                   "phx.gen.oidcc",
                   "SampleApp.GoogleOpendIdProviderConfig",
                   "https://erlef-test-w4a8z2.zitadel.cloud",
                   client_id,
                   client_secret
                 ],
                 into: IO.stream()
               )

      assert File.read!("mix.exs") =~ "oidcc_plug"
    end)
  end

  @tag phx_new_opts: [
         "--no-html",
         "--no-assets",
         "--no-dashboard",
         "--no-ecto",
         "--no-mailer"
       ]
  test "raises without html", %{app_dir: app_dir} do
    %{"clientId" => client_id, "clientSecret" => client_secret} =
      :phx_gen_oidcc
      |> Application.app_dir("priv/test/fixtures/zitadel-client.json")
      |> File.read!()
      |> Jason.decode!()

    in_project(app_dir, fn ->
      capture_io(fn ->
        assert {_out, 1} =
                 System.cmd(
                   "mix",
                   [
                     "phx.gen.oidcc",
                     "SampleApp.GoogleOpendIdProviderConfig",
                     "https://erlef-test-w4a8z2.zitadel.cloud",
                     client_id,
                     client_secret
                   ],
                   into: IO.stream(),
                   stderr_to_stdout: true
                 )
      end) =~ "contains html templates"

      refute File.read!("mix.exs") =~ "oidcc_plug"
    end)
  end

  test "raises wit incorrect arguments", %{app_dir: app_dir} do
    in_project(app_dir, fn ->
      capture_io(fn ->
        assert {_out, 1} =
                 System.cmd(
                   "mix",
                   [
                     "phx.gen.oidcc",
                     "SampleApp.GoogleOpendIdProviderConfig",
                     "https://erlef-test-w4a8z2.zitadel.cloud"
                   ],
                   into: IO.stream(),
                   stderr_to_stdout: true
                 )
      end) =~ "Invalid arguments"

      refute File.read!("mix.exs") =~ "oidcc_plug"
    end)
  end

  defp in_project(path, fun) do
    cwd = File.cwd!()

    try do
      File.cd!(path)

      InjectMixDependency.apply(
        "mix.exs",
        %{},
        quote do
          {:phx_gen_oidcc, path: "../../../.."}
        end
      )

      capture_io(fn ->
        {_out, 0} = System.cmd("mix", ["deps.get"], into: IO.stream())
        {_out, 0} = System.cmd("mix", ["compile"], into: IO.stream())
      end)

      fun.()
    after
      File.cd!(cwd)
    end
  end
end
