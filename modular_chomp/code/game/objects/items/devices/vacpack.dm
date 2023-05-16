//Vac attachment
/obj/item/device/vac_attachment
	name = "Vac-Pack attachment"
	desc = "Useful for slurping mess off the floors. Even things and stuff depending on settings. Can be connected to a trash bag or vore belly. On-mob sprites can be toggled via verb in Objects tab."
	icon = 'modular_chomp/icons/mob/vacpack.dmi'
	icon_override = 'modular_chomp/icons/mob/vacpack.dmi'
	icon_state = "sucker_drop"
	item_state = "sucker"
	var/vac_power = 0
	var/output_dest = null
	var/list/vac_settings = list(
			"power off" = 0,
			"dust and grime" = 1,
			"tiny objects" = 2,
			"pests and small objects" = 3,
			"medium objects" = 4,
			"large objects" = 5,
			"large pests" = 6,
			"auto-level" = 7,
			"output destination" = 8
			)

/obj/item/device/vac_attachment/New()
	..()
	flags |= NOBLUDGEON //No more attack messages

/obj/item/device/vac_attachment/attack_self(mob/living/user)
	var/set_input = null
	if(!output_dest)
		set_input = "output destination"
	if(!set_input)
		set_input = tgui_input_list(user, "Set your vacuum attachment's power level or output mode.", "Vac Settings", vac_settings)
	if(set_input)
		if(set_input == "output destination")
			var/set_output = tgui_input_list(user, "Set your vacuum attachment's connection port", "Vac Settings", list("Vore Belly", "Borg Belly", "Trash Bag"))
			if(set_output)
				if(set_output == "Borg Belly")
					if(isrobot(user))
						var/mob/living/silicon/robot/R = user
						var/obj/item/weapon/robot_module/M = R.module
						for(var/obj/item/device/dogborg/sleeper/S in M.modules)
							if(istype(S))
								output_dest = S
								return
					to_chat(user, "<span class='warning'>Borg belly not found.</span>")
				if(set_output == "Trash Bag")
					if(isrobot(user))
						var/mob/living/silicon/robot/R = user
						var/obj/item/weapon/robot_module/M = R.module
						for(var/obj/item/weapon/storage/bag/trash/T in M.modules)
							if(istype(T))
								output_dest = T
								return
					for(var/obj/item/weapon/storage/bag/trash/T in user.contents)
						if(istype(T))
							output_dest = T
							return
					to_chat(user, "<span class='warning'>Trash bag not found.</span>")
				if(set_output == "Vore Belly")
					if(user.vore_selected)
						output_dest = user.vore_selected
			return
		else
			vac_power = vac_settings[set_input]
			icon_state = "sucker-[vac_power]"

