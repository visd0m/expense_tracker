defmodule ReportFile do
  @enforce_keys [:file_path, :source, :owner]
  defstruct [:file_path, :source, :owner]

  @type t :: %ReportFile{
          file_path: String.t(),
          source: atom(),
          owner: atom()
        }
end
