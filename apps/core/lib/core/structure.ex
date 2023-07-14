defmodule Core.Structure do

  @typep error_reason :: String.t()

  @typedoc """
  Define error type which is a tuple of atom :error
  and error message
  """
  @type error :: {:error, error_reason()}

  @typedoc """
  Define success value type which is a tuple of atom :ok
  and any attached values
  """
  @type ok :: {:ok, any()}

  @typedoc """
  Define all possible types used as event's payload
  """
  @type event_types ::
    struct()
    | String.t()
    | atom()
    | map()
    | integer()
    | float()
    | list(any())

  @typedoc """
  Define an event type which is a tuple of atom :event
  with any struct value types
  """
  @type event :: {:event, String.t(), event_types()}

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
