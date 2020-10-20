defmodule SnowpackStatic.Plug do
  @moduledoc """
  Phoenix plug to proxy a locally running instance of the snowpack dev server.<br />
  This plug will only serve assets when the env parameter has the value of `:dev`.<br />
  Phoenix will be allowed a chance to resolve any assets not resolved by snowpack.<br />

  ## Installation

  ```
  defp deps do
    [
      {:snowpack_static_web, "~> 0.3.0"}
    ]
  end
  ```

  And run:

    $ mix deps.get

  ## Usage
  Add SnowpackStatic.Plug as a plug in the phoenix project's endpoint.

  ## Arguments
  * **port** - *(required)* The port that the snowpack dev server is listening on.
  * **assets** - *(required)* a list of the paths in the static folder that snowpack will for serve. The plug will ignore requests to any other path.
  * **env** - *(required)* the current environment the project is running under.

  ## Example
    in `endpoint.ex`

    ```
      plug SnowpackStatic.Plug,
        port: 8080, assets: ~w(css fonts images js), env: Mix.env
    ```
  """
  alias Plug.Conn, as: Conn

  @doc false
  def init(args) do
    List.keysort(args, 0)
  end

  @doc false
  def call(conn, [{:assets, assets}, {:env, env}, {:port, port}]) do
    if env == :dev do
      serve_asset(conn, port, assets)
    else
      conn
    end
  end

  #  req_headers: req_headers
  defp serve_asset(conn = %Plug.Conn{path_info: [uri | path_parts]}, port, assets) do
    requested_path = "#{uri}/#{Enum.join(path_parts, "/")}"

    url =
      "http://localhost:#{port}"
      |> URI.merge(requested_path)
      |> URI.to_string()

    asset_type =
      uri
      |> String.split("/")
      |> hd

    if Enum.any?(assets, &(&1 == asset_type)) do
      # require Logger
      # Logger.warn(inspect(url, pretty: true))

      # TODO: maybe put back headers: req_headers
      case Tesla.get(url) do
        {:ok, %Tesla.Env{body: body, headers: resp_headers, status: 200}} ->
          conn = %Plug.Conn{conn | resp_headers: resp_headers}

          conn
          |> Conn.send_resp(200, body)
          |> Conn.halt()

        {:ok, %Tesla.Env{status: 500}} ->
          raise "Snowpack responded with error code: 500"

        _ ->
          conn
      end
    else
      conn
    end
  end

  defp serve_asset(conn = %Plug.Conn{}, _, _), do: conn
end
