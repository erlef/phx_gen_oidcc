fn %{app: app_name, web_base: web_base, app_base: app_base} = _opts ->
  quote do
    defmodule unquote(Module.concat(web_base, OidccController)) do
      use unquote(web_base), :controller

      plug Oidcc.Plug.Authorize,
           [
             provider: unquote(Module.concat(app_base, OpenIdConfigurationProvider)),
             client_id: &__MODULE__.client_id/0,
             client_secret: &__MODULE__.client_secret/0,
             redirect_uri: &__MODULE__.callback_uri/0
           ]
           when action in [:authorize]

      plug Oidcc.Plug.AuthorizationCallback,
           [
             provider: unquote(Module.concat(app_base, OpenIdConfigurationProvider)),
             client_id: &__MODULE__.client_id/0,
             client_secret: &__MODULE__.client_secret/0,
             redirect_uri: &__MODULE__.callback_uri/0
           ]
           when action in [:callback]

      def authorize(conn, _params), do: conn

      def callback(
            %Plug.Conn{private: %{Oidcc.Plug.AuthorizationCallback => {:ok, {_token, userinfo}}}} =
              conn,
            params
          ) do
        conn
        |> put_session("oidcc_claims", userinfo)
        |> redirect(
          to:
            case params[:state] do
              nil -> "/"
              state -> state
            end
        )
      end

      def callback(
            %Plug.Conn{private: %{Oidcc.Plug.AuthorizationCallback => {:error, reason}}} = conn,
            _params
          ) do
        conn
        |> put_status(400)
        |> render(:error, reason: reason)
      end

      @doc false
      def client_id, do: Application.fetch_env!(unquote(app_name), Oidcc)[:client_id]

      @doc false
      def client_secret, do: Application.fetch_env!(unquote(app_name), Oidcc)[:client_secret]

      @doc false
      def callback_uri, do: url(~p"/oidcc/callback")
    end
  end
end
