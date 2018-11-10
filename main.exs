[inputPath | tail] = System.argv

IO.puts "Processing input at #{inputPath}"
orders = Omise.get_json(inputPath)["orders"]

%{:buyOrderbook => buy, :sellOrderbook => sell} = Omise.process([], [], orders)
File.write("output.json", Poison.encode!(%{ "buy" => buy, "sell" => sell}), [:binary])

IO.puts "result at output.json"