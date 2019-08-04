# ExpenseTracker

Personal tool I use to map bank accounts reports and upload them to a google spreadsheet.

## Warning

**the project is a personal tool**

**it just handles the type of bank accounts I need, it is not thougth as a "all bank accounts" tool**

Handled bank accounts
- revolut
- sella
- widiba

## What problem does it solve?

I have more than one bank account, my expenses are spread through them.
My girlfirend has another bank account.

We would like to aggregate our expesnes in a single place in order to be able to check an monitor them.

We chose google spreadsheet to aggregate expenses, beacuse it has different clients (mobile/web) and it is easy to use and edit manually if needed.

Given the bank accounts report, this script map them into a model we choose to use to represent expenses on the spreadsheet, and uplaod the expenses to the google spreadsheet.

The process is not yet fully automated, because I have to run manually the script after I download manually the exports (not the best but I am working on making it better)

## Highlight of the project

- The script is configurable using a json file `config/config.json`
```
{
  "spreadsheet_id": "11nvtF9XQOJIz0KSpJtGRmsIA0bks-VNJ3HoyrNcdBv4",
  "report_files": [
    {
      "file_path": "/Users/domenicovisconti/Desktop/export/Revolut-EUR-Statement-1 Jun 2019 to 31 Jul 2019.csv",
      "source": "revolut",
      "owner": "SARA"
    },
    {
      "file_path": "/Users/domenicovisconti/Desktop/export/Revolut-EUR-Statement-giu – lug 2019.csv",
      "source": "revolut",
      "owner": "DOMENICO"
    },
    {
      "file_path": "/Users/domenicovisconti/Desktop/export/ListaMovimentiConto.csv",
      "source": "sella",
      "owner": "DOMENICO"
    },
    {
      "file_path": "/Users/domenicovisconti/Desktop/export/I miei movimenti conto.xlsx",
      "source": "widiba",
      "owner": "DOMENICO"
    }
  ]
}

```
- csv and xls parsing using 
  - `{:csv, "~> 2.3"}`
  - `{:xlsxir, "~> 1.6"}`
- `{:goth, "~> 1.1"}` is used to authenticate `{:google_api_sheets, "~> 0.7.0"}` requests through oauth2.

## How to run

To run the script, log into iex loading the mix project
```
iex -S mix  
```

Parse report files, map them and upload them to google sheet using
```
ExpenseTracker.track 
```