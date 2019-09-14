defmodule ExpenseUploader do
  @spec upload_expenses([Expense.t()], String.t()) ::
          {:error, Tesla.Env.t()} | {:ok, GoogleApi.Sheets.V4.Model.AppendValuesResponse.t()}
  def upload_expenses(expenses, spreadsheet_id) do
    expenses =
      expenses
      |> Enum.map(
           fn expense ->
             [
               Date.to_iso8601(expense.date),
               expense.amount,
               expense.category,
               expense.detail,
               expense.owner,
               expense.source,
               expense.import_session_id,
               Poison.encode!(expense.metadata)
             ]
           end
         )

    connection =
      GoogleApi.Sheets.V4.Connection.new(
        fn scopes ->
          Goth.Token.for_scope(Enum.join(scopes, " "))
          |> elem(1)
          |> Map.get(:token)
        end
      )

    GoogleApi.Sheets.V4.Api.Spreadsheets.sheets_spreadsheets_values_append(
      connection,
      spreadsheet_id,
      "A:A",
      valueInputOption: "USER_ENTERED",
      body: %GoogleApi.Sheets.V4.Model.ValueRange{
        range: "A:A",
        values: expenses
      }
    )
  end
end
