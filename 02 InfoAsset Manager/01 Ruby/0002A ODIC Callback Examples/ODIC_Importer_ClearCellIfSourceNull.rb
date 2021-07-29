#If Asset ID in the source is null, delete any current value from IAM
class Importer
       def Importer.onEndRecordNode(obj)
              if obj['asset_id'].nil?
                     obj['user_text_1']=nil
              end
       end
end