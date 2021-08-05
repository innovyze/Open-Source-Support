Details: Is it possible to look-up the property ID within the Property grid based upon the location and assign it to the property ID in the Blockage incident with a query?

Request to Update the property_id field of a Blockage Incident with the Property ID form the Property table by comparing the location field on the Blockage Incident to the property_address on the Property object.


^ Script file UpdateBlockagePropertyID.rb will action as the request.

The other scripts (UpdateObjectFromObject_ByPrompt_n.rb) are all to update any object from any other object in the database by making a comparison. Options for Source & Destination are: Tables, Fields for comparison, Fields to pull from/to.

Script#2 Adds in support for overwriting existing values in destination.

Script#3 Adds in support for Flags.