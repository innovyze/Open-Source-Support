# Autodesk Water Infrastructure Open Source Support

📊 **[View Repository Traffic Analytics →](https://innovyze.github.io/Open-Source-Support/)**

This repository will host open source code that can be used in the Autodesk Water products. This includes Ruby for the UI/Exchange, SQL and other information.

The [Exchange](https://help.autodesk.com/view/IWICMS/2026/ENU/?guid=Innovyze_Exchange_Introduction_ICM_introduction_html) documentation includes (almost) all available Ruby methods and will be updated regularly.

## Scope

Scripts posted here are generally developed by Autodesk Support on the back of a specific customer request, but we're not programmers. Therefore, the scripts might not always be entirely optimised. Feel welcome to contribute with pull requests and raise issues for changes that you'd like to see.

It would be a desirable by-product if this space reached enough critical mass that a community of like-minded users would help each other, suggest improvements and propose new ideas. Feel free to make use of [Issues](https://github.com/innovyze/Open-Source-Support/issues).

This is not the place to develop bespoke code for customers, nor ever will we post it here. This can be requested from Autodesk within the scope of an implementation project.

## Languages

### Ruby

Ruby scripts are split into those which run from the UI and those which run via the Exchange API. The differences between the two are explicit in the [Exchange](https://help.autodesk.com/view/IWICMS/2026/ENU/?guid=Innovyze_Exchange_Introduction_ICM_introduction_html) documentation.

In this repository:

* Scripts that run from the **UI** will follow the nomenclature `UI_script.rb`. These can be run from the Workgroup Client.
* Scripts that run from via **Exchange** will follow the nomenclature `EX_script.rb`. These need to be passed to `IExchange.exe` to run, which is present in the folders of every version of the Workgroup Client installation in both 32-bit and 64-bit. This requires a valid Exchange license.

The `bat` file encapsulates commands that call the Exchange executable and provide the Ruby script in the same folder as a parameter for a specific Workgroup Client version. It allows a degree of customisation - see an example below:

```bat
@ECHO OFF
SET script=EX_script.rb
SET version=2021.1
SET bit=64
IF %bit%==32 (SET "path=C:\Program Files (x86)")
IF %bit%==64 (SET "path=C:\Program Files")
"%path%\Innovyze Workgroup Client %version%\IExchange" "%~dp0%script%" ICM
```

This example BAT script passes an `EX_script.rb` Ruby script to the `IExchange.exe` executable version `2021.1` using the `64-bit` architecture.

Multiple scripts performing a similar task can be stored under the same folder. These should be appended with the suffix `_v?`, where `?` is an integer representing each variant.

### SQL (of the Autodesk Water Workgroup Products variety)

Autodesk Water implements its own subset of SQL (Structured Query Language) for selecting and updating network objects using specified criteria.
An SQL query consists of a number of clauses separated by semi-colons. Each clause can do one of the following:

* Select objects
* Deselect objects
* Update fields in objects
* Clear the selection

Within the GUI users can create Stored Query objects where SQL queries can be built using a dialog.

## How to Contribute

We welcome contributions from the modeling community! If you have any great scripts that you would like to share, please submit a [pull request](https://github.com/innovyze/Open-Source-Support/pulls), or contact technical support. We will review them and try to upload them to the repository as soon as possible.

Additionally, if you find any bugs or make any enhancements to our existing scripts, please let us know. Your feedback is valuable in improving the quality of the scripts.

Together, let's grow and improve the InfoWorks ICM / WS Pro modelling experience!

## Disclaimer

### Structure

This project is currently growing in an organic fashion. We might decide to change the structure, which might mean broken links. We're also open to structure changes by users if they improve usability. We'll try to avoid this as best as possible, but during the early stages of the project this can happen frequently.

### Liability

Autodesk Support will post and moderate code posted here in good faith. This is open source and is available for anyone to interrogate.

**Autodesk is not liable for unintended consequences of code posted here, nor does it have a responsibility for maintaining it.**
