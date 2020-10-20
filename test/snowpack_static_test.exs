defmodule SnowpackStaticTest do
  @moduledoc false
  use ExUnit.Case
  use Plug.Test
  alias Plug.Conn, as: Conn
  alias SnowpackStatic.Plug, as: Plugin

  @opts [
    env: :dev,
    port: 9000,
    assets: ~w(js css)
  ]

  @req_body "() => {}"

  setup do
    bypass = Bypass.open(port: @opts[:port])
    {:ok, bypass: bypass}
  end

  test "will not serve file when env is not dev" do
    opts =
      @opts
      |> Keyword.merge(env: :test)
      |> Plugin.init()

    conn =
      conn(:get, "/js/test.js", nil)
      |> put_req_header("accept", "application/javascript")
      |> Plugin.call(opts)

    assert conn.halted == false
    assert conn.state == :unset
    assert conn.status == nil
  end

  test "will pass conn to next plug if snowpack asset is not resolved", %{bypass: bypass} do
    requested_resouce_path = "/js/test.js"

    opts = Plugin.init(@opts)

    Bypass.expect_once(bypass, "GET", requested_resouce_path, fn conn ->
      Conn.resp(conn, 404, "Not Found")
    end)

    conn =
      conn(:get, requested_resouce_path, nil)
      |> put_req_header("accept", "application/javascript")
      |> Plugin.call(opts)

    assert conn.halted == false
    assert conn.state == :unset
    assert conn.status == nil
  end

  test "will return http status code when an error code is returned from snowpack", %{
    bypass: bypass
  } do
    requested_resouce_path = "/js/test.js"

    opts = Plugin.init(@opts)

    Bypass.expect_once(bypass, "GET", requested_resouce_path, fn conn ->
      Conn.resp(conn, 500, "Internal Server Error")
    end)

    assert_raise RuntimeError, ~r/^Snowpack responded with error code: 500/, fn ->
      conn(:get, requested_resouce_path, nil)
      |> put_req_header("accept", "application/javascript")
      |> Plugin.call(opts)
    end
  end

  test "will pass conn to next plug if requested path is not white listed" do
    requested_resouce_path = "/img/test.jpg"

    opts = Plugin.init(@opts)

    conn =
      conn(:get, requested_resouce_path, nil)
      |> put_req_header("accept", "application/javascript")
      |> Plugin.call(opts)

    assert conn.halted == false
    assert conn.state == :unset
    assert conn.status == nil
  end

  test "will set resp headers to whatever headers snowpack returns", %{bypass: bypass} do
    requested_resouce_path = "/js/test.js"

    opts = Plugin.init(@opts)

    Bypass.expect_once(bypass, "GET", requested_resouce_path, fn conn ->
      conn
      |> Conn.put_resp_header("x-test", "I worked")
      |> Conn.resp(200, @req_body)
    end)

    conn =
      conn(:get, requested_resouce_path, nil)
      |> put_req_header("accept", "application/javascript")
      |> Plugin.call(opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == @req_body
    assert conn.halted == true

    [header_value] = Conn.get_resp_header(conn, "x-test")

    assert header_value == "I worked"
  end
end
