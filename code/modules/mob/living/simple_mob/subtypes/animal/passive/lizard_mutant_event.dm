/mob/living/simple_mob/animal/passive/lizard/event
	desc = "This one looks like it is growing huge!"
	var/amount_grown = 0
	var/faction = lizard

/mob/living/simple_mob/animal/passive/lizard/event/Life()
	. = ..()
	if(amount_grown >= 0)
		amount_grown += rand(0,4)
	if(amount_grown >= 100 && icon_state != icon_dead)
		man()
		return

/mob/living/simple_mob/animal/passive/lizard/event/proc/man()
	visible_message("<span class='warning'>\The [src] suddenly evolves!</span>")
	new /mob/living/simple_mob/vore/aggressive/lizardman(get_turf(src))
	qdel(src)
