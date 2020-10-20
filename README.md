# SnowpackStatic

Phoenix plug to proxy a locally running instance of the snowpack dev server.<br />
This plug will only serve assets when the env parameter has the value of `:dev`.<br />
Phoenix will be allowed a chance to resolve any assets not resolved by snowpack.<br />

## Installation

```elixir
defp deps do
  [
    {:snowpack_static_plug, "~> 0.3.0"}
  ]
end
```

And run:

\$ mix deps.get

## Usage

Add SnowpackStatic.Plug as a plug in the phoenix project's endpoint.

## Arguments

- **port** - _(required)_ The port that the snowpack dev server is listening on.
- **assets** - _(required)_ a list of the paths in the static folder that snowpack will for serve. The plug will ignore requests to any other path.
- **env** - _(required)_ the current environment the project is running under.

## Example

in `endpoint.ex`

```elixir
  plug SnowpackStatic.Plug,
    port: 8080,
    assets: ~w(public web_modules _dist_ __snowpack__),
    env: Mix.env()
```
