# VmqPlugin

*work in progress*

An unofficial helper behaviour for creating plugins for the [VerneMQ](https://vernemq.com/) MQTT message broker. As of yet it provide specs for the callback hooks which aids editor integrations and the dialyzer software.


## Setting up a VerneMQ Plugin in mix.exs
You will still need to register the callbacks you implement to the environment, this can be done like so in the project *mix.exs*-file:

``` elixir
def application do
  [applications: [:elixir],
   env: [vmq_plugin_hooks]]
end

defp vmq_plugin_hooks do
  {:vmq_plugin_hooks, [{Elixir.VmqElixirPlugin,:auth_on_subscribe,3,[]},
                       {Elixir.VmqElixirPlugin,:auth_on_register,5,[]},
                       {Elixir.VmqElixirPlugin,:auth_on_publish,6,[]}]}
end
```

Only the relevant parts are shown. Remember to start Elixir as an application.


## Installation

Add vmq_plugin to your list of dependencies in `mix.exs`:

``` elixir
def deps do
  [{:vmq_plugin, github: "gausby/vmq_plugin"}]
end
```
