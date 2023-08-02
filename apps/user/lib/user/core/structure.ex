defmodule User.Structure do

  defmodule Password do
    @moduledoc """
    Password is a value object used to hash and check
    for given raw validation
    """

    @typedoc """
    raw is a given value in raw format, which mean it
    still not hashed yet
    """
    @type raw :: String.t()

    @typedoc """
    hashed is form of string that already hashed
    """
    @type hashed :: String.t()

    @doc """
    new used to initiate Password value, for the first time
    the initiation value will be in raw format, this raw will be
    used to hash or to compare with other hashed format
    """
    @spec new(raw()) :: hashed()
    def new(raw), do: raw

    @doc """
    hash used to start hashing given raw format, it can be used as pipelining
    from new method

    ## Examples

        iex> Password.new("hello world") |> hash
        "hashedvalue"

    """
    @spec hash(raw()) :: hashed()
    def hash(raw) do
      :crypto.hash(:sha256, raw)
      |> Base.encode16()
      |> String.downcase()
    end

    @doc """
    is_valid? used to compare given string in raw format with another hashed format
    by hashing given raw value first

    ## Examples

        iex> Password.new("hello world") |> is_valid?("hashedexample")
        false

    """
    @spec is_valid?(raw(), hashed()) :: boolean()
    def is_valid?(raw, hashed) do
      raw
      |> hash()
      |> compare(hashed)
    end

    @spec compare(hashed(), hashed()) :: boolean()
    defp compare(raw_hashed, hashed), do: raw_hashed == hashed
  end

  defmodule Entity do
    @moduledoc """
    Entity is a main User's entity structure it describe user's properties
    and also act as User's root aggregate
    """
    alias Core.Structure
    alias Core.Structure.Id
    alias User.Structure.Password

    @enforce_keys [:id, :name, :email, :password, :created_at]
    defstruct [:id, :name, :email, :password, :created_at, :updated_at]

    @error_validation_not_passed {:error, "invalid given new user structure"}

    @typedoc """
    Define main entity properties of the user
    """
    @type t :: %__MODULE__{
      id: Id.t(),
      name: String.t(),
      email: String.t(),
      password: Password.hashed(),
      created_at: DateTime.t(),
      updated_at: DateTime.t() | nil
    }

    @typedoc """
    new_user used as a initial user's inputs when they want to create a new entity
    """
    @type new_user :: %{
      required(:name) => String.t(),
      required(:email) => String.t(),
      required(:password) => Password.raw()
    }

    @doc """
    new used to generate new user's entity. It will generate User's entity
    including for it's id and created_at
    """
    @spec new(user :: new_user()) :: t() | Structure.error()
    def new(user) when is_map(user) do

      validation_result =
        user
        |> validate_new_user()

      with user_validated <- validation_result,
            uid <- Id.new()
      do
        %Entity{
          id: uid,
          name: user_validated.name,
          email: user_validated.email,
          password: Password.new(user_validated.password) |> Password.hash,
          created_at: DateTime.utc_now()
        }
      else
        err -> err
      end

    end

    @spec validate_new_user(user :: new_user()) :: new_user() | Structure.error()
    defp validate_new_user(user) when is_map(user) do

      required_keys =
        [:name, :email, :password]
        |> Enum.reject(fn key -> Map.has_key?(user, key) end)
        |> Enum.empty?()

      case required_keys do
        false -> @error_validation_not_passed
        true -> user
      end
    end

  end

  defmodule Event do
    @moduledoc """
    Event used to describe all user's management. It describe per event names and it's payload
    """
    alias Core.Structure, as: CoreStructure
    alias User.Structure.Entity, as: UserEntity

    @error_invalid_user_type "invalid given user type"

    @doc """
    user_registered triggered when user successfully registered to system
    """
    @spec user_registered(user :: UserEntity.t()) :: CoreStructure.event() | CoreStructure.error()
    def user_registered(user) when is_struct(user), do: {:event, :user_registered, user}
    def user_registered(_), do: {:error, @error_invalid_user_type}

    @doc """
    user_logged_in triggered when user successfully loggedi in to system
    """
    @spec user_logged_in(user :: UserEntity.t()) :: CoreStructure.event() | CoreStructure.error()
    def user_logged_in(user) when is_struct(user), do: {:even, :user_logged_in, user}
    def user_logged_in(_), do: {:error, @error_invalid_user_type}

    @spec user_modified(user :: UserEntity.t()) :: CoreStructure.event() | CoreStructure.error()
    def user_modified(user) when is_struct(user), do: {:event, :user_modified, user}
    def user_modified(_), do: {:error, @error_invalid_user_type}

    @doc """
    user_deleted triggered when user deleted from system
    """
    @spec user_deleted(user :: UserEntity.t()) :: CoreStructure.event() | CoreStructure.error()
    def user_deleted(user) when is_struct(user), do: {:event, :user_deleted, user}
    def user_deleted(_), do: {:error, @error_invalid_user_type}
  end

end