/obj/item/device/vac_attachment/afterattack(atom/target, mob/living/user, proximity)
	if(vac_power < 1)
		return
	if(!proximity)
		return
	if(!output_dest)
		return
	if(istype(output_dest,/obj/item/weapon/storage/bag/trash))
		if(get_turf(output_dest) != get_turf(user))
			vac_power = 0
			icon_state = "sucker-0"
			output_dest = null
			to_chat(user, "<span class='warning'>Trash bag not found. Shutting down.</span>")
			return
		var/obj/item/weapon/storage/bag/trash/B = output_dest
		if(LAZYLEN(B.contents) >= B.max_storage_space) //A bit more lenient than the w_class system to avoid complicated spaghetti.
			to_chat(user, "<span class='warning'>Trash bag full. Empty trash bag contents to continue.</span>")
			return
	if(istype(output_dest,/obj/item/device/dogborg/sleeper))
		var/obj/item/device/dogborg/sleeper/B = output_dest
		if(LAZYLEN(B.contents) >= B.max_item_count)
			to_chat(user, "<span class='warning'>[B.name] full. Empty or process contents to continue.</span>")
			return
		if(B.ore_storage)
			if(B.current_capacity >= B.max_ore_storage)
				to_chat(user, "<span class='warning'>Ore storage full. Deposit ore contents to a box continue.</span>")
				return
	if(isbelly(output_dest))
		var/obj/belly/B = output_dest
		if(B.loc != user && !B.loc.Adjacent(user)) //Can still be used as a feeding tube by another adjacent player.
			vac_power = 0
			icon_state = "sucker-0"
			output_dest = null
			to_chat(user, "<span class='warning'>Target destination not found. Shutting down.</span>")
			return
	user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
	var/auto_setting = 1
	if(isturf(target))
		user.visible_message("<span class='filter_notice'>[user] begins vacuuming the mess off \the [target.name]...</span>", "<span class='notice'>You begin vacuuming the mess off \the [target.name]...</span>")
		var/list/suckables = list()
		if(vac_power >= 1)
			for(var/obj/effect/decal/cleanable/C in target)
				suckables |= C
		if(vac_power >= 2)
			for(var/obj/item/I in target)
				if(I.anchored || I.w_class > 1)
					continue
				else
					suckables |= I
		if(vac_power >= 3)
			for(var/obj/item/I in target)
				if(I.anchored || I.w_class > 2)
					continue
				else
					suckables |= I
			for(var/mob/living/L in target)
				if(L.anchored || !L.devourable || L == user || L.buckled || !L.can_be_drop_prey)
					continue
				if(L.size_multiplier < 0.5)
					suckables |= L
				if(istype(L,/mob/living/simple_mob/animal/passive/mouse) || istype(L,/mob/living/simple_mob/animal/passive/lizard) || istype(L,/mob/living/simple_mob/animal/passive/cockroach))
					suckables |= L
		if(vac_power >= 4)
			for(var/obj/item/I in target)
				if(I.anchored || I.w_class > 3)
					continue
				else
					suckables |= I
		if(vac_power >= 5)
			for(var/obj/item/I in target)
				if(I.anchored)
					continue
				else
					suckables |= I
		if(vac_power >= 6)
			for(var/mob/living/L in target)
				if(L.anchored || !L.devourable || L == user || L.buckled || !L.can_be_drop_prey)
					continue
				suckables |= L
		if(LAZYLEN(suckables))
			if(vac_power == 7)
				for(var/atom/movable/F in suckables)
					if(isitem(F))
						auto_setting = max(2, auto_setting)
						var/obj/item/I = F
						if(I.w_class > auto_setting)
							auto_setting = min(I.w_class, 5)
					if(isliving(F))
						var/mob/living/L = F
						if(L.size_multiplier < 0.5 || istype(L,/mob/living/simple_mob/animal/passive/mouse) || istype(L,/mob/living/simple_mob/animal/passive/lizard) || istype(L,/mob/living/simple_mob/animal/passive/cockroach))
							if(auto_setting < 3)
								auto_setting = 3
						else
							auto_setting = 6
			else
				auto_setting = vac_power
			playsound(src, 'sound/machines/kitchen/candymaker/candymaker-mid1.ogg', auto_setting * 20, 1, -1)
			var/vac_conga = 0
			for(var/atom/movable/F in suckables)
				if(is_type_in_list(F,item_vore_blacklist) || F.loc != target)
					continue
				if(istype(F,/obj/effect/decal/cleanable))
					qdel(F)
					continue
				if(istype(output_dest,/obj/item/weapon/storage/bag/trash))
					var/obj/item/weapon/storage/bag/trash/B = output_dest
					if(LAZYLEN(B.contents) >= B.max_storage_space)
						to_chat(user, "<span class='warning'>Trash bag full. Empty trash bag contents to continue.</span>")
						return
				if(vac_conga < 100)
					vac_conga += 3
				spawn(3 + vac_conga)
					if(!F.Adjacent(user) || src.loc != user || vac_power < 2) //Cancel if moved/unpowered/dropped
						break
					F.SpinAnimation(5,1)
					spawn(5)
						if(F.loc == target)
							if(isitem(F))
								var/obj/item/I = F
								if(I.drop_sound)
									playsound(src, I.drop_sound, auto_setting * 5, 1, -1)
							playsound(src, 'sound/rakshasa/corrosion3.ogg', auto_setting * 15, 1, -1)
							F.forceMove(output_dest)
			if(istype(target, /turf/simulated))
				var/turf/simulated/T = target
				T.dirt = 0
				T.clean_blood()
		return
	if(!isturf(target.loc))
		return
	if(istype(target,/obj/item))
		var/obj/item/I = target
		if(is_type_in_list(I,item_vore_blacklist))
			return
		if(vac_power > I.w_class)
			if(vac_power == 7)
				auto_setting = min(I.w_class, 5)
			else
				auto_setting = vac_power
			playsound(src, 'sound/machines/kitchen/candymaker/candymaker-mid1.ogg', auto_setting * 20, 1, -1)
			user.visible_message("<span class='filter_notice'>[user] vacuums up \the [target.name].</span>", "<span class='notice'>You vacuum up \the [target.name]...</span>")
			I.SpinAnimation(5,1)
			spawn(5)
				if(!I.Adjacent(user) || src.loc != user || vac_power < 2) //Cancel if moved/unpowered/dropped
					return
				if(I.drop_sound)
					playsound(src, I.drop_sound, vac_power * 5, 1, -1)
				playsound(src, 'sound/rakshasa/corrosion3.ogg', auto_setting * 15, 1, -1)
				I.forceMove(output_dest)
	else if(istype(target,/obj/effect/decal/cleanable))
		playsound(src, 'sound/machines/kitchen/candymaker/candymaker-mid1.ogg', auto_setting * 20, 1, -1)
		user.visible_message("<span class='filter_notice'>[user] vacuums up \the [target.name].</span>", "<span class='notice'>You vacuum up \the [target.name]...</span>")
		qdel(target)
	else if(isliving(target))
		var/mob/living/L = target
		var/valid_to_suck = FALSE
		if(L.anchored || !L.devourable || L == user || L.buckled || !L.can_be_drop_prey)
			return
		if(vac_power >= 3)
			if(L.size_multiplier > 0.5 || istype(L,/mob/living/simple_mob/animal/passive/mouse) || istype(L,/mob/living/simple_mob/animal/passive/lizard))
				valid_to_suck = TRUE
				auto_setting = 3
		if(vac_power >= 6)
			valid_to_suck = TRUE
			auto_setting = 6
		if(valid_to_suck)
			playsound(src, 'sound/machines/kitchen/candymaker/candymaker-mid1.ogg', auto_setting * 20, 1, -1)
			user.visible_message("<span class='filter_notice'>[user] vacuums up \the [target.name].</span>", "<span class='notice'>You vacuum up \the [target.name]...</span>")
			L.SpinAnimation(5,1)
			spawn(5)
				if(!L.Adjacent(user) || src.loc != user || vac_power < 2) //Cancel if moved/unpowered/dropped
					return
				playsound(src, 'sound/rakshasa/corrosion3.ogg', auto_setting * 15, 1, -1)
				L.forceMove(output_dest)
	return

