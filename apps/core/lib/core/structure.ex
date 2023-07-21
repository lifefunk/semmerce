defmodule Core.Structure do

  @typep error_reason :: String.t()
  @typep error_type :: atom()

  @typedoc """
  Define error type which is a tuple of atom :error
  and error message
  """
  @type error :: {:error, {error_type(), error_reason()}}

  @typedoc """
  Define success value type which is a tuple of atom :ok
  and any attached values
  """
  @type ok :: {:ok, any()}

  @typedoc """
  Define all possible types used as event's payload
  """
  @type event_payload ::
    struct()
    | String.t()
    | atom()
    | map()
    | integer()
    | float()
    | list(any())

  @typedoc """
  Define type of event_name, it can be string or an atom
  Example:
    {:event, :event_name, 1}
    {:event, "event_name", %{}}
  """
  @type event_name :: String.t() | atom()

  @typedoc """
  Define an event type which is a tuple of atom :event
  with any struct value types
  """
  @type event :: {:event, event_name(), event_payload()}

  @typedoc """
  Define a result of some process with return success (ok) and
  also return the process events. This type will be useful in
  Aggregate things
  """
  @type ok_with_event :: {:ok_with_event, any(), event()}

  @typedoc """
  Define specific aggregate name
  """
  @type aggregate_name :: String.t() | atom()

  @typedoc """
  Define a payload type for aggregate data structure
  """
  @type aggregate_payload :: struct() | map() | nil

  @typedoc """
  Define a structure of aggregate data structure, it contains
  only for specific entity which is a struct and a list unpublished
  events
  """
  @type aggregate :: {:aggregate, aggregate_name(), aggregate_payload()}

  defmodule Function.Builder do
    @moduledoc """
    Function.Builder supposed to be as a "standard"
    to build all *critical* functions like usecase modules.

    This builder give us a helpers, such as for function's dependencies
    """

    defmodule Dependency do
      @moduledoc """
      Provide a mechanism like DI (Dependency Injection). In OOP languages,
      we can set the dependencies once and store it into object's states.

      But in functional languages, like Elixir, there are no internal states
      (well actually it has, but it's not supposed to be like that). I'm prefer to
      using function dependencies which pass it as function parameters rather than
      using config, especially if we want to create a flexible library

      To make it standard, I think I need this helper. A 'Dependency` module actually
      is just a simple struct contains of `deps` and `options`, where a `deps` can be
      a struct or map, it depends on your needs
      """

      @enforce_keys [:deps]
      defstruct [:deps, :options]

      @typedoc """
      Define an "object" dependencies, any value that needed by your function, for example
      like behaviour implementation, you can store it into some structs or maps
      """
      @type objects :: module() | struct() | map()
      @type options :: keyword() | nil

      @type t :: %__MODULE__{
        deps: objects(),
        options: options()
      }
    end

  end

  defmodule Id do
    @moduledoc """
    Id is a value object specific for unique id. Actually it is just
    a string of UUID but has been modified to be more short and can be
    decoded back to it's original format
    """
    alias User.Structure

    @typedoc """
    It's base original type of this value object, it is a String
    """
    @type t :: String.t()

    @doc """
    Generate new UUID and pipe it to ShortUUID for more compact format
    """
    @spec new() :: t() | Structure.error()
    def new() do
      out = UUID.uuid4() |> ShortUUID.encode()
      case out do
        {:ok, uid} -> uid
        _ -> out
      end
    end

    @doc """
    Decode given shorted uid to it's original format, which is UUID
    """
    @spec decode(shorted :: String.t()) :: t() | Structure.error()
    def decode(shorted) do
      out = shorted |> ShortUUID.decode()
      case out do
        {:ok, original} -> original
        _ -> out
      end
    end
  end
end
