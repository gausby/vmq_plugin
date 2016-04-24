defmodule VmqPlugin do
  @moduledoc """
  Defines callbacks for writing plugins for the VerneMQ MQTT message
  broker. Please refer to the official documentation on plugin
  development: https://vernemq.com/docs/plugindevelopment/
  """

  @type peer :: {:inet.ip_address(), :inet.port_number()}
  @type username :: binary | :undefined
  @type password :: binary | :undefined
  @type client_id :: binary
  @type mountpoint :: char_list
  @type subscriber_id :: {mountpoint, client_id}
  @type reg_view :: atom
  @type topic :: [binary]
  @type qos :: 0 | 1 | 2
  @type routing_key :: [binary]
  @type payload :: binary
  @type flag :: boolean

  @type topics :: [{topic, qos}]

  # session life cycle -------------------------------------------------
  @type reg_modifier ::
    {:mountpoint, mountpoint} |
    {:subscriber_id, subscriber_id} |
    {:reg_view, reg_view} |
    {:clean_session, flag} |
    {:max_message_size, non_neg_integer} |
    {:max_message_rate, non_neg_integer} |
    {:max_inflight_messages, non_neg_integer} |
    {:retry_interval, pos_integer} |
    {:upgrade_qos, boolean} |
    {:trade_consistency, boolean}

  @doc """
  Grant or reject new client connections. Besides working as a
  application level firewall it can also alter the configuration of the
  client.
  """
  @callback auth_on_register(peer, subscriber_id, username, password, clean_session :: flag) ::
    :ok | {:ok, [reg_modifier]} |
    {:error, :invalid_credentials | reason :: binary} |
    :next

  @doc """
  During `on_register` detailed information can be gathered about the
  client
  """
  @callback on_register(peer, subscriber_id, username) :: any

  @doc """
  Called after the client has been successfully authenticated, and after
  the `auth_on_register/5` and `on_register/3`; after the queue has been
  attached to--and offline messages has been migrated and dublicate
  sessions has been disconnected.

  This hook can hang for a bit if the client uses `clean_session=false`
  or if the client had a previous session in the VerneMQ cluster--in
  which case messages has to be moved between nodes.
  """
  @callback on_client_wakeup(subscriber_id) :: any

  @doc """
  **This hook is only called if the client uses `clean_session=false`**

  Triggered when the connection is closed or the client is disconnected
  because of a dublicate session.
  """
  @callback on_client_offline(subscriber_id) :: any

  @doc """
  **This hook is only called if the client uses `clean_session=true`**

  Triggered when the connection is closed or the client is disconnected
  because of a dublicate session.
  """
  @callback on_client_gone(subscriber_id) :: any

  # subscribe flow -----------------------------------------------------
  @doc """
  Allow the plugin to grand or reject subscribe requests sent by a
  client, as well as rewrite the subscribe topic and quality of service.
  """
  @callback auth_on_subscribe(username, subscriber_id, topics) ::
    :ok | {:ok, topics} |
    {:error, reason :: any} |
    :next

  @doc """
  Called on every subscribe request that has been authorized.
  """
  @callback on_subscribe(username, subscriber_id, topics) :: any

  @doc """
  Called on every unsubscribe request and allow the plugin author to
  rewrite the unsubscribe topic.
  """
  @callback on_unsubscribe(username, subscriber_id, topics) ::
    :ok | {:ok, topics} |
    :next

  # publish flow -------------------------------------------------------
  @type msg_modifier ::
    {:topic, topic} |
    {:payload, payload} |
    {:reg_view, reg_view} |
    {:qos, qos} |
    {:retain, flag} |
    {:mountpoint, mountpoint}

  @doc """
  Grand or reject publish requests sent by a client. It is also possible
  to rewrite the publish topic, payload, quality of service or retain
  flag.

  If this hook is defined it will become part of a conditional plugin
  chain; if the plugin cannot validate the publish message it is best to
  pass the message on to the next plugin implementing `auth_on_publish`
  by returning `:next`. If none of the plugins accept the message it
  will get rejected.
  """
  @callback auth_on_publish(username, subscriber_id, qos, topic, payload, is_retain :: flag) ::
    :ok | {:ok, payload | [msg_modifier]} |
    {:error, reason :: any} |
    :next

  @doc """
  Called on every authorized publish message.
  """
  @callback on_publish(username, subscriber_id, qos, topic, payload, is_retain :: flag) :: any

  @doc """
  Called every time a message going to a currently offline client is
  queued.
  """
  @callback on_offline_message(subscriber_id) :: any

  @type msg_deliver_modifier ::
    {:topic, topic} |
    {:payload, payload}

  @doc """
  Called on every outgoing publish message, and allow the plugin to
  rewrite the `topic` and/or `payload`.
  """
  @callback on_deliver(username, subscriber_id, topic, payload) ::
    :ok | {:ok, payload | [msg_deliver_modifier]}
    :next

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour unquote(__MODULE__)

      def auth_on_register({_ipaddr, _port}, _subscriber_id, _username, _password, _cleansession),
        do: :next

      def on_register(_peer, _subscriber_id, _username),
        do: nil

      def on_client_wakeup(_subscriber_id),
        do: nil

      def on_client_offline(_subscriber_id),
        do: nil

      def on_client_gone(_subscriber_id),
        do: nil

      def auth_on_subscribe(_username, _client_id, _topics),
        do: :next

      def on_subscribe(_username, _subscriber_id, _topics),
        do: nil

      def on_unsubscribe(_username, _subscriber_id, _topics),
        do: :next

      def auth_on_publish(_username, _subscriber_id, _qos, _topic, _payload, _is_retain),
        do: :next

      def on_publish(_username, _subscriber_id, _qos, _topic, _payload, _is_retain),
        do: nil

      def on_offline_message(_subscriber_id),
        do: nil

      def on_deliver(_username, _subscriber_id, _topic, _payload),
        do: :next

      defoverridable [
        auth_on_register: 5, on_register: 3,
        on_client_wakeup: 1, on_client_offline: 1, on_client_gone: 1,

        auth_on_subscribe: 3,
        on_subscribe: 3, on_unsubscribe: 3,

        auth_on_publish: 6,
        on_publish: 6, on_offline_message: 1, on_deliver: 4]
    end
  end
end
