fn %{web_base: web_base} = _opts ->
  quote do
    defmodule unquote(Module.concat(web_base, OidccHTML)) do
      use unquote(web_base), :html

      embed_templates "oidcc_html/*"
    end
  end
end
