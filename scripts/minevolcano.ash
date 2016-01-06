script "minevolcano.ash";

/**********************************************
                 Developed by:
      the coding arm of ProfessorJellybean.
             (#2410942), (#2413598)

 Please don't KMail me unless there are issues.
     I'm glad you're using this but I have
             enough mail already :P

   GCLI Usage: minevolcano <turns to spend>

**********************************************/

/***
Strategy:

Check that everything's okay, equip stuff/heal if necessary.
Visit the mine URL and load the page.
If no sparkles are present, and nothing has been mined, mine a random non-edge square.
If no sparkles are present, and at least one square has been mined, reset.
If sparkles are present, mine the sparkle. (Ignore if in the velvet zone)
 - If $item[1,970 carat gold] is found, reset.
 - If $item[unsmoothed velvet] is found, reset. (contiguous velvet trap)
 - Else, let future iterations keep going at this one.
***/

// The Location code of the velvet mine.
location mine = $location[The Velvet / Gold Mine];
// The URL of the velvet mine.
string mineurl = "mining.php?mine=6";

// The amount of base hot resistant requireed to mine
int hot15amount = 83.26;
// whether or not a mysticality bonus is granted
boolean mystbonus = (my_class() == $class[pastamancer] || my_class() == $class[sauceror]);

//high-temp drill equipment
item drill = $item[high-temperature mining drill];
item broken = $item[broken high-temperature mining drill];
item sheets = $item[heat-resistant sheet metal];
// Xiblaxian holowristputer and whether or not to try equipping it.
item wristputer = $item[xiblaxian holo-wrist-puter];
boolean tryputer = true;

// The contents of the mine page.
string page;
// Whether or not a mark has been made.
boolean mined;
// Whether or not a gold or a velvet has been found.
boolean reset;
// Coordinates to target for the next mining adventure. Col-major order. (XY)
int[2] target;

// Your password hash, for POST requests.
string pwhash = "&pwd=" + my_hash();
// Color of error messages.
string errcolor = "Red";
// True until something goes horribly wrong. Setting false should induce global halt.
boolean running = true;



// Prints an error.
void throwErr(string errmsg) {
	print(errmsg, errcolor);
}

// Returns whether Object Detection-like effects are on.
boolean objdetect() {
	return (have_effect($effect[Object Detection]) != 0) || is_wearing_outfit("Dwarvish War Uniform");
}

// Returns whether or not 15 hot resistance is available.
boolean hot15resist() {
	float base_resist_limit = hot15amount;
	class myclass = my_class();
	if (mystbonus) {
		base_resist_limit = base_resist_limit + 5;
	}
	return elemental_resistance($element[hot]) > base_resist_limit;
}

// Tries to put a wristputer in a given accessory slot, if it does not upset hotres.
// Returns true if succesful.
boolean wristputerIn(slot place) {
	item swap = equipped_item(place);
	equip(place, wristputer);
	if (hot15resist()) {
		return true;
	}
	equip(place, swap);
	return false;
}

// Returns if one is wearing a wristputer or not.
boolean wearingWristputer() {
	return (equipped_item($slot[acc1]) == wristputer)
	|| (equipped_item($slot[acc2]) == wristputer)
	|| (equipped_item($slot[acc3]) == wristputer);
}

