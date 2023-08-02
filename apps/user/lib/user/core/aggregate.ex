defmodule User.Core.Aggregate do
  alias Core.Structure, as: CoreStructure
  alias Core.Event, as: CoreEvent
  alias User.Core.Aggregate
  alias User.Core.Aggregate.Event, as: UserEvent
  alias User.Core.Structure.Entity, as: UserEntity

  defstruct [:entity, :events]

  @typedoc """
  This is main aggregate map structure, any operation inside an aggregate must using
  this structure
  """
  @type t :: %__MODULE__{
    entity: ProductEntity.t() | nil,
    events: list(CoreStructure.event()),
  }

  defmodule Event do
    @moduledoc """
    Event used to describe all user's management. It describe per event names and it's payload
    """
    @event_user_registered :user_registered
    @event_user_modified :user_modified
    @event_user_deleted :user_deleted
    @error_invalid_user_type {:error, {:type, "invalid given user type"}}

    @doc """
    user_registered triggered when user successfully registered to system
    """
    @spec user_registered(user :: UserEntity.t()) :: {:ok, CoreStructure.event()} | CoreStructure.error()
    def user_registered(user) when is_struct(user), do: {:ok, {:event, @event_user_registered, user}}
    def user_registered(_), do: @error_invalid_user_type

    @doc """
    user_modified triggered when user successfully updated
    """
    @spec user_modified(user :: UserEntity.t()) :: {:ok, CoreStructure.event()} | CoreStructure.error()
    def user_modified(user) when is_struct(user), do: {:ok, {:event, @event_user_modified, user}}
    def user_modified(_), do: @error_invalid_user_type

    @doc """
    user_deleted triggered when user deleted from system
    """
    @spec user_deleted(user :: UserEntity.t()) :: {:ok, CoreStructure.event()} | CoreStructure.error()
    def user_deleted(user) when is_struct(user), do: {:ok, {:event, @event_user_deleted, user}}
    def user_deleted(_), do: @error_invalid_user_type
  end

  @aggregate_name :user
  @error_invalid_user_type {:error, {:user_type, "invalid user type"}}

  @doc """
  new/1 used to load an aggregate with given valid user's entity
  """
  @spec new(product :: UserEntity.t()) :: CoreStructure.aggregate()
  def new(user) do
    {:aggregate, @aggregate_name, %Aggregate{
      entity: user,
      events: []
    }}
  end

  @doc """
  new with empty parameter, new/0 used to generate
  """
  @spec new() :: CoreStructure.aggregate()
  def new() do
    {:aggregate, @aggregate_name, %Aggregate{}}
  end

  @spec create_new(agg :: tuple(), user :: UserEntity.new()) :: {:ok, CoreStructure.aggregate()} | CoreStructure.error()
  def create_new(agg, user) when is_tuple(agg) and is_map(user) do
    with {:ok, entity}  <- UserEntity.new(user),
         {:ok, event} <- UserEvent.user_registered(entity)
    do
      update_aggregate(agg, entity, event)
    else
      err -> err
    end
  end

  @spec aggregate(agg :: CoreStructure.aggregate()) :: {:ok, t()} | CoreStructure.error()
  def aggregate(agg) when is_tuple(agg) do
    try do
      elem(agg, 2)
    rescue
      e in ArgumentError -> {:error, {:exception, e.message}}
    end
  end

  @spec entity(agg :: t()) :: UserEntity.t()
  def entity(agg), do: agg.entity

  @spec update_aggregate(agg :: CoreStructure.aggregate(), entity :: UserEntity.t(), event :: CoreStructure.event()) :: {:ok, CoreStructure.aggregate()} | CoreStructure.error()
  defp update_aggregate(agg, entity, event)
        when is_tuple(agg)
        and is_struct(entity)
        and is_tuple(event) do

    out_agg = agg |> aggregate
    case out_agg do
      {:ok, user} ->
        out =
          %{user | entity: entity, events: CoreEvent.add_event(user.events, event)}
        {:ok, {:aggregate, @aggregate_name, out}}
      _ ->
        out_agg
    end

  end

  @spec update_aggregate(any(), any(), any()) :: CoreStructure.error()
  defp update_aggregate(_, _, _), do: @error_invalid_user_type
end
