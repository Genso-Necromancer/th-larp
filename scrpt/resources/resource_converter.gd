extends Resource
class_name ResourceConverter


##Resource-to-SaveData
##Order of resources is preserved, usable with items and features
func resources_to_save_data(resources:Array)->Dictionary:
	var converted:Dictionary = {}
	var slot:int=0
	for resource in resources:
		converted[str(slot)]=resource.convert_to_save_data()
		slot += 1
	return converted

##Does not preserve order of effects
func effects_to_save_data(effects:Dictionary)->Dictionary:
	var converted:Dictionary = {}
	for key in effects:
		var effect:Effect = effects[key].effect
		var path= effect.convert_to_save_data().Properties
		converted[key] = {"Path":path,"Duration":effect[key].duration}
	return converted


##Save Data-to-Resource
#The round about way this is processed was done to preserve the original order of the unit's inventory
func inventory_to_resource(resources:Dictionary)->Array[Item]:
	var slot:= 0
	var size:= resources.size()
	var inv:Array[Item]
	while slot<size:
		var type: String = resources[str(slot)].class
		var item: Item
		var stringified:String = str(slot) #Thanks wokedot
		match type:
			"Weapon": 
				item = Weapon.new(load(resources[stringified].Properties))
				item.load_save_data(resources[stringified])
			"Consumable":
				item = Consumable.new(load(resources[stringified].Properties))
				item.load_save_data(resources[stringified])
			"Ofuda": 
				item = Ofuda.new(load(resources[stringified].Properties))
				item.load_save_data(resources[stringified])
			"Accessory":
				item = Accessory.new(load(resources[stringified].Properties))
				item.load_save_data(resources[stringified])
		inv.append(item)
		slot += 1
	return inv


func buff_effects_to_resource(effects:Dictionary)->Dictionary:
	var resources:Dictionary={}
	for key in effects:
		var loaded := load(effects[key].Path)
		resources[key]={"Effect":loaded,"Duration":effects[key].Duration}
	return resources


func natural_to_resource(natural_data:Dictionary) ->Natural:
	var natural := Natural.new(load(natural_data.Properties))
	natural.load_save_data(natural_data)
	return natural


## Use ".assign()" with the returned array to convert it's typing
func features_to_resource(features:Dictionary)->Array[Feature]:
	var resources:Array[Feature]=[]
	var slot:= 0
	var size:= resources.size()
	while slot<size:
		var feature := load(features[str(slot)].Properties)
		resources.append(feature)
		slot += 1
	return resources
