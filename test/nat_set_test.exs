defmodule NatSetTest do
  use ExUnit.Case, async: true
  doctest NatSet

  alias NatSet, as: S

  test "compare efficiency of MapSets and NatSets" do
    max = 1_000

    {mus, map_set} = :timer.tc(fn -> Enum.into(1..max, MapSet.new) end)
    IO.puts("MapSet took #{mus |> secs} seconds and is #{map_set |> size_in_kb} kb")

    {mus, nat_set} = :timer.tc(fn -> Enum.into(1..max, NatSet.new) end)
    IO.puts("NatSet took #{mus |> secs} seconds and is #{nat_set |> size_in_kb} kb")
  end

  defp size_in_kb(term), do: :erts_debug.size(term) * :erlang.system_info(:wordsize) / 1024.0
  defp secs(mus), do: mus / 1_000_000

  # The following tests are adapted from Elixir's map_set_test.exs

  test "new/1" do
    assert S.equal?(S.new(1..5), make([1, 2, 3, 4, 5]))
  end

  test "new/2" do
    assert S.equal?(S.new(1..3, fn x -> 2 * x end), make([2, 4, 6]))
  end

  test "put" do
    assert S.equal?(S.put(S.new, 1), S.new([1]))
    assert S.equal?(S.put(S.new([1, 3, 4]), 2), S.new(1..4))
    assert S.equal?(S.put(S.new(5..100), 10), S.new(5..100))
  end

  test "union" do
    assert S.equal?(S.union(S.new([1, 3, 4]), S.new), S.new([1, 3, 4]))
    assert S.equal?(S.union(S.new(5..15), S.new(10..25)), S.new(5..25))
    assert S.equal?(S.union(S.new(1..120), S.new(1..100)), S.new(1..120))
  end

  test "intersection" do
    assert S.equal?(S.intersection(S.new, S.new(1..21)), S.new)
    assert S.equal?(S.intersection(S.new(1..21), S.new(4..24)), S.new(4..21))
    assert S.equal?(S.intersection(S.new(2..100), S.new(1..120)), S.new(2..100))
  end

  test "difference" do
    assert S.equal?(S.difference(S.new(2..20), S.new), S.new(2..20))
    assert S.equal?(S.difference(S.new(2..20), S.new(1..21)), S.new)
    assert S.equal?(S.difference(S.new(1..101), S.new(2..100)), S.new([1, 101]))
  end

  test "disjoint?" do
    assert S.disjoint?(S.new, S.new)
    assert S.disjoint?(S.new(1..6), S.new(8..20))
    refute S.disjoint?(S.new(1..6), S.new(5..15))
    refute S.disjoint?(S.new(1..120), S.new(1..6))
  end

  test "subset?" do
    assert S.subset?(S.new, S.new)
    assert S.subset?(S.new(1..6), S.new(1..10))
    assert S.subset?(S.new(1..6), S.new(1..120))
    refute S.subset?(S.new(1..120), S.new(1..6))
  end

  test "equal?" do
    assert S.equal?(S.new, S.new)
    refute S.equal?(S.new(1..20), S.new(2..21))
    assert S.equal?(S.new(1..120), S.new(1..120))
  end

  test "delete" do
    assert S.equal?(S.delete(S.new, 1), S.new)
    assert S.equal?(S.delete(S.new(1..4), 5), S.new(1..4))
    assert S.equal?(S.delete(S.new(1..4), 1), S.new(2..4))
    assert S.equal?(S.delete(S.new(1..4), 2), S.new([1, 3, 4]))
  end

  test "size" do
    assert S.size(S.new) == 0
    assert S.size(S.new(5..15)) == 11
    assert S.size(S.new(2..100)) == 99
  end

  test "to_list" do
    assert S.to_list(S.new) == []

    list = S.to_list(S.new(1..20))
    assert Enum.sort(list) == Enum.to_list(1..20)

    list = S.to_list(S.new(5..120))
    assert Enum.sort(list) == Enum.to_list(5..120)
  end

  defp make(collection), do: Enum.into(collection, S.new)
end
