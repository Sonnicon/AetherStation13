/obj/machinery/atmospherics/pipe
	damage_deflection = 12
	var/datum/gas_mixture/air_temporary //used when reconstructing a pipeline that broke
	var/volume = 0

	use_power = NO_POWER_USE
	can_unwrench = 1
	var/datum/pipeline/parent = null
	can_process_atmos = FALSE

	paintable = TRUE
	var/amendable = FALSE

	//Buckling
	can_buckle = TRUE
	buckle_requires_restraints = TRUE
	buckle_lying = 90

/obj/machinery/atmospherics/pipe/New()
	add_atom_colour(pipe_color, FIXED_COLOUR_PRIORITY)
	volume = 35 * device_node_count
	..()

/obj/machinery/atmospherics/pipe/Initialize()
	. = ..()

	if (hide)
		AddElement(/datum/element/undertile, TRAIT_T_RAY_VISIBLE) //if changing this, change the subtypes RemoveElements too, because thats how bespoke works

/obj/machinery/atmospherics/pipe/atmosinit(list/node_connects = getNodeConnects())
	// Collect references to devices available at nodes
	var/discovered_pipes = 0
	for(var/i in 1 to device_node_count)
		var/discover_direction = node_connects[i]
		for(var/obj/machinery/atmospherics/target in get_step(src, discover_direction))
			// Don't connect on invalid valid connection
			if(!can_be_node(target, i))
				continue

			// Set nodes on ourselves and the target
			nodes[i] = target
			// Get the direction of us from the other pipe
			var/reverse_direction = (12 - 9 * (((discover_direction >> 1) | discover_direction) & 1)) & (discover_direction ^ 15)
			target.nodes[target.getNodeIndex(reverse_direction, piping_layer)] = src
			target.update_appearance()

			// Merge with other pipes we find
			if(istype(target, /obj/machinery/atmospherics/pipe))
				var/obj/machinery/atmospherics/pipe/other = target
				discovered_pipes++

				if(discovered_pipes == 1)
					// Add ourselves to first pipe we find
					other.parent.addMemberPipe(src)
				else
					// And merge all further pipelines
					//todo optimization find the largest one then merge all into that
					parent.merge(other.parent)
			break

	// Create new pipeline for ourselves if we're alone
	if(discovered_pipes == 0)
		parent = new
		parent.addMemberPipe(src)

	update_appearance()

/obj/machinery/atmospherics/pipe/nullifyNode(i)
	var/obj/machinery/atmospherics/oldN = nodes[i]
	..()
	if(oldN)
		SSair.add_to_rebuild_queue(oldN)

/obj/machinery/atmospherics/pipe/destroy_network()
	QDEL_NULL(parent)

/obj/machinery/atmospherics/pipe/get_rebuild_targets()
	if(!QDELETED(parent))
		return
	parent = new
	return list(parent)

/obj/machinery/atmospherics/pipe/proc/releaseAirToTurf()
	if(air_temporary)
		var/turf/T = loc
		T.assume_air(air_temporary)

/obj/machinery/atmospherics/pipe/return_air()
	if(air_temporary)
		return air_temporary
	return parent.air

/obj/machinery/atmospherics/pipe/return_analyzable_air()
	if(air_temporary)
		return air_temporary
	return parent.air

/obj/machinery/atmospherics/pipe/remove_air(amount)
	if(air_temporary)
		return air_temporary.remove(amount)
	return parent.air.remove(amount)

/obj/machinery/atmospherics/pipe/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/pipe_meter))
		var/obj/item/pipe_meter/meter = W
		user.dropItemToGround(meter)
		meter.setAttachLayer(piping_layer)
	else
		return ..()

/obj/machinery/atmospherics/pipe/proc/createAmend(turf/T, direction)

/obj/machinery/atmospherics/pipe/returnPipenet()
	return parent

/obj/machinery/atmospherics/pipe/setPipenet(datum/pipeline/P)
	parent = P

/obj/machinery/atmospherics/pipe/Destroy()
	QDEL_NULL(parent)

	releaseAirToTurf()

	var/turf/T = loc
	for(var/obj/machinery/meter/meter in T)
		if(meter.target == src)
			var/obj/item/pipe_meter/PM = new (T)
			meter.transfer_fingerprints_to(PM)
			qdel(meter)
	. = ..()

/obj/machinery/atmospherics/pipe/update_icon()
	. = ..()
	update_layer()

/obj/machinery/atmospherics/pipe/proc/update_node_icon()
	for(var/i in 1 to device_node_count)
		if(nodes[i])
			var/obj/machinery/atmospherics/N = nodes[i]
			N.update_icon()

/obj/machinery/atmospherics/pipe/returnPipenets()
	. = list(parent)

/obj/machinery/atmospherics/pipe/paint(paint_color)
	if(paintable)
		add_atom_colour(paint_color, FIXED_COLOUR_PRIORITY)
		pipe_color = paint_color
		update_node_icon()
	return paintable
