Code.compile_file("benchmarks/simple.ex")

as = Enum.to_list(1..10_000)
bs = Enum.to_list(1..10_000)
input_list = Enum.zip(as, bs)

Benchee.run(
  %{
    "add with TypeCheck" => fn -> Enum.map(input_list, fn {a, b} -> Addition.add(a, b) end) end,
    "baseline add" => fn -> Enum.map(input_list, fn {a, b} -> Addition.baseline_add(a, b) end) end,
  },
  time: 10,
  memory_time: 2
)
