defmodule Product.Category.Core.Structure do
  defmodule Entity do
    @moduledoc """
    This is a main entity for product's category. A product
    will be related to some category. Category will have many products, from
    database perspective
    """
    alias Core.Structure, as: CoreStructure
    alias Core.Structure.Id, as: CoreId

    @enforce_keys [:id, :name, :created_at]
    defstruct [:id, :name, :desc, :created_at, :updated_at]

    @error_validation_not_passed {:error, "invalid given new category structure"}
    @error_invalid_category_type {:error, "invalid given category type"}

    @typedoc """
    Main type for category entity
    """
    @type t :: %__MODULE__{
      id: CoreId.t(),
      name: String.t(),
      desc: String.t(),
      created_at: DateTime.t(),
      updated_at: DateTime.t() | nil
    }

    @typedoc """
    new_category is a given payload to create category's entity
    """
    @type new_category :: %{
      required(:name) => String.t(),
      optional(:desc) => String.t()
    }

    @type state_changes :: {:ok, t()} | CoreStructure.error()

    @doc """
    Create Category entity from given new_category payload. It will return
    an entity or an error tuple
    """
    @spec new(category :: new_category()) :: state_changes()
    def new(category) when is_map(category) do
      validation_result =
        category
        |> validate_new_category()

        with category_validated <- validation_result,
            uid <- CoreId.new()
        do
          entity = %Entity{
            id: uid,
            name: category_validated.name,
            desc: Map.get(category, :desc),
            created_at: DateTime.utc_now()
          }

          {:ok, entity}
        else
          err -> err
        end
    end

    @spec change_name(category :: t(), name :: String.t()) :: {:ok, t()}
    def change_name(category, name) when is_struct(category) and is_binary(name) do
      out =
        %{category | name: name}
        |> Map.update(:updated_at, DateTime.utc_now(), fn _ -> DateTime.utc_now() end)

      {:ok, out}
    end

    @spec change_name(any(), any()) :: CoreStructure.error()
    def change_name(_, _), do: @error_invalid_category_type

    @spec change_desc(category :: t(), desc :: String.t()) :: {:ok, t()}
    def change_desc(category, desc) when is_struct(category) and is_binary(desc) do
      out =
        %{category | desc: desc}
        |> Map.update(:updated_at, DateTime.utc_now(), fn _ -> DateTime.utc_now() end)

      {:ok, out}
    end

    @spec change_desc(any(), any()) :: CoreStructure.error()
    def change_desc(_, _), do: @error_invalid_category_type

    @spec validate_new_category(category :: new_category()) :: new_category() | CoreStructure.error()
    defp validate_new_category(category) when is_map(category) do
      required_keys =
        [:name]
        |> Enum.reject(fn key -> Map.has_key?(category, key) end)
        |> Enum.empty?()

      case required_keys do
        false -> {:error, @error_validation_not_passed}
        true -> category
      end
    end
  end
end
