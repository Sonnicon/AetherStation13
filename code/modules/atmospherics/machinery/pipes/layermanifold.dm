/obj/machinery/atmospherics/pipe/layer_manifold
	name = "layer adaptor"
	icon = 'icons/obj/atmospherics/pipes/manifold.dmi'
	icon_state = "manifoldlayer"
	desc = "A special pipe to bridge pipe layers with."
	dir = SOUTH
	initialize_directions = NORTH|SOUTH
	pipe_flags = PIPING_ALL_LAYER | PIPING_DEFAULT_LAYER_ONLY | PIPING_CARDINAL_AUTONORMALIZE
	piping_layer = PIPING_LAYER_DEFAULT
	// First half are NORTH or EAST, last half are SOUTH or WEST
	device_node_count = (PIPING_LAYER_MAX - PIPING_LAYER_MIN + 1) * 2
	volume = 260
	construction_type = /obj/item/pipe/binary
	pipe_state = "manifoldlayer"
	paintable = FALSE

	var/list/front_nodes
	var/list/back_nodes

/obj/machinery/atmospherics/pipe/layer_manifold/Initialize()
	icon_state = "manifoldlayer_center"
	return ..()

/obj/machinery/atmospherics/pipe/layer_manifold/Destroy()
	nullifyAllNodes()
	return ..()

/obj/machinery/atmospherics/pipe/layer_manifold/proc/nullifyAllNodes()
	for(var/obj/machinery/atmospherics/A in nodes)
		A.disconnect(src)
		SSair.add_to_rebuild_queue(A)
	front_nodes = null
	back_nodes = null
	nodes = list()

/obj/machinery/atmospherics/pipe/layer_manifold/update_layer()
	layer = initial(layer) + (PIPING_LAYER_MAX * PIPING_LAYER_LCHANGE) //This is above everything else.

/obj/machinery/atmospherics/pipe/layer_manifold/update_overlays()
	. = ..()

	for(var/node in nodes)
		. += get_attached_images(node)

/obj/machinery/atmospherics/pipe/layer_manifold/proc/get_attached_images(obj/machinery/atmospherics/A)
	if(!A)
		return

	. = list()
	if(istype(A, /obj/machinery/atmospherics/pipe/layer_manifold))
		for(var/i in PIPING_LAYER_MIN to PIPING_LAYER_MAX)
			. += get_attached_image(get_dir(src, A), i)
		return
	. += get_attached_image(get_dir(src, A), A.piping_layer, A.pipe_color)

/obj/machinery/atmospherics/pipe/layer_manifold/proc/get_attached_image(p_dir, p_layer, p_color = null)
	// Uses pipe-3 because we don't want the vertical shifting
	var/image/I = getpipeimage(icon, "pipe-3", p_dir, p_color, p_layer)
	I.layer = layer - 0.01
	return I

/obj/machinery/atmospherics/pipe/layer_manifold/SetInitDirections()
	switch(dir)
		if(NORTH, SOUTH)
			initialize_directions = NORTH|SOUTH
		if(EAST, WEST)
			initialize_directions = EAST|WEST

/obj/machinery/atmospherics/pipe/layer_manifold/isConnectable(obj/machinery/atmospherics/target, given_layer)
	if(!given_layer)
		return TRUE
	. = ..()

/obj/machinery/atmospherics/pipe/layer_manifold/atmosinit()
	//todo merge this whole thing into the pipes.dm one
	var/discovered_pipes = 0
	// Search once for each direction
	for(var/side = 0 to 1)
		var/opposite_dir = dir << !side
		for(var/obj/machinery/atmospherics/target in get_step(src, dir << side))
			// If target isn't connecting to us
			if(!(target.initialize_directions & opposite_dir))
				continue
			
			// Fast exit for components that occupy all layers
			if(target.pipe_flags & PIPING_ALL_LAYER)
				for(var/i in PIPING_LAYER_MIN to PIPING_LAYER_MAX)
					// Set nodes on each device
					nodes[i + side * 5] = target
					target.nodes[getNodeIndex(opposite_dir, i)] = src
				target.update_appearance()
				break

			// Normal one-layer components
			nodes[target.piping_layer + side * 5] = target
			target.nodes[target.getNodeIndex(opposite_dir, target.piping_layer)] = src
			target.update_appearance()
			
			if(istype(target, /obj/machinery/atmospherics/pipe))
				var/obj/machinery/atmospherics/pipe/target_pipe = target
				discovered_pipes++
				if(discovered_pipes == 1)
					target_pipe.parent.addMemberPipe(src)
				else
					parent.merge(target_pipe.parent)

	if(discovered_pipes == 0)
		parent = new
		parent.addMemberPipe(src)

	update_appearance()

/*/obj/machinery/atmospherics/pipe/layer_manifold/setPipingLayer()
	piping_layer = PIPING_LAYER_DEFAULT*/

/obj/machinery/atmospherics/pipe/layer_manifold/getNodeConnects()
	var/list/node_connects = new(device_node_count)

	for(var/i = 1 to device_node_count)
		node_connects[i] = dir << (dir > 5)

	return node_connects

/obj/machinery/atmospherics/pipe/layer_manifold/getNodeIndex(direction, layer)
	return (direction == dir) * 5 + layer

/obj/machinery/atmospherics/pipe/layer_manifold/pipeline_expansion()
	return nodes

/obj/machinery/atmospherics/pipe/layer_manifold/disconnect(obj/machinery/atmospherics/reference)
	if(istype(reference, /obj/machinery/atmospherics/pipe))
		var/obj/machinery/atmospherics/pipe/P = reference
		P.destroy_network()
	while(reference in nodes)
		var/i = nodes.Find(reference)
		nodes[i] = null
		i = front_nodes.Find(reference)
		if(i)
			front_nodes[i] = null
		i = back_nodes.Find(reference)
		if(i)
			back_nodes[i] = null
	update_appearance()

/obj/machinery/atmospherics/pipe/layer_manifold/relaymove(mob/living/user, direction)
	if(initialize_directions & direction)
		return ..()
	if((NORTH|EAST) & direction)
		user.ventcrawl_layer = clamp(user.ventcrawl_layer + 1, PIPING_LAYER_MIN, PIPING_LAYER_MAX)
	if((SOUTH|WEST) & direction)
		user.ventcrawl_layer = clamp(user.ventcrawl_layer - 1, PIPING_LAYER_MIN, PIPING_LAYER_MAX)
	to_chat(user, "You align yourself with the [user.ventcrawl_layer]\th output.")

/obj/machinery/atmospherics/pipe/layer_manifold/visible
	hide = FALSE
	layer = GAS_PIPE_VISIBLE_LAYER
