defmodule NatSetBench do
  use Benchfella

  @max 10_000

  @list 1..@max
  @list3 Enum.filter(@list, &rem(&1, 3) == 0)
  @list4 Enum.filter(@list, &rem(&1, 4) == 0)
  @list5 Enum.filter(@list, &rem(&1, 5) == 0)

  @nat_set NatSet.new(@list)
  @nat_set3 NatSet.new(@list3)
  @nat_set4 NatSet.new(@list4)
  @nat_set5 NatSet.new(@list5)

  @map_set MapSet.new(@list)
  @map_set3 MapSet.new(@list3)
  @map_set4 MapSet.new(@list4)
  @map_set5 MapSet.new(@list5)

  bench "put and delete using NatSet", do: put_and_delete(NatSet)
  bench "put and delete using MapSet", do: put_and_delete(MapSet)

  bench "difference using NatSet", do: NatSet.difference(@nat_set, @nat_set3)
  bench "difference using MapSet", do: MapSet.difference(@map_set, @map_set3)

  bench "disjoint? using NatSet", do: NatSet.disjoint?(@nat_set3, @nat_set5)
  bench "disjoint? using MapSet", do: MapSet.disjoint?(@map_set3, @map_set5)

  bench "equal? using NatSet", do: NatSet.equal?(@nat_set3, @nat_set3)
  bench "equal? using MapSet", do: MapSet.equal?(@map_set3, @map_set3)

  bench "intersection using NatSet", do: NatSet.intersection(@nat_set3, @nat_set4)
  bench "intersection using MapSet", do: MapSet.intersection(@map_set3, @map_set4)

  bench "member? using NatSet", do: Enum.map(@list, &NatSet.member?(@nat_set3, &1))
  bench "member? using MapSet", do: Enum.map(@list, &MapSet.member?(@map_set3, &1))

  bench "size using NatSet", do: NatSet.size(@nat_set)
  bench "size using MapSet", do: MapSet.size(@map_set)

  bench "subset? using NatSet", do: NatSet.subset?(@nat_set3, @nat_set)
  bench "subset? using MapSet", do: MapSet.subset?(@map_set3, @map_set)

  bench "union using NatSet", do: NatSet.union(@nat_set3, @nat_set4)
  bench "union using MapSet", do: MapSet.union(@map_set3, @map_set4)

  defp put_and_delete(set_module) do
    all = @list |> Enum.reduce(set_module.new, fn n, result -> set_module.put(result, n) end)
    Enum.reduce(@list3, all, fn n, result -> set_module.delete(result, n) end)
  end
end
