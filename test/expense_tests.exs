defmodule ExpenseTests do
  use ExUnit.Case
  doctest Expense

  ### revolut

  test "should parse revolut record dome" do
    import_session_id = UUID.uuid4()
    detail = "a_description"

    revolut_record = %{
      "Completed Date" => "1 ago 2019",
      "Paid Out (EUR)" => "10,6",
      "Paid In (EUR)" => "",
      "Exchange Out" => "",
      "Exchange In" => "",
      "Balance (EUR)" => "100,0",
      "Category" => "shopping",
      "Description" => detail
    }

    expense =
      Expense.parse_expense(
        revolut_record,
        :revolut,
        "domenico",
        import_session_id
      )

    assert expense != nil
    assert expense.category == "SHOPPING"
    assert expense.amount == -10.6
    assert expense.import_session_id == import_session_id
    assert expense.detail == detail
    assert expense.date == Date.from_iso8601!("2019-08-01")
    assert expense.metadata != nil
    assert expense.metadata == %{:csv => revolut_record}
    assert expense.owner == "domenico"
    assert expense.source == "REVOLUT"
  end

  test "should parse revolut record sara" do
    import_session_id = UUID.uuid4()
    detail = "a_description"

    revolut_record = %{
      "Completed Date" => "July 31",
      "Paid Out (EUR)" => "10,6",
      "Paid In (EUR)" => "",
      "Exchange Out" => "",
      "Exchange In" => "",
      "Balance (EUR)" => "100,0",
      "Category" => "shopping",
      "Reference" => detail
    }

    expense =
      Expense.parse_expense(
        revolut_record,
        :revolut,
        "sara",
        import_session_id
      )

    assert expense != nil
    assert expense.category == "SHOPPING"
    assert expense.amount == -10.6
    assert expense.import_session_id == import_session_id
    assert expense.detail == detail
    assert expense.date == Date.from_iso8601!("2019-07-31")
    assert expense.metadata != nil
    assert expense.metadata == %{:csv => revolut_record}
    assert expense.owner == "sara"
    assert expense.source == "REVOLUT"
  end

  ### sella

  test "should parse sella" do
    import_session_id = UUID.uuid4()
    detail = "a_description"

    sella_record = %{
      "Codice identificativo" => "an_id",
      "Data Contabile" => "29/07/2019",
      "Data valuta" => "29/07/2019",
      "Descrizione" => detail,
      "Divisa" => "EUR",
      "Importo" => "+2.137,00"
    }

    expense =
      Expense.parse_expense(
        sella_record,
        :sella,
        "domenico",
        import_session_id
      )

    assert expense != nil
    assert expense.category == "EXTRA"
    assert expense.amount == 2137
    assert expense.import_session_id == import_session_id
    assert expense.detail == detail
    assert expense.date == Date.from_iso8601!("2019-07-29")
    assert expense.metadata != nil
    assert expense.metadata == %{:csv => sella_record}
    assert expense.owner == "domenico"
    assert expense.source == "SELLA"
  end

  ### widiba

  test "should parse widiba" do
    import_session_id = UUID.uuid4()
    detail = "a_description"

    widiba_record = [
      "boh",
      Date.from_iso8601!("2019-07-29"),
      "boh",
      detail,
      2137,
      "boh"
    ]

    expense =
      Expense.parse_expense(
        widiba_record,
        :widiba,
        "domenico",
        import_session_id
      )

    assert expense != nil
    assert expense.category == "EXTRA"
    assert expense.amount == 2137
    assert expense.import_session_id == import_session_id
    assert expense.detail == detail
    assert expense.date == Date.from_iso8601!("2019-07-29")
    assert expense.metadata != nil
    assert expense.metadata == %{:xls => widiba_record}
    assert expense.owner == "domenico"
    assert expense.source == "WIDIBA"
  end
end
