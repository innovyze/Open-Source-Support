To export the choice list values (from Network > Standards & Choice Lists) as part of a Ruby script export process.

[UI-ExportChoiceListValues.rb](./UI-ExportChoiceListValues.rb)
This is a standalone script syntax which will export the Choice List values for the Category Code field of a CCTV Survey, the relevant methods are `field_choices` and `field_choice_descriptions`.
As this is a metadata export it is not as straight forward as exporting network objects.
I have surrounded them with basic Ruby syntax to have two outputs, one to screen (using puts) and one to a CSV file.

To export multiple choice list values, the centre block (between "fc =" [line 9] and the second "end" [line 30]) would have to be duplicated prior to the final end with the relevant tables and fields defined.