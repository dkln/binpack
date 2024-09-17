defmodule BinpackTest do
  use ExUnit.Case

  doctest Binpack

  alias Binpack.Container
  alias Binpack.Item
  alias Binpack.Pack

  describe "pack/1" do
    test "pack one container" do
      item_1 = %Item{width: 5, height: 2, depth: 3, data: "1", weight: 1}
      item_2 = %Item{width: 6, height: 5, depth: 4, data: "2", weight: 2}
      item_3 = %Item{width: 7, height: 4, depth: 2, data: "3", weight: 3}

      container = %Container{width: 50, height: 50, depth: 50, data: "big box", max_weight: 50}

      pack =
        %Pack{}
        |> Pack.add_container(container)
        |> Pack.add_item(item_1)
        |> Pack.add_item(item_2)
        |> Pack.add_item(item_3)

      assert Binpack.pack(pack) == []
    end
  end
end
