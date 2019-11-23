defmodule ExpenseUploader do
  require Logger

  @spec upload_expenses([Expense.t()], String.t()) ::
          {:error, Tesla.Env.t()} | {:ok, GoogleApi.Sheets.V4.Model.AppendValuesResponse.t()}
  def upload_expenses(expenses, spreadsheet_id) do
    expenses =
      expenses
      |> Enum.map(fn expense ->
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
      end)

    connection =
      GoogleApi.Sheets.V4.Connection.new(fn scopes ->
        case get_token(scopes) do
          {:ok, token} -> token
          err -> raise "can not obtain access token, #{inspect(err)}"
        end
      end)

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

  @spec get_token([String.t()]) :: {:ok, String.t()} | {:error, any}
  def get_token(scopes) do
    Logger.info("getting token for scopes=#{scopes}")

    with scopes <- Enum.join(scopes, " "),
         {:ok, result} <- Goth.Token.for_scope(scopes),
         {:ok, token} <- Map.fetch(result, :token) do
      {:ok, token}
    else
      {:error, reason} = err ->
        Logger.error(inspect(reason))
        err

      err ->
        {:error, err}
    end
  end
end