// Returns if it is possible to mine at the 70s volcano.
// Will attempt to construct and equip the proper equipment.
boolean canMine() {
	//Check if the player is not drunk.
	if(my_inebriety() > inebriety_limit()) {
		throwErr("You're drunk.");
		return false;
	}

	//Checks for remaining adventures
	if (my_adventures() == 0) {
		throwErr("No adventures.");
		return false;
	}
	
	//Checks that the player is not beaten up
	if (have_effect($effect[Beaten Up]) != 0) {
		throwErr("You got beaten up somewhere. Heal first.");
		return false;
	}

	//Check has 15 hot resistance. If not, attempt to do it.
	if (! hot15resist()) {
		maximize("Hot Resistance -1weapon -1offhand", 0, 0, false);
		if (! hot15resist()) {
    		throwErr("More hot resistance needed.");
    		return false;
    	}
    	// Attempt to swap in a xiblaxian holowristputer if one is owned.
    	if (tryputer && (! wearingWristputer())) {
	    	if (item_amount(wristputer) != 0 || closet_amount(wristputer) != 0) {
	    		if (item_amount(wristputer) == 0) {
	    			take_closet(1, wristputer);
	    		}
	    		tryputer = wristputerIn($slot[acc3]) || wristputerIn($slot[acc2]) || wristputerIn($slot[acc1]);
	    	} else {
	    		tryputer = false;
	    	}
	    }
   	}

   	//Checks that the player has survivable health.
   	float healthmultiplier = (100 - elemental_resistance($element[hot])) / 100;
   	int minhp = healthmultiplier * 70;
	if (my_hp() < minhp) {
		throwErr("Insufficent hp. You need at least " + minhp + " hp to mine safely.");
		int hprestore = 2 * minhp + my_hp();
		print("Attempting to restore hp to " + hprestore, "gray");
		if (! restore_hp(hprestore)) {
			throwErr("Unable to restore!");
			return false;
		}
	}

	if (equipped_item($slot[weapon]) != drill) {
		// If there isn't an inventory drill but the closet has one, take it.
		if (item_amount(drill) == 0 && closet_amount(drill) != 0) {
			take_closet(1, drill);
		}

		// If there isn't one in the inventory, attempt to construct one.
		// Not like they have any other use, anyway.
		while (item_amount(drill) == 0) {
			// Checks and gets the proper number of sheets.
			if (item_amount(sheets) == 0) {
				if (closet_amount(sheets) == 0) {
					throwErr("Need more heat-resistant sheet metal.");
					return false;
				} else {
					take_closet(1, sheets);
				}
			}
			
			// Checks and gets the proper number of broken drills.
			if (item_amount(broken) == 0) {
				if (closet_amount(broken) == 0) {
					throwErr("Need more heat-resistant sheet metal.");
					return false;
				} else {
					take_closet(1, broken);
				}
			}

			// Now that the materials have been readied, attempt 1 repair.
			use(1, broken);
		}

		// Equip one drill from inventory.
		if (can_equip(drill)) {
			equip(drill);
		} else {
			throwErr("drill cannot be equipped.");
			return false;
		}

	}

	//Check for no object detection
	if (objdetect()) {
		throwErr("I see you have Object Detection. That's interesting, but distracting to this script.");
		return false;
	}

	return true;
}

// Resets the mine targeting data.
void resetData() {
	target[0] = 0;
	target[1] = 0;
	mined = false;
	reset = false;
}

// Refreshes the PAGE object and snips out the table.
void refresh() {
	// Check if the player has access
    if (mine == $location[none]) {
		throwErr("Cannot find the mine.");
		return;
	}

	page = visit_url(mineurl);
	resetData();

	// Match open caverns in row 1 to determine if the page is mined.
	matcher matcher_open = create_matcher("Open Cavern \\(\\d,6\\)", page);
	mined = matcher_open.find();

	// Match sparkles in the first two rows.
	matcher matcher_sparkle = create_matcher("Promising Chunk of Wall \\((\\d),([56])\\)", page);
	if (matcher_sparkle.find()) {
		target[0] = matcher_sparkle.group(1).to_int();
		target[1] = matcher_sparkle.group(2).to_int();
	}
}

// Clears out the mine and finds a new one.
// This is free!
void mineReset() {
	print("Resetting mine.", "gray");
	visit_url("mining.php?reset=1&mine=6" + pwhash, true);
}

// Returns whether a sparkly target is in reach.
boolean hasTarget() {
	return (target[0] != 0) && (target[1] != 0);
}

// Check for a gold reset.
void checkAfter(string result) {
	int[item] itemsFound = extract_items(result);
	if (itemsFound contains $item[1,970 carat gold]) {
		print("Struck gold!", "blue");
		mineReset();
	}
}

// Mines at a specified spot.
void mineAtSpot(int col, int row) {
	print("Mining at square (" + col + ", "+ row + ")", "gray");
	string url = mineurl;
	int index = col + (8 * row);
	url = url + "&which=" + index;
	url = url + pwhash;
	string result = visit_url(url, true);
	checkAfter(result);
}

// Does one mining turn in the optimal pattern.
void mine() {
	// If one can mine,
	if (canMine()) {
	   //are there accessible sparkles within the first two rows? (helper)
		if (hasTarget()) {
			// mine the sparkle.
			mineAtSpot(target[0], target[1]);
		}
		else {
			//has this mine been mined?
			if (mined) {
				//if so, reset.
				print("No more sparklies here.", "gray");
				mineReset();
			} else {
				// mine a central square in the first row.
				print("Trying a spot.", "gray");
				mineAtSpot(3, 6);
			}
		}
	} else {
		// Uh oh! Cannot mine. Halt needed.
		running = false;
	}
	return;
}

// Runs the script for TURNS adventures.
void main(int turns) {
	int startingct=item_amount($item[1,970 carat gold]);
	int temp = turns;

	while (temp > 0 && running) {
		refresh();
		mine();
		temp = temp - 1;
	}

	int delta = item_amount($item[1,970 carat gold]) - startingct;

	string messagecolor = "red";
	if (delta > 0) {
		messagecolor = "green";
	}

	int avgvalue = delta * 19700 / turns;
	print("Obtained " + delta + " 1,970 carat golds in " + turns + " turns.", messagecolor);
	print("Average value: " + avgvalue + " meat/adventure", messagecolor);
}