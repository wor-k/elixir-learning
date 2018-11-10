defmodule Omise do
  def putRecord(record, orderbook, func, res) when length(orderbook) == 0 do
    res ++ [record]
  end

  def putRecord(record, orderbook, func, res) do
    [head | tail] = orderbook

    newOrderBook =
      cond do
        record["price"] == head["price"] ->
          res ++
            [%{"price" => head["price"], "amount" => head["amount"] + record["amount"]}] ++ tail

        func.(record["price"], head["price"]) ->
          res ++ [record, head] ++ tail

        true ->
          putRecord(record, tail, func, res ++ [head])
      end

    newOrderBook
  end

  def putSell(record, orderbook) do
    putRecord(record, orderbook, &(&1 < &2), [])
  end

  def putBuy(record, orderbook) do
    putRecord(record, orderbook, &(&1 > &2), [])
  end

  def processMatch(record, orderbookRecord) do
    matchVolume =
      cond do
        record["amount"] >= orderbookRecord["amount"] ->
          orderbookRecord["amount"]

        true ->
          record["amount"]
      end

    newOrderbooxRecord =
      if orderbookRecord["amount"] == matchVolume do
        nil
      else
        %{
          "price" => orderbookRecord["price"],
          "amount" => orderbookRecord["amount"] - matchVolume
        }
      end

    newRecord =
      if record["amount"] == matchVolume do
        nil
      else
        %{"price" => record["price"], "amount" => record["amount"] - matchVolume}
      end

    %{
      :orderbookRecord => newOrderbooxRecord,
      :record => newRecord
    }
  end

  def matchRecord(record, orderbook, processCond, accOrderbook) when record == nil do
    %{
      :orderbook => accOrderbook ++ orderbook,
      :record => record
    }
  end

  def matchRecord(record, orderbook, processCond, accOrderbook) when length(orderbook) == 0 do
    %{
      :orderbook => accOrderbook,
      :record => record
    }
  end

  def matchRecord(record, orderbook, processCond, accOrderbook) do
    [head | tail] = orderbook

    processRes =
      cond do
        processCond.(record["price"], head["price"]) ->
          processMatch(record, head)

        true ->
          nil
      end

    case processRes do
      nil ->
        %{:orderbook => accOrderbook ++ orderbook, :record => record}

      %{:orderbookRecord => orderbookRecord, :record => newRecord} ->
        case orderbookRecord do
          nil -> matchRecord(newRecord, tail, processCond, accOrderbook)
          _ -> matchRecord(newRecord, tail, processCond, accOrderbook ++ [orderbookRecord])
        end
    end
  end

  def matchBuy(record, orderbook) do
    processCond = &(&1 >= &2)
    matchRecord(record, orderbook, processCond, [])
  end

  def matchSell(record, orderbook) do
    processCond = &(&1 <= &2)
    matchRecord(record, orderbook, processCond, [])
  end

  def get_json(filename) do
    with {:ok, body} <- File.read(filename), {:ok, json} <- Poison.decode(body), do: json
  end

  def processBuy(buyOrderbook, sellOrderbook, order) do
    %{:orderbook => newSellOrderbook, :record => record} = matchBuy(order, sellOrderbook)

    newBuyOrderbook =
      case record do
        nil -> buyOrderbook
        _ -> putBuy(record, buyOrderbook)
      end

    %{:buyOrderbook => newBuyOrderbook, :sellOrderbook => newSellOrderbook}
  end

  def processSell(buyOrderbook, sellOrderbook, order) do
    %{:orderbook => newBuyOrderbook, :record => record} = matchSell(order, buyOrderbook)

    newSellOrderbook =
      case record do
        nil -> sellOrderbook
        _ -> putSell(record, sellOrderbook)
      end

    %{:buyOrderbook => newBuyOrderbook, :sellOrderbook => newSellOrderbook}
  end

  def processCommand(buyOrderbook, sellOrderbook, order) do
    case order["command"] do
      "sell" -> processSell(buyOrderbook, sellOrderbook, Map.drop(order, ["command"]))
      "buy" -> processBuy(buyOrderbook, sellOrderbook, Map.drop(order, ["command"]))
      _ -> %{:buyOrderbook => buyOrderbook, :sellOrderbook => sellOrderbook}
    end
  end

  def process(buyOrderbook, sellOrderbook, orders) when length(orders) == 0 do
    %{:buyOrderbook => buyOrderbook, :sellOrderbook => sellOrderbook}
  end

  def process(buyOrderbook, sellOrderbook, orders) do
    [head | tail] = orders

    %{:buyOrderbook => newBuyOrderbook, :sellOrderbook => newSellOrderbook} =
      processCommand(buyOrderbook, sellOrderbook, head)

    process(newBuyOrderbook, newSellOrderbook, tail)
  end
end