/obj/item/device/vac_attachment/resolve_attackby(atom/A, mob/user, var/attack_modifier = 1, var/click_parameters)
	if(istype(A,/obj/structure) && vac_power > 0)
		afterattack(A.loc, user, click_parameters)
		return TRUE
	return ..()

/obj/item/device/vac_attachment/pickup(mob/user)
	.=..()
	icon_state = "sucker-[vac_power]"

/obj/item/device/vac_attachment/dropped(mob/user as mob)
	.=..()
	icon_state = "sucker_drop"

/obj/item/device/vac_attachment/verb/hide_pack()
	set name = "Toggle Vac-Pack Sprites"
	set desc = "Toggle Vac-Pack sprite visibility"
	set category = "Object"
	var/choice = tgui_input_list(usr, "Vac-Pack Visibility Options", "Vac-Pack Visibility Options", list("Show Pack", "Show Tube", "Hidden"))
	if(choice == "Show Pack")
		item_state = "sucker"
	if(choice == "Show Tube")
		item_state = "sucker_nobag"
	if(choice == "Hidden")
		item_state = null
	usr.update_inv_r_hand()
	usr.update_inv_l_hand()

/obj/item/weapon/storage/Entered(atom/movable/thing, atom/OldLoc) //Holder the mob so they don't get stuck in trashbags etc.
	. = ..()
	if(isliving(thing))
		var/mob/living/L = thing
		var/mob_holder_type = L.holder_type || /obj/item/weapon/holder
		new mob_holder_type(src, L)
