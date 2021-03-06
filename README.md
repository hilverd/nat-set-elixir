# NatSet

[![Build Status](https://api.travis-ci.org/hilverd/nat-set-elixir.svg?branch=master)](https://travis-ci.org/hilverd/nat-set-elixir)
[![Hex.pm](https://img.shields.io/hexpm/v/nat_set.svg?style=flat-square)](https://hex.pm/packages/nat_set)
[![Hex.pm](https://img.shields.io/hexpm/dt/nat_set.svg?style=flat-square)](https://hex.pm/packages/nat_set)

This is an Elixir library for working with sets of natural numbers (i.e. non-negative integers). It
uses [bitsets](https://en.wikipedia.org/wiki/Bit_array) to represent such sets much more compactly
than you would get when using standard MapSets.

Documentation: http://hexdocs.pm/nat_set.

## Usage

1. Add `nat_set` to your list of dependencies in `mix.exs`:

    ``` elixir
    def deps do
      [{:nat_set, "~> 0.0.1"}]
    end
    ```

2. Ensure `nat_set` is started before your application:

    ``` elixir
    def application do
      [applications: [:nat_set]]
    end
    ```

## Examples

Start an interactive Elixir shell with `iex -S mix`.

``` elixir
iex> NatSet.new([1, 2, 0, 1, 3])
#NatSet<[0, 1, 2, 3]>

iex> multiples_of_4 = 1..100_000 |> Enum.filter(&rem(&1, 4) == 0) |> NatSet.new
#NatSet<[4, 8, 12, 16, 20, ...]>

iex> multiples_of_6 = 1..100_000 |> Enum.filter(&rem(&1, 6) == 0) |> NatSet.new
#NatSet<[6, 12, 18, 24, 30, ...]>

iex> NatSet.intersection(multiples_of_4, multiples_of_6) |> NatSet.size
8333
```

See the [documentation](http://hexdocs.pm/nat_set) for more available functionality.

## Benchmarks

The following test gives a rough idea of how NatSet's performance compares to that of MapSet for
storing natural numbers.

``` elixir
test "compare efficiency of MapSets and NatSets" do
  max = 100_000

  {mus, map_set} = :timer.tc(fn -> Enum.into(1..max, MapSet.new) end)
  IO.puts("MapSet took #{mus |> secs} seconds and is #{map_set |> size_in_kb} kb")

  {mus, nat_set} = :timer.tc(fn -> Enum.into(1..max, NatSet.new) end)
  IO.puts("NatSet took #{mus |> secs} seconds and is #{nat_set |> size_in_kb} kb")
end

defp size_in_kb(term), do: :erts_debug.size(term) * :erlang.system_info(:wordsize) / 1024.0
defp secs(mus), do: mus / 1_000_000
```

This produced the following on my machine:

```
MapSet took 0.06468 seconds and is 2947.375 kb
NatSet took 0.043118 seconds and is 26.7890625 kb
```

### Results

The results below are produced by [Benchfella](https://github.com/alco/benchfella) using the tests
in
[`nat_set_bench.exs`](https://github.com/hilverd/nat-set-elixir/blob/master/bench/nat_set_bench.exs).

```
difference using NatSet          100000   15.28 µs/op
difference using MapSet            2000   897.59 µs/op

disjoint? using NatSet         10000000   0.87 µs/op
disjoint? using MapSet            50000   34.60 µs/op

equal? using NatSet           100000000   0.06 µs/op
equal? using MapSet           100000000   0.06 µs/op

intersection using NatSet        100000   16.00 µs/op
intersection using MapSet          5000   389.47 µs/op

member? using NatSet               1000   2336.44 µs/op
member? using MapSet               1000   1307.68 µs/op

put and delete using NatSet         500   5381.54 µs/op
put and delete using MapSet         500   5378.17 µs/op

size using NatSet                   500   3163.51 µs/op
size using MapSet             100000000   0.03 µs/op

subset? using NatSet             500000   7.47 µs/op
subset? using MapSet               5000   302.90 µs/op

union using NatSet               100000   12.55 µs/op
union using MapSet                20000   86.31 µs/op
```
