#If source field 'SYSTEMDATE' is not null, import in the value into User_text_2 in the strftime format defined
require 'Date'
class Importer
       def Importer.onEndRecordNode(obj)
              if !obj['SYSTEMDATE'].nil?
                     obj['user_text_2']=obj['SYSTEMDATE'].strftime('%d')+"/"+obj['SYSTEMDATE'].strftime('%m')+"/"+obj['SYSTEMDATE'].strftime('%Y')+" "+obj['SYSTEMDATE'].strftime('%T')
              end
       end
end