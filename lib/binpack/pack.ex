defmodule Binpack.Pack do
  alias __MODULE__
  alias Binpack.Container
  alias Binpack.Item

  defstruct containers: [],
            items: []

  @type t :: %__MODULE__{
          containers: list(Container.t()),
          items: list(Item.t())
        }

  @doc """
  Adds a possible container to the pack algorithm

  ## Examples

      iex> pack = %Binpack.Pack{}
      ...> pack.containers
      []
      iex> pack = Binpack.Pack.add_container(pack, %Binpack.Container{data: "1"})
      ...> pack = Binpack.Pack.add_container(pack, %Binpack.Container{data: "2"})
      ...> pack.containers
      [%Binpack.Container{data: "2"}, %Binpack.Container{data: "1"}]

  """
  @spec add_container(Pack.t(), Container.t()) :: Pack.t()
  def add_container(%Pack{} = pack, %Container{} = container),
    do: %Pack{pack | containers: [container | pack.containers]}

  @doc """
  Adds a packable item to the pack algorithm

  ## Examples

      iex> pack = %Binpack.Pack{}
      ...> pack.items
      []
      iex> pack = Binpack.Pack.add_item(pack, %Binpack.Item{data: "1"})
      ...> pack = Binpack.Pack.add_item(pack, %Binpack.Item{data: "2"})
      ...> pack.items
      [%Binpack.Item{data: "2"}, %Binpack.Item{data: "1"}]
  """
  @spec add_item(Pack.t(), Item.t()) :: Pack.t()
  def add_item(%Pack{} = pack, %Item{} = item), do: %Pack{pack | items: [item | pack.items]}
end
