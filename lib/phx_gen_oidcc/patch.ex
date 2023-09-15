defmodule PhxGenOidcc.Patch do
  @moduledoc false

  @type opts :: %{
          app: atom(),
          app_base: module(),
          web_base: module(),
          provider_name: GenServer.name(),
          issuer: String.t(),
          client_id: String.t(),
          client_secret: String.t()
        }

  @callback apply(file :: Path.t(), opts :: opts()) :: :ok | :conflict

  @callback conflict_description(opts :: opts()) :: String.t()
end
