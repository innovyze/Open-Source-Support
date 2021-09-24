## If source fields cover_lockable/side_entry have value "Y", set IAM boolean field = true/checked
class Importer
        def Importer.onEndRecordNode(obj)
               if obj['cover_lockable']=='Y'
                       obj['cover_type_locking']=true
               end

               if obj['side_entry']=='Y'
                       obj['side_entry']=true
               end
        end
end