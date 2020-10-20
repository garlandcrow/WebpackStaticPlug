defmodule WebpackStatic.Plug do
  @moduledoc """
  Phoenix plug to proxy a locally running instance of the webpack dev server.<br />
  This plug will only serve assets when the env parameter has the value of `:dev`.<br />
  Phoenix will be allowed a chance to resolve any assets not resolved by webpack.<br />

  ## Installation

  ```
  defp deps do
    [
      {:WebpackStaticPlug, "~> 0.1.1"}
    ]
  end
  ```

  And run:

    $ mix deps.get

  ## Usage
  Add WebpackStatic.Plug as a plug in the phoenix project's endpoint.

  ## Arguments
  * **port** - *(required)* The port that the webpack dev server is listening on.
  * **webpack_assets** - *(required)* a list of the paths in the static folder that webpack will for serve. The plug will ignore requests to any other path.
  * **env** - *(required)* the current environment the project is running under.
  * **manifest_path** - *(optional)* relative path that will resolve from the static folder of the webpack manifest file.

  ## Example
    in `endpoint.ex`

    ```
      plug WebpackStatic.Plug,
            port: 9000, webpack_assets: ~w(css fonts images js),
            env: Mix.env, manifest_path: "/manifest.json"
    ```
  """
  alias HTTPotion, as: Http
  alias Plug.Conn, as: Conn
  require Poison

  @doc false
  def init(args) do
    List.keysort(args, 0)
  end

  @doc false
  def call(conn, [
        {:env, env},
        {:manifest_path, manifest_path},
        {:port, port},
        {:webpack_assets, assets}
      ]) do
    if env == :dev do
      manifest_task = Task.async(fn -> get_manifest(manifest_path, port) end)
      manifest = Task.await(manifest_task)

      case manifest do
        {:error, message} -> raise message
        {:ok, manifest} -> serve_asset(conn, port, assets, manifest)
        nil -> serve_asset(conn, port, assets, nil)
      end
    else
      conn
    end
  end

  defp get_manifest(path, port) when is_binary(path) do
    url =
      "http://localhost:#{port}"
      |> URI.merge(path)
      |> URI.to_string()

    response = Http.get(url, headers: [Accept: "application/json"])

    case response do
      %HTTPotion.Response{status_code: code} when code == 404 ->
        {:error, "Error: could not find manifest located at #{url}"}

      %HTTPotion.Response{body: body, status_code: code} when code >= 400 ->
        {:error, "Error: fetching manifest, status:#{code} body:#{body}"}

      %HTTPotion.Response{body: body} ->
        Poison.decode(body)

      %HTTPotion.ErrorResponse{message: message} ->
        {:error, "Error: fetching manifest: #{message}"}
    end
  end

  defp get_manifest(_, _), do: nil

  defp serve_asset(
         conn = %Plug.Conn{
           path_info: [uri | path_parts],
           req_headers: req_headers
         },
         port,
         assets,
         manifest
       ) do
    requested_path = "#{uri}/#{Enum.join(path_parts, "/")}"

    actual_path =
      case manifest do
        %{^requested_path => value} -> value
        _ -> requested_path
      end

    url =
      "http://localhost:#{port}"
      |> URI.merge(actual_path)
      |> URI.to_string()

    asset_type =
      uri
      |> String.split("/")
      |> hd

    if Enum.any?(assets, &(&1 == asset_type)) do
      require Logger
      Logger.warn(inspect(url, pretty: true))

      # TODO: maybe put back headers: req_headers
      %Tesla.Env{body: body, headers: resp_headers, status: status} = Tesla.get!(url)

      conn = %Plug.Conn{conn | resp_headers: resp_headers}

      conn
      |> Conn.send_resp(status, body)
      |> Conn.halt()
    else
      conn
    end
  end

  defp serve_asset(conn = %Plug.Conn{}, _, _, _), do: conn
end
