defmodule PhxGenOidcc.PatchCase do
  @moduledoc """
  Test Helpers for Patches
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import PhxGenOidcc.PatchCase
    end
  end

  @spec create_context_file(relative_file_name :: Path.t(), contents :: String.t()) ::
          {:ok, {Path.t(), Path.t()}}
  def create_context_file(relative_file_name, contents) do
    {:ok, dir} = Briefly.create(directory: true)

    file_path = Path.join(dir, relative_file_name)
    file_dir = Path.dirname(file_path)

    File.mkdir_p!(file_dir)

    File.write!(file_path, contents)

    {:ok, {dir, file_path}}
  end
end
