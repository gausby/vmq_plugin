defmodule VmqPlugin do
  @moduledoc """

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
  Grant or reject new client connections. Besides working as a application
  level firewall it can also alter the configuration of the client.
  """
  @callback auth_on_register(peer, subscriber_id, username, password, clean_session :: flag) ::
    :ok | {:ok, [reg_modifier]} |
    {:error, :invalid_credentials | reason :: binary} |
    :next

  @doc """
  During `on_register` detailed information can be gathered about the client
  """
  @callback on_register(peer, subscriber_id, username) :: any

  @doc """
  Called after the client has been successfully authenticated, and after the
  `auth_on_register/5` and `on_rigister/3`; after the queue has been attached
  to--and offline messages has been migrated and dublicate sessions has been
  disconnected.

  This hook can hang for a bit if the client uses `clean_session=false` or
  if the client had a previous session in the VerneMQ cluster (messages has
  to be moved between nodes).
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
  @callback auth_on_subscribe(username, subscriber_id, topics) ::
    :ok | {:ok, topics} |
    {:error, reason :: any} |
    :next

  @callback on_subscribe(username, subscriber_id, topics) :: any

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

  @callback auth_on_publish(username, subscriber_id, qos, topic, payload, is_retain :: flag) ::
    :ok | {:ok, payload | [msg_modifier]} |
    {:error, reason :: any} |
    :next

  @callback on_publish(username, subscriber_id, qos, topic, payload, is_retain :: flag) :: any

  @callback on_offline_message(subscriber_id) :: any

  @type msg_deliver_modifier ::
    {:topic, topic} |
    {:payload, payload}

  @callback on_deliver(username, subscriber_id, topic, payload) ::
    :ok | {:ok, payload | [msg_deliver_modifier]}
    :next

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour unquote(__MODULE__)

      @doc false
      def auth_on_register({_ipaddr, _port}, _subscriber_id, _username, _password, _cleansession),
        do: :next

      @doc false
      def on_register(_peer, _subscriber_id, _username),
        do: nil

      @doc false
      def on_client_wakeup(_subscriber_id),
        do: nil

      @doc false
      def on_client_offline(_subscriber_id),
        do: nil

      @doc false
      def on_client_gone(_subscriber_id),
        do: nil

      @doc false
      def auth_on_subscribe(_username, _client_id, _topics),
        do: :next

      @doc false
      def on_subscribe(_username, _subscriber_id, _topics),
        do: nil

      @doc false
      def on_unsubscribe(_username, _subscriber_id, _topics),
        do: :next

      @doc false
      def auth_on_publish(_username, _subscriber_id, _qos, _topic, _payload, _is_retain),
        do: :next

      @doc false
      def on_publish(_username, _subscriber_id, _qos, _topic, _payload, _is_retain),
        do: nil

      @doc false
      def on_offline_message(_subscriber_id),
        do: nil

      @doc false
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
