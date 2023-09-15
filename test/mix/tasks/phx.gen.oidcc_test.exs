defmodule Mix.Tasks.Phx.Gen.OidccTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import ExUnit.CaptureIO

  alias Mix.Tasks.Phx.Gen.Oidcc, as: GenTask
  alias PhxGenOidcc.Patch.InjectMixDependency

  setup %{test: test} = tags do
    cwd = File.cwd!()

    app_name = test |> Atom.to_string() |> String.replace(~r/[^\w]/iu, "_") |> String.to_atom()

    fixture_dir = Application.app_dir(:phx_gen_oidcc, "priv/test/projects")
    app_dir = Path.join(fixture_dir, to_string(app_name))

    File.rm_rf!(app_dir)
    File.mkdir_p!(fixture_dir)

    File.cd!(fixture_dir)

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

  test "works", %{app_name: app_name, app_dir: app_dir} do
    %{"clientId" => client_id, "clientSecret" => client_secret} =
      :phx_gen_oidcc
      |> Application.app_dir("priv/test/fixtures/zitadel-client.json")
      |> File.read!()
      |> Jason.decode!()

    in_project(app_name, app_dir, fn _mix_module ->
      InjectMixDependency.apply(
        "mix.exs",
        %{},
        quote do
          {:phx_gen_oidcc, path: "../../../.."}
        end
      )

      capture_io(fn ->
        GenTask.run(
          [
            "SampleApp.GoogleOpendIdProviderConfig",
            "https://erlef-test-w4a8z2.zitadel.cloud",
            client_id,
            client_secret
          ],
          recompile?: false
        )
      end)

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
  test "raises without html", %{app_name: app_name, app_dir: app_dir} do
    %{"clientId" => client_id, "clientSecret" => client_secret} =
      :phx_gen_oidcc
      |> Application.app_dir("priv/test/fixtures/zitadel-client.json")
      |> File.read!()
      |> Jason.decode!()

    in_project(app_name, app_dir, fn _mix_module ->
      InjectMixDependency.apply(
        "mix.exs",
        %{},
        quote do
          {:phx_gen_oidcc, path: "../../../.."}
        end
      )

      assert_raise Mix.Error, fn ->
        capture_io(fn ->
          GenTask.run(
            [
              "SampleApp.GoogleOpendIdProviderConfig",
              "https://erlef-test-w4a8z2.zitadel.cloud",
              client_id,
              client_secret
            ],
            recompile?: false
          )
        end)
      end

      refute File.read!("mix.exs") =~ "oidcc_plug"
    end)
  end

  test "raises wit incorrect arguments", %{app_name: app_name, app_dir: app_dir} do
    in_project(app_name, app_dir, fn _mix_module ->
      InjectMixDependency.apply(
        "mix.exs",
        %{},
        quote do
          {:phx_gen_oidcc, path: "../../../.."}
        end
      )

      assert_raise Mix.Error, fn ->
        capture_io(fn ->
          GenTask.run(
            [
              "SampleApp.GoogleOpendIdProviderConfig",
              "https://erlef-test-w4a8z2.zitadel.cloud"
            ],
            recompile?: false
          )
        end)
      end

      refute File.read!("mix.exs") =~ "oidcc_plug"
    end)
  end

  defp in_project(app, path, fun) do
    %{name: name, file: file} = Mix.Project.pop()

    try do
      capture_io(:stderr, fn ->
        Mix.Project.in_project(app, path, [], fun)
      end)
    after
      Mix.Project.push(name, file)
    end
  end
end
