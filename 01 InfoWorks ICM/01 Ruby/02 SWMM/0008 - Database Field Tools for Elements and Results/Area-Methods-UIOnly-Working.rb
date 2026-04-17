# This method of obtaining objects is WIP

$instances = {}
$instances[:WSOpenNetwork]           = WSApplication.current_network
$instances[:WSDatabase]              = WSApplication.current_database
$instances[:WSModelObjectCollection] = $instances[:WSDatabase].model_object.collection("Model Group")
$instances[:WSModelObject]           = $instances[:WSModelObjectCollection][0]
$instances[:WSNumbatNetworkObject]   = $instances[:WSDatabase].model_object.collection("Model Network")[0]
$instances[:WSSimObject]             = $instances[:WSDatabase].model_object.collection("Sim")[0]

$instances[:WSOpenNetwork].transaction_begin
$instances[:WSRowObject]             = $instances[:WSOpenNetwork].new_row_object("hw_prefs")
$instances[:WSNode]                  = $instances[:WSOpenNetwork].new_row_object("hw_nodes")
$instances[:WSLink]                  = $instances[:WSOpenNetwork].new_row_object("hw_conduit")
$instances[:WSOpenNetwork].transaction_rollback

#... etc.


def try(object,method,args)
	begin
		object.method(method).call(*args)
	rescue Exception => e
                message = e.to_s  #In general if you get a parameter type error, the method is likely runnable in the UI.
                if (message =="The method cannot be run from the user interface")
                    message = "ICMExchange Only"
                elsif message=="The method is for Innovyze internal use only, please check your licence."
                    message = "Innovyze Private method"
                elsif message == "The method cannot be run from InfoWorks ICM"
                    message = "The method cannot be run from InfoWorks ICM"
                end
		puts (object.to_s + "." +  method.to_s).ljust(80) + ":\t" + message
	end
end

Module.constants.each do |const|
    if const.to_s[/MS.+/]
        cls = Module.const_get(const) #class
        methods = cls.singleton_methods - Object.methods
        instance_methods = cls.instance_methods - Object.methods
        
        #Test singleton methods
        if methods.length > 0
            methods.each do |method|
                args = getTestArgs(cls,method)
                try(cls,method,args)
            end
        end
        
        #Test instance methods
        icls = $instances[const]
        if instance_methods.length > 0
            instance_methods.each do |method|
                args = getTestArgs(cls,method)
                try(icls,method,args)
            end
        end
    end
end