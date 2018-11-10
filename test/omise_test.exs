defmodule OmiseTest do
  use ExUnit.Case
  doctest Omise

  test "putRecord empty" do
    orderbook = [
    ]
    expect = [
      %{"price" => 300, "amount" => 100},
    ]
    func = &(&1 < &2)
    assert Omise.putRecord(%{"price" => 300, "amount" => 100}, orderbook, func, []) == expect
  end

  test "putRecord tail" do
    orderbook = [
      %{"price" => 100, "amount" => 100},
      %{"price" => 150, "amount" => 100},
      %{"price" => 200, "amount" => 100},
    ]
    expect = [
      %{"price" => 100, "amount" => 100},
      %{"price" => 150, "amount" => 100},
      %{"price" => 200, "amount" => 100},
      %{"price" => 300, "amount" => 100},
    ]
    func = &(&1 < &2)
    assert Omise.putRecord(%{"price" => 300, "amount" => 100}, orderbook, func, []) == expect
  end

  test "putRecord head" do
    orderbook = [
      %{"price" => 100, "amount" => 100},
      %{"price" => 150, "amount" => 100},
      %{"price" => 200, "amount" => 100},
    ]
    expect = [
      %{"price" => 50, "amount" => 100},
      %{"price" => 100, "amount" => 100},
      %{"price" => 150, "amount" => 100},
      %{"price" => 200, "amount" => 100},
    ]
    func = &(&1 < &2)
    assert Omise.putRecord(%{"price" => 50, "amount" => 100}, orderbook, func, []) == expect
  end

  test "putRecord middle" do
    orderbook = [
      %{"price" => 100, "amount" => 100},
      %{"price" => 150, "amount" => 100},
      %{"price" => 200, "amount" => 100},
    ]
    expect = [
      %{"price" => 100, "amount" => 100},
      %{"price" => 150, "amount" => 100},
      %{"price" => 175, "amount" => 100},
      %{"price" => 200, "amount" => 100},
    ]
    func = &(&1 < &2)
    assert Omise.putRecord(%{"price" => 175, "amount" => 100}, orderbook, func, []) == expect
  end

  test "putRecord equal" do
    orderbook = [
      %{"price" => 100, "amount" => 100},
      %{"price" => 150, "amount" => 100},
      %{"price" => 200, "amount" => 100},
    ]
    expect = [
      %{"price" => 100, "amount" => 100},
      %{"price" => 150, "amount" => 200},
      %{"price" => 200, "amount" => 100},
    ]
    func = &(&1 < &2)
    assert Omise.putRecord(%{"price" => 150, "amount" => 100}, orderbook, func, []) == expect
  end

  test "putSell" do
    orderbook = [
      %{"price" => 100, "amount" => 100},
      %{"price" => 150, "amount" => 100},
      %{"price" => 200, "amount" => 100},
    ]
    expect = [
      %{"price" => 100, "amount" => 100},
      %{"price" => 125, "amount" => 100},
      %{"price" => 150, "amount" => 100},
      %{"price" => 200, "amount" => 100},
    ]
    assert Omise.putSell(%{"price" => 125, "amount" => 100}, orderbook) == expect
  end

  test "putBuy" do
    orderbook = [
      %{"price" => 100, "amount" => 100},
      %{"price" => 150, "amount" => 100},
      %{"price" => 200, "amount" => 100},
    ]
    expect = [
      %{"price" => 100, "amount" => 100},
      %{"price" => 150, "amount" => 100},
      %{"price" => 175, "amount" => 100},
      %{"price" => 200, "amount" => 100},
    ]
    assert Omise.putSell(%{"price" => 175, "amount" => 100}, orderbook) == expect
  end

  test "processMatch" do
    mockOrderbookRecord = %{"price" => 101, "amount" => 100}
    mockRecord = %{"price" => 100, "amount" => 100}

    expectOrderbookRecord = nil
    expectRecord = nil

    %{:orderbookRecord => orderbookRecord, :record => record} = Omise.processMatch(mockRecord, mockOrderbookRecord)
    assert orderbookRecord == expectOrderbookRecord
    assert record == expectRecord
  end

  test "processMatch partial 1" do
    mockOrderbookRecord = %{"price" => 101, "amount" => 103}
    mockRecord = %{"price" => 100, "amount" => 100}

    expectOrderbookRecord = %{"price" => 101, "amount" => 3}
    expectRecord = nil

    %{:orderbookRecord => orderbookRecord, :record => record} = Omise.processMatch(mockRecord, mockOrderbookRecord)
    assert orderbookRecord == expectOrderbookRecord
    assert record == expectRecord
  end

  test "processMatch partial 2" do
    mockOrderbookRecord = %{"price" => 100, "amount" => 100}
    mockRecord = %{"price" => 101, "amount" => 107}

    expectOrderbookRecord = nil
    expectRecord = %{"price" => 101, "amount" => 7}

    %{:orderbookRecord => orderbookRecord, :record => record} = Omise.processMatch(mockRecord, mockOrderbookRecord)
    assert orderbookRecord == expectOrderbookRecord
    assert record == expectRecord
  end

  test "matchRecord partial 1" do
    mockOrderbook = [
      %{"price" => 100, "amount" => 100},
      %{"price" => 150, "amount" => 100},
      %{"price" => 200, "amount" => 100},
    ]
    mockRecord = %{"price" => 150, "amount" => 150}

    expectOrderbook = [
      %{"price" => 150, "amount" => 50},
      %{"price" => 200, "amount" => 100},
    ]
    expectRecord = nil
    processCond = &(&1 >= &2)
    %{:orderbook => orderbook, :record => record} = Omise.matchRecord(mockRecord, mockOrderbook, processCond, [])
    assert orderbook == expectOrderbook
    assert record == expectRecord
  end

  test "matchRecord partial 2" do
    mockOrderbook = [
      %{"price" => 100, "amount" => 100},
    ]
    mockRecord = %{"price" => 150, "amount" => 101}

    expectOrderbook = [
    ]
    expectRecord = %{"price" => 150, "amount" => 1}
    processCond = &(&1 >= &2)
    %{:orderbook => orderbook, :record => record} = Omise.matchRecord(mockRecord, mockOrderbook, processCond, [])
    assert orderbook == expectOrderbook
    assert record == expectRecord
  end

  test "matchRecord partial 3" do
    mockOrderbook = [
      %{"price" => 100, "amount" => 103},
      %{"price" => 150, "amount" => 100},
      %{"price" => 200, "amount" => 100},
    ]
    mockRecord = %{"price" => 100, "amount" => 100}

    expectOrderbook = [
      %{"price" => 100, "amount" => 3},
      %{"price" => 150, "amount" => 100},
      %{"price" => 200, "amount" => 100},
    ]
    expectRecord = nil
    processCond = &(&1 >= &2)
    %{:orderbook => orderbook, :record => record} = Omise.matchRecord(mockRecord, mockOrderbook, processCond, [])
    assert orderbook == expectOrderbook
    assert record == expectRecord
  end
end
