class_name Quests
## Static quest definitions and the rules that move them along. Quest progress is stored per character via
## GameState.get/set_quest_state, with tallies and one-off flags in GameState.get/set_quest_counter.
##
## A quest is offered by its giver (an NPC or an object such as a notice board, by npc id), then moves from
## state to state:
## - "events": things done out in the world. record_event(type, target, object_id) advances every active
##   quest waiting on that event, once per object for collectables, until "count" is reached.
## - "talks": conversations with an NPC (the giver or anyone else) that advance or complete the quest.
## - "quest_item": an item found in the forest boss's chest (Rendel's coat).
## Completing a quest pays out its gold and experience and files its keepsake under Quest Rewards.
##
## A quest is offered once every quest in "requires" is done and, if it has one, its "requires_level" has
## been cleared. Level transition quests (see get_departure) carry the player on to the next region: they
## have a "travel" to a hub and an "arrive" event at that hub (target "hub_<level id>", recorded by every
## hub's HUD on arrival) that completes them. Another region's transition is one more definition like
## ROAD_TO_SALTWIND plus a giver standing in the previous hub.

const STATE_AVAILABLE := ""
const STATE_ACCEPTED := "accepted"
const STATE_COMPLETED := "completed"

const FIND_RENDEL := "find_rendel"
## find_rendel stage: the player has looted Rendel's coat and must return it to Beth.
const STATE_COAT_FOUND := "coat_found"
const WILD_APPLES := "wild_apples"
const WORD_FROM_THE_WOODS := "word_from_the_woods"
const MOONPETAL_REMEDY := "moonpetal_remedy"
const GLOOMHOLLOW := "gloomhollow"
const THINNING_THE_PACK := "thinning_the_pack"
const RENDELS_AXE := "rendels_axe"
const LOST_PIP := "lost_pip"
const SCAR_EAR_BOUNTY := "scar_ear_bounty"
const WAYFIRES := "wayfires"
## The starting zone's quest (see StartingZone): walk Perry to Oblath for a new hat. He doesn't make it.
const PERRYS_HAT := "perrys_hat"
## The Forest Outskirts' transition quest: once the area is secured, ride Rashid's caravan to Saltwind Camp.
const ROAD_TO_SALTWIND := "road_to_saltwind"

## The Sunscorch Sands (see DesertQuests). The story: Malik, a caravan driver, dug into the vault beneath
## the buried city of Qasr Anuhm for gold and cracked the Sunstone that kept the First Sting, mother of
## every scorpion in the Sands, asleep. The main line runs from his wreck to her death:
const LAST_CARAVAN := "last_caravan"
const VOICE_IN_THE_DUNES := "voice_in_the_dunes"
const CITY_THE_SAND_ATE := "city_the_sand_ate"
const WORDS_IN_STONE := "words_in_stone"
const SUNKEN_VAULT := "sunken_vault"
const MOTHER_OF_STINGS := "mother_of_stings"
## Saltwind Camp's side quests.
const STONES_FOR_THE_LOST := "stones_for_the_lost"
const SALVAGE_RIGHTS := "salvage_rights"
const TAIL_FOR_SAMIR := "tail_for_samir"
const EYES_ON_THE_DUNES := "eyes_on_the_dunes"
const GLASSTAIL_BOUNTY := "glasstail_bounty"
const SWEETWATER := "sweetwater"
const SUNBLOOM_STEW := "sunbloom_stew"
## The Sunscorch Sands' transition quest: once the First Sting is dead, ride north with Torsten to Rimehollow.
const NORTH_TO_RIMEHOLLOW := "north_to_rimehollow"

## Areas shown as tabs in the quest menu, keyed by GameState level id.
const AREAS := [
	{"level_id": 1, "name": "Forest Outskirts"},
	{"level_id": 2, "name": "Sunscorch Sands"},
	{"level_id": 3, "name": "The Ice Caves"},
	{"level_id": 4, "name": "The Underworld"},
]

## Everyone (and everything) that gives, advances or takes in a quest. "idle" is said when they have
## nothing quest-related to say.
const NPCS := {
	"beth": {"name": "Beth", "idle": ["The forest road is quiet tonight."]},
	"mary": {"name": "Mary", "idle": ["Mind the cobbles, love. They've tripped better folk than you."]},
	"gertrude": {"name": "Gertrude", "idle": ["My knees say rain. My knees are never wrong."]},
	"sarah": {"name": "Sarah", "idle": ["Pip! Pip, where have you... oh. Sorry, I thought you were my boy."]},
	"elsa": {"name": "Elsa", "idle": ["Ale's warm, stew's warmer. Come in when you've a mind to."]},
	"notice_board": {"name": "Oblath Notice Board", "idle": ["Faded notices: a lost goat, a sale of turnips, a reminder that the well is not a bath."]},
	"aldous": {"name": "Aldous the Hermit", "idle": ["The forest talks, if you're patient. Mostly it says 'go away'."]},
	"corwin": {"name": "Corwin the Hunter", "idle": ["Keep your eyes on the treeline. Wolves don't announce themselves."]},
	"pip": {"name": "Pip", "idle": ["I'm not scared. I'm just... sitting very still."]},
	"forest_shrine": {"name": "Mossy Shrine", "idle": ["The shrine is quiet. Warmth lingers in the old stone."]},
	"perry": {"name": "Perry", "idle": ["Green, with a feather. Did I mention the feather?"]},
	"rashid": {"name": "Rashid the Camel-Driver", "idle": ["Sand in my boots, sand in my bread. You never get it all out."]},
	"idris": {"name": "Caravan Master Idris", "idle": ["Water first, questions after. That's the rule of Saltwind."]},
	"hamid": {"name": "Old Hamid", "idle": ["The wind remembers everything the sand forgets."]},
	"leila": {"name": "Leila", "idle": ["We pile the stones high so the wind can't take them too."]},
	"jamal": {"name": "Jamal", "idle": ["If it's not nailed down, the sand takes it. If it is nailed down, the sand takes the nails."]},
	"samir": {"name": "Samir", "idle": ["I'm keeping watch. Tarek doesn't know yet."]},
	"tarek": {"name": "Scout Tarek", "idle": ["If you see the sand move against the wind, run."]},
	"saltwind_guard": {"name": "Camp Guard", "idle": ["Keep to the trail when you head out. The dunes shift."]},
	"nadja": {"name": "Nadja", "idle": ["Drink, but don't waste it. Every cup is a day."]},
	"farah": {"name": "Farah", "idle": ["Eat something. Out there you won't get the chance."]},
	"yusuf": {"name": "Yusuf", "idle": ["I check the camels twice a night now. Just in case."]},
	"imani": {"name": "Scholar Imani", "idle": ["Three hundred years under the sand, and the carvings are still crisp. They built to be read."]},
	"torsten": {"name": "Torsten the Fur-Trader", "idle": ["Too hot. Everything here is too hot. Even the soup."]},
}

const DEFINITIONS := {
	FIND_RENDEL: {
		"title": "The Missing Woodsman",
		"type": "Search",
		"giver": "Beth",
		"giver_id": "beth",
		"giver_location": "Oblath",
		"area": 1,
		"summary": "Beth's husband Rendel went into the forest to cut timber three days ago and never came home. The wolves have grown bold, and Beth fears the worst.",
		"objectives": [
			"Search the Forest Outskirts for Rendel",
			"Return Rendel's wool coat to Beth in Oblath",
		],
		# How many objectives are done, and the status line, for each stage of the quest.
		"stages": {
			STATE_ACCEPTED: {"objectives_done": 0, "status": "Search the forest for any sign of Rendel."},
			STATE_COAT_FOUND: {"objectives_done": 1, "status": "You found Rendel's wool coat in the wolves' lair. Return it to Beth in Oblath."},
			STATE_COMPLETED: {"objectives_done": 2, "status": "Completed. Beth now knows what became of Rendel."},
		},
		# Looting this item from the boss chest moves the quest from requires_state to sets_state.
		"quest_item": {
			"name": "Rendel's Wool Coat",
			"color": "#9b6b43",
			"requires_state": STATE_ACCEPTED,
			"sets_state": STATE_COAT_FOUND,
		},
		"talks": [
			{
				"npc": "beth",
				"requires_state": STATE_COAT_FOUND,
				"sets_state": STATE_COMPLETED,
				"pages": [
					"You're back. What... what is that you're carrying?",
					"That's his coat. I stitched that patch on the elbow myself, last winter. He never went anywhere without it.",
					"So the wolves... oh, Rendel. My Rendel. *Beth clutches the coat and weeps.*",
					"I'm sorry. Thank you for bringing him back to me, in the only way you could.",
					"Here. This was his compass. He always said it would lead him home. Take it, so a part of him can keep travelling.\n\nYou received Rendel's Compass.",
				],
			},
		],
		"reward": {
			"name": "Rendel's Compass",
			"description": "A battered brass compass, its needle still steady. Beth pressed it into your hands so a part of Rendel could keep travelling. It has no use in battle, only in memory.",
		},
		"dialogue": {
			STATE_AVAILABLE: [
				"Oh, thank the stars, a traveller who can hold a blade. Please, I need your help.",
				"My husband Rendel went into the forest three days ago to cut timber, like he does every week. He always comes home before the lamps are lit.",
				"He hasn't come back. And the hunters say the wolves have grown bold out there... whole packs of them, led by a great grey beast.",
				"I can't bear to think of it. Will you search the forest for Rendel and bring him home to Oblath?",
			],
			"accepted_reply": [
				"Bless you. Take the portal to the forest, and please be careful. If you find him... tell him I'm waiting.",
			],
			"declined_reply": [
				"I... I understand. It's dangerous out there. If you change your mind, I'll be right here.",
			],
			STATE_ACCEPTED: [
				"Any sign of Rendel? Please, keep searching the forest. He's stubborn, but he's all I have.",
			],
			STATE_COMPLETED: [
				"I miss him. Every evening I still look toward the forest road, hoping to see him walking home.",
			],
		},
	},
	WILD_APPLES: {
		"title": "Wild Apples for Mary",
		"type": "Gathering",
		"giver": "Mary",
		"giver_id": "mary",
		"giver_location": "Oblath",
		"area": 1,
		"summary": "Mary bakes the harvest pies for Oblath's autumn supper, but this year's orchard crop was thin. The old wild apple trees in the Forest Outskirts still fruit, if someone brave enough will pick them.",
		"objectives": [
			"Pick apples from 5 wild apple trees in the Forest Outskirts",
			"Bring the apples to Mary in Oblath",
		],
		"stages": {
			STATE_ACCEPTED: {"objectives_done": 0, "status": "Find wild apple trees in the forest and pick their fruit.", "counter": {"label": "Trees picked", "count": 5}},
			"apples_picked": {"objectives_done": 1, "status": "Your pack is heavy with wild apples. Bring them to Mary in Oblath."},
			STATE_COMPLETED: {"objectives_done": 2, "status": "Completed. Oblath will have its harvest pies after all."},
		},
		"events": [
			{"type": "collect", "target": "apple", "requires_state": STATE_ACCEPTED, "sets_state": "apples_picked", "count": 5},
		],
		"talks": [
			{
				"npc": "mary",
				"requires_state": "apples_picked",
				"sets_state": STATE_COMPLETED,
				"pages": [
					"Look at you, laden like a pack mule! Let me see... oh, these are lovely. Tart as a lemon and twice as bright.",
					"My grandmother swore by forest apples. Said the wolves kept the trees honest. Never knew what she meant.",
					"*Mary tucks a folded, flour-dusted card into your hand.* My pie recipe. Don't you dare show it to Gertrude.",
				],
			},
		],
		"reward": {
			"name": "Mary's Recipe Card",
			"description": "A flour-dusted card in looping handwriting: 'Forest apples, a knob of butter, honey if you've got it, patience if you haven't.' Mary made you swear not to show Gertrude.",
		},
		"gold": 30,
		"experience": 80,
		"dialogue": {
			STATE_AVAILABLE: [
				"Oh, a fresh face! You look like someone who doesn't mind a walk. I'm Mary. I bake the harvest pies for the autumn supper.",
				"But the orchard's had a sorry year. Blight, then the frost. I've barely enough apples for one pie, let alone thirty.",
				"There are wild apple trees out in the Forest Outskirts, though. Old ones, gnarled as Gertrude's temper. They always fruit.",
				"Would you pick some for me? Five trees' worth ought to do it. I'd go myself, but I'm rather attached to my legs.",
			],
			"accepted_reply": [
				"Wonderful! Look for the trees heavy with red fruit. And mind the wolves - they're fond of apples. Well, fond of apple-pickers.",
			],
			"declined_reply": [
				"No, no, I understand. Wolves and pies don't mix. Just don't come crying to me at the supper when there's only turnip tart.",
			],
			STATE_ACCEPTED: [
				"Any luck with those wild trees? Five should see me right. Follow the red, my love.",
			],
			STATE_COMPLETED: [
				"The pies are cooling on every sill in Oblath. You'll get the first slice at the supper, I promise.",
			],
		},
	},
	WORD_FROM_THE_WOODS: {
		"title": "Word from the Woods",
		"type": "Search",
		"giver": "Gertrude",
		"giver_id": "gertrude",
		"giver_location": "Oblath",
		"area": 1,
		"summary": "Gertrude's younger brother Aldous lives alone in the Forest Outskirts, an herbalist who sends her a basket of remedies at every new moon. Two moons have passed without one.",
		"objectives": [
			"Find Aldous's camp in the Forest Outskirts",
			"Bring Aldous's letter back to Gertrude",
		],
		"stages": {
			STATE_ACCEPTED: {"objectives_done": 0, "status": "Search the Forest Outskirts for Aldous the hermit."},
			"met_aldous": {"objectives_done": 1, "status": "Aldous is alive. Take his letter back to Gertrude in Oblath."},
			STATE_COMPLETED: {"objectives_done": 2, "status": "Completed. Gertrude knows her brother is safe."},
		},
		"talks": [
			{
				"npc": "aldous",
				"requires_state": STATE_ACCEPTED,
				"sets_state": "met_aldous",
				"pages": [
					"Hm? A visitor? Nobody visits. That's rather the point of being a hermit.",
					"Gertrude sent you? *He goes pale.* Two moons! Has it truly been two moons? The wolves came so close to camp that I dared not walk the road.",
					"She'll have imagined me eaten. She always imagines me eaten. She's been imagining it since I was six.",
					"*He scratches out a letter with a stub of charcoal and presses it into your hands.* Give her this, would you? Tell her I'm whole. Mostly.",
				],
			},
			{
				"npc": "gertrude",
				"requires_state": "met_aldous",
				"sets_state": STATE_COMPLETED,
				"pages": [
					"Well? Don't stand there like a post. Is he... *She snatches the letter and reads it twice.*",
					"'Whole. Mostly.' The old fool. Hiding from wolves in his own woods, and not a word to his sister.",
					"*Her voice wobbles, just once.* Thank you, dear. Truly. Here - I pressed these from our mother's garden. I want someone kind to have one.",
				],
			},
		],
		"npc_lines": {
			"aldous": {
				"met_aldous": ["Go on, take that letter to Gertrude before she storms the forest with a rolling pin. Come back after - I could use a steady pair of hands."],
			},
		},
		"reward": {
			"name": "Pressed Forget-me-not",
			"description": "A tiny blue flower pressed flat between waxed paper, from the garden Gertrude and Aldous grew up tending. She keeps the rest in her prayer book.",
		},
		"gold": 20,
		"experience": 60,
		"dialogue": {
			STATE_AVAILABLE: [
				"You there. Yes, you, with the sword and the sorry boots. Sit. My knees won't let me chase you.",
				"My brother Aldous lives out in that forest, brewing his roots and mumbling at mushrooms. Every new moon he sends me a basket of remedies.",
				"Two moons now, and nothing. Not a basket, not a note. He's a fool, but he's never once forgotten.",
				"Find him for me. Bring me word. And if the wolves have had him... bring me that word too.",
			],
			"accepted_reply": [
				"Good. He camps in the deep woods to the south-west, where the light goes green. Follow the smoke - he never could build a clean fire.",
			],
			"declined_reply": [
				"Hmph. Well. I've waited two moons; I can wait a third. Probably.",
			],
			STATE_ACCEPTED: [
				"Still nothing? South-west, I said. Where the light goes green and the smoke smells of burnt sage.",
			],
			"met_aldous": [
				"You found him? Then why are you just standing there? Out with it!",
			],
			STATE_COMPLETED: [
				"He writes like a hen walks. But it's his writing, and that's what matters.",
			],
		},
	},
	MOONPETAL_REMEDY: {
		"title": "Moonpetal Remedy",
		"type": "Gathering",
		"giver": "Aldous",
		"giver_id": "aldous",
		"giver_location": "the Forest Outskirts",
		"area": 1,
		"requires": [WORD_FROM_THE_WOODS],
		"summary": "Aldous's stores ran dry while the wolves kept him pinned in camp. Gertrude's joint tonic needs moonpetals, pale flowers that glow faintly in the forest's shaded hollows.",
		"objectives": [
			"Gather 4 moonpetals from the Forest Outskirts",
			"Bring the moonpetals to Aldous",
		],
		"stages": {
			STATE_ACCEPTED: {"objectives_done": 0, "status": "Look for glowing moonpetals near Aldous's camp.", "counter": {"label": "Moonpetals", "count": 4}},
			"petals_gathered": {"objectives_done": 1, "status": "You have enough moonpetals. Bring them to Aldous."},
			STATE_COMPLETED: {"objectives_done": 2, "status": "Completed. Gertrude's tonic is on its way to Oblath."},
		},
		"events": [
			{"type": "collect", "target": "moonpetal", "requires_state": STATE_ACCEPTED, "sets_state": "petals_gathered", "count": 4},
		],
		"talks": [
			{
				"npc": "aldous",
				"requires_state": "petals_gathered",
				"sets_state": STATE_COMPLETED,
				"pages": [
					"Moonpetals! And not a bruise on them. You've gentler hands than you look.",
					"*He grinds the petals with honey and something that smells alarmingly of feet.* There. A month's tonic for Gertrude. I'll send it with the next carter.",
					"She'll complain it tastes foul. That's how she'll know I'm well.",
				],
			},
		],
		"gold": 30,
		"experience": 100,
		"dialogue": {
			STATE_AVAILABLE: [
				"Ah, you're back. And Gertrude? Still alive, still furious? Good, good. Both mean she's healthy.",
				"I owe her a basket, but my shelves are bare. Her knees need moonpetal tonic, and I've not a single petal left.",
				"They grow round here, in the shade - pale things that glow like a cat's eye at dusk. The wolves trample them, the brutes.",
				"Bring me four, and I'll brew her a month's worth. Will you?",
			],
			"accepted_reply": [
				"Splendid. Look in the green shade around my camp. Pick them at the stem - gently, now, they bruise like peaches.",
			],
			"declined_reply": [
				"Ah. Well. I'll go myself, then. Tomorrow. Or the day after. When the wolves are... less.",
			],
			STATE_ACCEPTED: [
				"Four moonpetals, friend. They glow, you can't miss them. Unless you do, in which case look harder.",
			],
			STATE_COMPLETED: [
				"The tonic's bottled and gone. You'd think I'd sent her gold, the fuss she'll make.",
			],
		},
	},
	GLOOMHOLLOW: {
		"title": "The Gloomhollow",
		"type": "Cave",
		"giver": "Aldous",
		"giver_id": "aldous",
		"giver_location": "the Forest Outskirts",
		"area": 1,
		"requires": [MOONPETAL_REMEDY],
		"summary": "Aldous's old teacher, the herbwife Ilsa, kept her life's work in a journal hidden in the Gloomhollow, a cave west of his camp. A great black wolf has made its den there, and Aldous can't bear to think of her journal rotting under it.",
		"objectives": [
			"Enter the Gloomhollow, west of Aldous's camp",
			"Defeat Gloomfang, the black wolf of the hollow",
			"Recover Ilsa's journal from the cave",
			"Return the journal to Aldous",
		],
		"stages": {
			STATE_ACCEPTED: {"objectives_done": 0, "status": "Find the Gloomhollow's mouth, west of Aldous's camp, and go inside."},
			"entered": {"objectives_done": 1, "status": "Something large breathes in the dark. Defeat Gloomfang."},
			"beast_slain": {"objectives_done": 2, "status": "Gloomfang is dead. Search the back of the cave for Ilsa's journal."},
			"journal_found": {"objectives_done": 3, "status": "You have Ilsa's journal. Bring it to Aldous."},
			STATE_COMPLETED: {"objectives_done": 4, "status": "Completed. Ilsa's journal is home with her last student."},
		},
		"events": [
			{"type": "enter", "target": "gloomhollow", "requires_state": STATE_ACCEPTED, "sets_state": "entered"},
			{"type": "kill", "target": "gloomfang", "requires_state": "entered", "sets_state": "beast_slain"},
			{"type": "collect", "target": "ilsas_journal", "requires_state": "beast_slain", "sets_state": "journal_found"},
		],
		"talks": [
			{
				"npc": "aldous",
				"requires_state": "journal_found",
				"sets_state": STATE_COMPLETED,
				"pages": [
					"Is that... *He takes the journal in both hands, as though it might crumble.* Her handwriting. Every page.",
					"Forty years of remedies. Where the wolfsbane grows, how to set a bone, what to say to a dying man. She knew everything, Ilsa did.",
					"And Gloomfang? Dead? Then the hollow is quiet again. She'd have liked that. She hated noisy neighbours.",
					"Take this. It was hers - she used it to find her way home on moonless nights. I think she'd want it to keep moving.\n\nYou received Ilsa's Star Chart.",
				],
			},
		],
		"reward": {
			"name": "Ilsa's Star Chart",
			"description": "A palm-sized disc of hammered tin pricked with tiny holes. Held up to a lantern, it throws the autumn stars across the wall. The herbwife Ilsa used it to find her way home.",
		},
		"gold": 60,
		"experience": 200,
		"dialogue": {
			STATE_AVAILABLE: [
				"Sit a moment. There's something I've not told anyone, not even Gertrude.",
				"My teacher, Ilsa, kept a journal. Forty years of herb-lore, every remedy she ever learned. When she died, I hid it in the Gloomhollow, a cave west of here, so it'd be safe.",
				"Safe. Ha. A wolf moved in last spring - a black beast, bigger than a pony. The pack calls it Gloomfang, if wolves call things anything.",
				"I'm too old and too fond of my throat to go in there. But you... Would you bring Ilsa's journal out of the dark?",
			],
			"accepted_reply": [
				"The mouth of the cave is west of my camp, under a hill of mossy stone. Mind your footing, and mind Gloomfang more.",
			],
			"declined_reply": [
				"No. No, of course. It's only a book. *He doesn't look at you.* Only a book.",
			],
			STATE_ACCEPTED: [
				"The Gloomhollow is west of here. Look for a dark mouth in the hillside, and a smell like wet dog and old bones.",
			],
			"entered": [
				"You've been inside? And Gloomfang? Still alive? Then so is the problem.",
			],
			"beast_slain": [
				"Gloomfang's dead? Ha! Then the journal - did you find it? It's at the very back, under the stones where the crystals grow.",
			],
			STATE_COMPLETED: [
				"I read a page of Ilsa's journal every night. It's like hearing her voice again. Thank you, friend.",
			],
		},
	},
	THINNING_THE_PACK: {
		"title": "Thinning the Pack",
		"type": "Hunt",
		"giver": "Corwin",
		"giver_id": "corwin",
		"giver_location": "the Forest Outskirts",
		"area": 1,
		"summary": "Corwin, Oblath's hunter, has counted three packs where there used to be one. Until they're culled, nobody can work the woods safely - not woodcutters, not herb-gatherers, not hunters.",
		"objectives": [
			"Slay 10 wolves in the Forest Outskirts",
			"Report back to Corwin",
		],
		"stages": {
			STATE_ACCEPTED: {"objectives_done": 0, "status": "Slay wolves in the Forest Outskirts.", "counter": {"label": "Wolves slain", "count": 10}},
			"wolves_culled": {"objectives_done": 1, "status": "That's ten wolves. Report back to Corwin at his camp near the forest road."},
			STATE_COMPLETED: {"objectives_done": 2, "status": "Completed. The packs are thinner, for now."},
		},
		"events": [
			{"type": "kill", "target": "wolf", "requires_state": STATE_ACCEPTED, "sets_state": "wolves_culled", "count": 10},
		],
		"talks": [
			{
				"npc": "corwin",
				"requires_state": "wolves_culled",
				"sets_state": STATE_COMPLETED,
				"pages": [
					"Ten? I heard the howling stop on the east ridge. That was you, wasn't it?",
					"*He looks you up and down, then nods once.* You'd make a fair hunter. Too loud, but fair.",
					"Here. Pulled it from the first wolf I ever killed, back when I was half your size. Wear it and the packs will know you've earned your place out here.",
				],
			},
		],
		"reward": {
			"name": "Wolf-Tooth Charm",
			"description": "A yellowed fang on a strip of rawhide, from the first wolf Corwin ever killed. Hunters in Oblath wear them to say: I have walked the woods and come home.",
		},
		"gold": 40,
		"experience": 120,
		"dialogue": {
			STATE_AVAILABLE: [
				"Easy. You're not a wolf, so you're welcome. Name's Corwin. I hunt these woods for Oblath.",
				"Used to be one pack in this forest, and it knew its place. Now there's three, and they've stopped running from men.",
				"I can't work the traps, the woodcutters won't go past the road, and the herb-folk are hiding in their huts.",
				"Thin them out. Ten wolves should break the bolder packs. I'll make it worth your while.",
			],
			"accepted_reply": [
				"Good. They'll find you before you find them - just make sure you're the one still standing.",
			],
			"declined_reply": [
				"Suit yourself. They'll still be here when you change your mind. More of them, probably.",
			],
			STATE_ACCEPTED: [
				"Keep at it. Every wolf you drop is one less at Oblath's fence.",
			],
			STATE_COMPLETED: [
				"Quieter out there. I can hear the birds again. Funny how you forget they were missing.",
			],
		},
	},
	RENDELS_AXE: {
		"title": "Rendel's Axe",
		"type": "Exploration",
		"giver": "Corwin",
		"giver_id": "corwin",
		"giver_location": "the Forest Outskirts",
		"area": 1,
		"requires": [FIND_RENDEL],
		"summary": "Corwin knew Rendel well. He remembers the woodsman's favourite felling site, a clearing of old stumps to the north-east, and thinks Rendel's axe may still be lying where he worked his last day.",
		"objectives": [
			"Find Rendel's felling site, north-east in the Forest Outskirts",
			"Bring Rendel's axe home to Beth in Oblath",
		],
		"stages": {
			STATE_ACCEPTED: {"objectives_done": 0, "status": "Search the north-east of the forest for Rendel's felling site."},
			"axe_found": {"objectives_done": 1, "status": "You pulled Rendel's axe from the stump. Bring it home to Beth."},
			STATE_COMPLETED: {"objectives_done": 2, "status": "Completed. Rendel's axe hangs over Beth's hearth."},
		},
		"events": [
			{"type": "collect", "target": "rendels_axe", "requires_state": STATE_ACCEPTED, "sets_state": "axe_found"},
		],
		"talks": [
			{
				"npc": "beth",
				"requires_state": "axe_found",
				"sets_state": STATE_COMPLETED,
				"pages": [
					"Is that... *Beth reaches out and touches the axe handle, worn pale where his hands held it.*",
					"He carved our initials into the haft the day we married. See? R and B, and a little crooked heart. He was never any good at hearts.",
					"I'll hang it over the hearth. Then he's home, isn't he? In a way. *She smiles, wet-eyed.* Corwin sent you? Bless that gruff old man.",
					"Here, take his whetstone. An axe is no good without one, and you'll need a sharp edge out there more than I will.\n\nYou received Rendel's Whetstone.",
				],
			},
		],
		"npc_lines": {
			"corwin": {
				"axe_found": ["You found it? Then don't show it to me. Take it to Beth. It's hers now."],
			},
		},
		"reward": {
			"name": "Rendel's Whetstone",
			"description": "A grey whetstone worn into a shallow curve by years of Rendel's strokes. Beth said an axe is no good without one, and that you'd need a sharp edge more than she would.",
		},
		"gold": 25,
		"experience": 100,
		"dialogue": {
			STATE_AVAILABLE: [
				"You're the one who found Rendel's coat. *He's quiet for a while.* I hunted with him, when we were young. Best tracker in Oblath, and he chose to cut trees.",
				"He had a spot he loved. North-east of here, a clearing of old stumps where the oaks grow straight. He said the wood there sang when it split.",
				"If he went down out there, his axe may still be lying where he left it. Beth should have it. A coat's a sad thing to remember a man by.",
				"Will you go and look?",
			],
			"accepted_reply": [
				"North-east, past the big oaks. Look for fresh stumps and a lot of woodchips. He never cleaned up after himself.",
			],
			"declined_reply": [
				"Aye. Maybe it's better left. *He doesn't sound like he believes it.*",
			],
			STATE_ACCEPTED: [
				"North-east, a clearing of stumps. You'll know it - the woodchips go on forever.",
			],
			STATE_COMPLETED: [
				"Beth came out to the road to thank me. Didn't know what to say. Never do.",
			],
		},
	},
	LOST_PIP: {
		"title": "Where Did Pip Go?",
		"type": "Rescue",
		"giver": "Sarah",
		"giver_id": "sarah",
		"giver_location": "Oblath",
		"area": 1,
		"summary": "Sarah's son Pip, eight years old and fearless in the worst way, followed a fox kit out of the south gate this morning. He hasn't come back, and the forest is crawling with wolves.",
		"objectives": [
			"Find Pip in the woods south-east of the forest road",
			"Drive off the wolves circling him",
			"Send Pip home",
			"Return to Sarah in Oblath",
		],
		"stages": {
			STATE_ACCEPTED: {"objectives_done": 0, "status": "Search the woods south-east of the forest road for Pip."},
			"pip_found": {"objectives_done": 1, "status": "Wolves are circling Pip! Drive them off."},
			"pip_safe": {"objectives_done": 2, "status": "The wolves are dead. Talk to Pip."},
			"pip_home": {"objectives_done": 3, "status": "Pip is running home. Return to Sarah in Oblath."},
			STATE_COMPLETED: {"objectives_done": 4, "status": "Completed. Pip is home, grounded until midwinter."},
		},
		"events": [
			{"type": "find", "target": "pip", "requires_state": STATE_ACCEPTED, "sets_state": "pip_found"},
			{"type": "rescue", "target": "pip", "requires_state": "pip_found", "sets_state": "pip_safe"},
		],
		"talks": [
			{
				"npc": "pip",
				"requires_state": "pip_safe",
				"sets_state": "pip_home",
				"pages": [
					"*A small boy crawls out from behind a fallen log, eyes enormous.* Are they gone? All of them? You hit that big one SO hard.",
					"I wasn't lost. I was following Ember - she's a fox. She went in a hole. Then the wolves came and I hid and I didn't cry. Much.",
					"Mum's going to be so cross. *He sniffs.* Will you tell her I was brave? I'll run straight home, I promise. Straight down the road. No foxes.",
				],
			},
			{
				"npc": "sarah",
				"requires_state": "pip_home",
				"sets_state": STATE_COMPLETED,
				"pages": [
					"He came tearing through the gate covered in mud, shouting about a hero and a fox called Ember. *Sarah laughs and cries at once.*",
					"I could have shaken him to pieces. I hugged him instead. Then I shook him a little.",
					"He wanted you to have this. He carved it himself. It's meant to be a fox. I think. Thank you for bringing my boy home.\n\nYou received Pip's Wooden Fox.",
				],
			},
		],
		"npc_lines": {
			"pip": {
				"pip_found": ["Help! HELP! They're everywhere!"],
			},
		},
		"reward": {
			"name": "Pip's Wooden Fox",
			"description": "A lumpy little carving that is either a fox or a very determined potato. Pip made it for the hero who saved him, and named it Ember the Second.",
		},
		"gold": 35,
		"experience": 120,
		"dialogue": {
			STATE_AVAILABLE: [
				"Please - have you seen a little boy? This high, freckles, a hole in the knee of his trousers?",
				"My Pip. He saw a fox kit by the south gate this morning and off he went after it, before I could catch his collar.",
				"The guards say they saw him running for the trees south-east of the forest road. That was hours ago.",
				"He's only eight. He thinks wolves are big dogs. Please, find him!",
			],
			"accepted_reply": [
				"Thank you, thank you. South-east of the forest road. He'll be wherever there's trouble - that's where he always is.",
			],
			"declined_reply": [
				"Then I'll go myself. *She looks toward the gate, white-knuckled.* Somebody has to.",
			],
			STATE_ACCEPTED: [
				"Any sign of him? South-east of the road. Please hurry.",
			],
			"pip_found": [
				"You found him? Wolves?! Then why are you here? Go!",
			],
			"pip_safe": [
				"He's safe? Then where is he? Bring him home!",
			],
			STATE_COMPLETED: [
				"Pip's grounded until midwinter. He tells everyone about you. Every single day.",
			],
		},
	},
	SCAR_EAR_BOUNTY: {
		"title": "Bounty: Old Scar-Ear",
		"type": "Bounty",
		"giver": "the notice board",
		"giver_id": "notice_board",
		"giver_location": "Oblath",
		"area": 1,
		"summary": "A bounty posted by the reeve of Oblath: a grizzled wolf with one ragged ear has killed four sheep, two dogs and the reeve's prize goose. It prowls the far east of the Forest Outskirts. The purse is held at the tavern.",
		"objectives": [
			"Hunt down Old Scar-Ear in the far east of the Forest Outskirts",
			"Claim the bounty from Elsa at the tavern",
		],
		"stages": {
			STATE_ACCEPTED: {"objectives_done": 0, "status": "Track Old Scar-Ear in the far east of the forest."},
			"scar_ear_slain": {"objectives_done": 1, "status": "Old Scar-Ear is dead. Claim the bounty from Elsa, outside the tavern in Oblath."},
			STATE_COMPLETED: {"objectives_done": 2, "status": "Completed. The reeve's goose is avenged."},
		},
		"events": [
			{"type": "kill", "target": "scar_ear", "requires_state": STATE_ACCEPTED, "sets_state": "scar_ear_slain"},
		],
		"talks": [
			{
				"npc": "elsa",
				"requires_state": "scar_ear_slain",
				"sets_state": STATE_COMPLETED,
				"pages": [
					"That's Scar-Ear's ear, all right - I'd know that notch anywhere. He had a go at my ankles last spring.",
					"*Elsa counts coins out of a leather purse onto her tray.* The reeve's bounty, all of it. He'll want to hear the story, mind. Several times.",
					"And a drink on the house. Don't tell the regulars.",
				],
			},
		],
		"gold": 75,
		"experience": 150,
		"dialogue": {
			STATE_AVAILABLE: [
				"BOUNTY. By order of the Reeve of Oblath.",
				"A grey wolf with one torn ear, known as OLD SCAR-EAR, has killed four sheep, two dogs, and Lady Honk, the reeve's prize goose.",
				"The beast prowls the far east of the Forest Outskirts, beyond the forest road. It is larger than its kin, and cunning.",
				"A purse of 75 gold to whoever brings proof of its death. Purse held by Elsa at the tavern. Take the notice?",
			],
			"accepted_reply": [
				"You tear the notice from the board and fold it into your pack. Somebody has drawn a little goose with a halo in the corner.",
			],
			"declined_reply": [
				"You leave the notice where it hangs. A breeze flaps its corner, as if waving goodbye to the goose.",
			],
			STATE_ACCEPTED: [
				"A clean space on the board where the bounty notice used to hang.",
			],
			"scar_ear_slain": [
				"A fresh notice in the reeve's hand: 'Bounties to be claimed from Elsa at the tavern. Do NOT bring the evidence inside.'",
			],
			STATE_COMPLETED: [
				"Someone has pinned a drawing of a wolf with a cross through it beside a goose wearing a crown.",
			],
		},
	},
	WAYFIRES: {
		"title": "The Wayfires",
		"type": "Exploration",
		"giver": "the Mossy Shrine",
		"giver_id": "forest_shrine",
		"giver_location": "the Forest Outskirts",
		"area": 1,
		"summary": "A moss-covered shrine stands north of the forest road. Its inscription tells of three wayfires that once burned in the forest to guide travellers home, and asks a passer-by to kindle them again.",
		"objectives": [
			"Light the 3 wayfires in the northern Forest Outskirts",
			"Return to the Mossy Shrine",
		],
		"stages": {
			STATE_ACCEPTED: {"objectives_done": 0, "status": "Find and light the old wayfires in the north of the forest.", "counter": {"label": "Wayfires lit", "count": 3}},
			"fires_lit": {"objectives_done": 1, "status": "All three wayfires burn again. Return to the Mossy Shrine."},
			STATE_COMPLETED: {"objectives_done": 2, "status": "Completed. The wayfires guide travellers home once more."},
		},
		"events": [
			{"type": "collect", "target": "wayfire", "requires_state": STATE_ACCEPTED, "sets_state": "fires_lit", "count": 3},
		],
		"talks": [
			{
				"npc": "forest_shrine",
				"requires_state": "fires_lit",
				"sets_state": STATE_COMPLETED,
				"pages": [
					"As you lay a hand on the shrine, the moss stirs. Three thin threads of smoke rise above the trees to the north, and the old stone grows warm.",
					"New words glow in the carving where there were none: 'Lost ones find the road. Wanderers find the hearth. Kindler, be welcome.'",
					"A small ember-red stone rolls from a crack in the shrine into your palm. It stays warm.\n\nYou received a Shrine Ember.",
				],
			},
		],
		"reward": {
			"name": "Shrine Ember",
			"description": "A smooth red stone, always warm to the touch, given up by the Mossy Shrine when the wayfires burned again. On cold nights it glows faintly, like a coal remembering a fire.",
		},
		"gold": 20,
		"experience": 150,
		"dialogue": {
			STATE_AVAILABLE: [
				"An old shrine, furred with moss. Someone has scraped the moss from its face, revealing a carving of a figure carrying a torch through trees.",
				"The inscription reads: 'Three fires burn in the northern wood, that none who walk here walk lost. Should the fires fail, kindle them, traveller, and be blessed.'",
				"The stone is cold. Somewhere to the north, the old wayfires have gone dark. Will you kindle them?",
			],
			"accepted_reply": [
				"You touch the carving. For a moment, three faint warm points pulse in your mind, scattered through the northern woods.",
			],
			"declined_reply": [
				"You leave the shrine to its moss. The carved traveller's torch looks colder than before.",
			],
			STATE_ACCEPTED: [
				"The shrine is cold. The wayfires in the northern wood still wait to be kindled.",
			],
			STATE_COMPLETED: [
				"The shrine is warm, and the moss around it is studded with tiny white flowers.",
			],
		},
	},
	PERRYS_HAT: {
		"title": "Perry's New Hat",
		"type": "Escort",
		"giver": "Perry",
		"giver_id": "perry",
		"giver_location": "the forest trail",
		"area": 1,
		"summary": "Perry, a cheerful old wanderer, has been lost on the forest trail all morning. He's on his way to Oblath to spend a year's savings on a new hat - green, with a feather - and asked you to show him the way.",
		"objectives": [
			"Walk the forest trail with Perry",
			"Take Perry's hat",
			"Enter Oblath through the town gate",
		],
		"stages": {
			STATE_ACCEPTED: {"objectives_done": 0, "status": "Lead Perry down the trail to the gate of Oblath."},
			"perry_fell": {"objectives_done": 1, "status": "Perry fell into a hidden spike pit and did not survive. His hat lies at the edge."},
			"hat_taken": {"objectives_done": 2, "status": "Carry Perry's hat on to the gate of Oblath."},
			STATE_COMPLETED: {"objectives_done": 3, "status": "Completed. You reached Oblath. Perry never got his new hat."},
		},
		"events": [
			{"type": "fall", "target": "perry", "requires_state": STATE_ACCEPTED, "sets_state": "perry_fell"},
			{"type": "collect", "target": "perrys_hat", "requires_state": "perry_fell", "sets_state": "hat_taken"},
			{"type": "enter", "target": "oblath", "requires_state": "hat_taken", "sets_state": STATE_COMPLETED},
		],
		"reward": {
			"name": "Perry's Old Hat",
			"description": "A moth-eaten felt hat with a hole in the crown, taken from the edge of a hunter's spike pit on the trail to Oblath. Perry wore it for forty years and was on his way to replace it.",
		},
		"gold": 15,
		"experience": 60,
		"dialogue": {
			STATE_AVAILABLE: [
				"Oh! Oh, thank goodness, a person. A real one. I've been talking to that tree for an hour, and it's terrible company.",
				"Name's Perry. I'm trying to get to Oblath, but this trail keeps going round in circles. Or I do. One of us does.",
				"See this hat? *He lifts a felt hat riddled with moth holes. A tuft of grey hair pokes through the crown.* Forty years I've worn it. Today, I buy a new one.",
				"The hatter in Oblath has a green one with a feather in the window. I've saved all year. Would you take me there? I'll stay right behind you. You won't even know I'm there.",
			],
			"accepted_reply": [
				"Splendid! Lead the way, friend. Green, with a feather. Did I mention the feather?",
			],
			"declined_reply": [
				"Oh. Well. I'll just... wait here, then. With the tree. Maybe it knows the way.",
			],
			STATE_ACCEPTED: [
				"Right behind you! Lead on. I can practically feel that feather already.",
			],
			STATE_COMPLETED: [
				"...",
			],
		},
	},
	ROAD_TO_SALTWIND: {
		"title": "The Road to Saltwind",
		"type": "Journey",
		"giver": "Rashid",
		"giver_id": "rashid",
		"giver_location": "Oblath",
		"area": 1,
		"requires_level": 1,
		"summary": "With the Forest Outskirts secured, a camel-driver named Rashid has come north to Oblath with word from Saltwind Camp. The caravans that cross the Sunscorch Sands are vanishing, and Caravan Master Idris is asking for whoever broke the wolf packs.",
		"objectives": [
			"Join Rashid's caravan in Oblath",
			"Reach Saltwind Camp, at the edge of the Sunscorch Sands",
		],
		"stages": {
			STATE_ACCEPTED: {"objectives_done": 1, "status": "Rashid's caravan is ready to leave. Talk to him in Oblath to set out for Saltwind Camp."},
			STATE_COMPLETED: {"objectives_done": 2, "status": "Completed. You reached Saltwind Camp. The Sunscorch Sands lie east."},
		},
		# Talking to Rashid in this state (as accepting does) sets out for the hub of level 2.
		"travel": {"hub": 2, "requires_state": STATE_ACCEPTED},
		"events": [
			{"type": "arrive", "target": "hub_2", "requires_state": STATE_ACCEPTED, "sets_state": STATE_COMPLETED},
		],
		"reward": {
			"name": "Caravan Bell",
			"description": "A dented brass bell from the neck of Rashid's lead camel. Saltwind drivers hang one on every beast so the caravan can find itself in a sandstorm. Rashid says it rang the whole way south, and he'd rather you kept it.",
		},
		"gold": 40,
		"experience": 150,
		"dialogue": {
			STATE_AVAILABLE: [
				"*A sunburnt man in a dusty turban looks up from his camel's harness.* You. The one they say cleared the wolves from the forest road? Then the stars are kind to me at last.",
				"I am Rashid. I drive for Caravan Master Idris, out of Saltwind Camp, far to the south where the forest gives way to sand.",
				"Three caravans left Saltwind this season. One came back, empty. Scorpions the size of carts, the drivers say, and the sand moving against the wind. Something old is waking under the Sunscorch Sands.",
				"Idris sent me north to find someone who can fight what we cannot. My camels are rested and the water is loaded. Will you ride south with me to Saltwind Camp?",
			],
			"accepted_reply": [
				"Ha! I knew it. Climb up beside me, and mind the grey one, she bites.",
				"It is a long road, but the camels know it better than I do. When you wake, you will taste salt on the wind. Hold on!",
			],
			"declined_reply": [
				"Not yet? I understand. A road like that wants a ready traveller. I'll be here with the camels when you are.",
			],
			STATE_ACCEPTED: [
				"There you are! The camels are loaded and the grey one is in a mood. Climb up, we leave now.",
			],
			STATE_COMPLETED: [
				"Saltwind! Smell that? Salt, smoke and camel. Home. Go and see Idris by the fire. And drink before you go east - the Sands take water from you like a thief.",
			],
		},
	},
	# --- The Sunscorch Sands: the main line ------------------------------------------------------------
	LAST_CARAVAN: {
		"title": "The Last Caravan",
		"type": "Search",
		"giver": "Idris",
		"giver_id": "idris",
		"giver_location": "Saltwind Camp",
		"area": 2,
		"summary": "Caravan Master Idris has lost three caravans to the Sunscorch Sands this season. The last, led by a driver named Malik, never reached the coast, and the scouts found its tracks leading east, away from the trade road. Idris wants to know why.",
		"objectives": [
			"Find the wreck of Malik's caravan in the eastern Sands",
			"Search the wreckage for Malik's ledger",
			"Bring the ledger to Idris in Saltwind Camp",
		],
		"stages": {
			STATE_ACCEPTED: {"objectives_done": 0, "status": "Search the eastern Sands for the wreck of Malik's caravan."},
			"wreck_found": {"objectives_done": 1, "status": "You found the wreck. Search it for Malik's ledger."},
			"ledger_found": {"objectives_done": 2, "status": "You have Malik's ledger. Bring it to Idris in Saltwind Camp."},
			STATE_COMPLETED: {"objectives_done": 3, "status": "Completed. Malik wasn't trading. He was digging."},
		},
		"events": [
			{"type": "find", "target": "malik_wreck", "requires_state": STATE_ACCEPTED, "sets_state": "wreck_found"},
			{"type": "collect", "target": "caravan_ledger", "requires_state": "wreck_found", "sets_state": "ledger_found"},
		],
		"talks": [
			{
				"npc": "idris",
				"requires_state": "ledger_found",
				"sets_state": STATE_COMPLETED,
				"pages": [
					"Malik's ledger. *Idris turns the pages slowly, his jaw tight.* Salt, dates, rope... and this. Forty shovels. Ten picks. Lamp oil, enough for a month underground.",
					"He wasn't trading. He was digging. The fool hired diggers on my coin and took them off the road, east, toward the old ruins.",
					"And the last page. His hand changes. 'The sand moves. Yusuf ran for the red rocks. If anyone reads this-' Nothing after.",
					"Yusuf. Malik's camel boy. If he reached the rocks, he may still be alive. Take this for your trouble, and sit a while before you go back out there.",
				],
			},
		],
		"gold": 50,
		"experience": 200,
		"dialogue": {
			STATE_AVAILABLE: [
				"So you're the one Rashid brought down from the forest. He says you broke the wolf packs that had Oblath under siege. Good. I need someone who doesn't break easily.",
				"Three caravans left Saltwind this season. The first came back empty, its drivers gone. The second we found picked clean by scorpions.",
				"The third was Malik's. Forty camels, twelve drivers, and it never reached the coast. Malik knows the trade road like his own palm, yet the scouts found his tracks leading east, away from it.",
				"Find what's left of his caravan. And find out why he left the road. Will you go?",
			],
			"accepted_reply": [
				"The trail out of camp takes you into the Sands. Malik's tracks bent east, past the dunes. Look for broken wagons, and for vultures. They always find a wreck first.",
			],
			"declined_reply": [
				"Rest, then. The Sands will keep. They always do.",
			],
			STATE_ACCEPTED: [
				"East, past the dunes. Watch for the vultures.",
			],
			"wreck_found": [
				"You found it? Then search it. Malik kept his ledger on him, always. If it's anywhere, it's in his wagon.",
			],
			STATE_COMPLETED: [
				"Malik was a good driver once. Greed got into him like sand into a wound.",
			],
		},
	},
	VOICE_IN_THE_DUNES: {
		"title": "A Voice in the Dunes",
		"type": "Rescue",
		"giver": "Idris",
		"giver_id": "idris",
		"giver_location": "Saltwind Camp",
		"area": 2,
		"requires": [LAST_CARAVAN],
		"summary": "Malik's ledger ends with his camel boy, Yusuf, running for the red rocks in the south of the Sands. If he found shelter there he may still be alive, and he may be the only one who saw what Malik dug up.",
		"objectives": [
			"Search the red rocks in the southern Sands for Yusuf",
			"Kill the snakes that have him cornered",
			"Talk to Yusuf",
			"Return to Idris in Saltwind Camp",
		],
		"stages": {
			STATE_ACCEPTED: {"objectives_done": 0, "status": "Search the red rocks in the south of the Sands for Yusuf."},
			"yusuf_found": {"objectives_done": 1, "status": "Snakes have Yusuf cornered! Kill them."},
			"yusuf_safe": {"objectives_done": 2, "status": "The snakes are dead. Talk to Yusuf."},
			"yusuf_home": {"objectives_done": 3, "status": "Yusuf is making for Saltwind Camp. Return to Idris."},
			STATE_COMPLETED: {"objectives_done": 4, "status": "Completed. Yusuf is safe in Saltwind, and you know what Malik found."},
		},
		"events": [
			{"type": "find", "target": "yusuf", "requires_state": STATE_ACCEPTED, "sets_state": "yusuf_found"},
			{"type": "rescue", "target": "yusuf", "requires_state": "yusuf_found", "sets_state": "yusuf_safe"},
		],
		"talks": [
			{
				"npc": "yusuf",
				"requires_state": "yusuf_safe",
				"sets_state": "yusuf_home",
				"pages": [
					"*A thin boy in a torn headscarf peers out from a crack in the red rock, clutching an empty waterskin.* Are they dead? The snakes? They've waited for me for days. Snakes are very patient.",
					"I'm Yusuf. I tend Malik's camels. He said we were going to the coast, but at the dunes he turned us east, to the old city. Qasr Anuhm. He said there was gold under it.",
					"There wasn't gold. There was a door. Malik broke it open, and something under there... breathed. Then the sand began to move, and the scorpions came out of it like water.",
					"I ran. I didn't stop until I was here. *He looks at his hands.* I left them, all of them. Is Saltwind still there? Then I'll go. I know the way from here.",
				],
			},
			{
				"npc": "idris",
				"requires_state": "yusuf_home",
				"sets_state": STATE_COMPLETED,
				"pages": [
					"Yusuf walked in an hour ago, half dead and talking about doors and breathing sand. Farah's feeding him. He'll live.",
					"Qasr Anuhm. The city the sand ate. Every child in this camp grows up on stories of it, and every one is told never to dig there.",
					"Malik broke something old. *Idris looks east, toward the dunes.* Talk to Old Hamid. He knows those stories better than anyone alive, and I'd stake my water he knows more than he tells.",
					"Oh - and Yusuf asked me to give you this. He says it kept him alive in the rocks, and that you need it more now.\n\nYou received Yusuf's Lucky Knot.",
				],
			},
		],
		"npc_lines": {
			"yusuf": {
				"yusuf_found": ["Help! Please! They're all around me!"],
			},
		},
		"reward": {
			"name": "Yusuf's Lucky Knot",
			"description": "A camel-hair cord tied in a knot nobody else in Saltwind can undo. Yusuf swears it kept him alive for eight days in the red rocks, and insisted you needed it more than he did.",
		},
		"gold": 60,
		"experience": 250,
		"dialogue": {
			STATE_AVAILABLE: [
				"Malik's camel boy, Yusuf. Fourteen, maybe fifteen. Quick on his feet, quicker with his mouth.",
				"If he reached the red rocks in the south, there's shade there, and a seep of water. A boy could last a week. Maybe.",
				"It's been eight days. Will you look for him?",
			],
			"accepted_reply": [
				"South, where the sand turns red. Bring him home if you can. If you can't... bring me his name, at least.",
			],
			"declined_reply": [
				"Then I'll send Tarek. He's needed here, but a boy's life is a boy's life.",
			],
			STATE_ACCEPTED: [
				"The red rocks, in the south. Hurry.",
			],
			"yusuf_found": [
				"Then why are you standing here? Go!",
			],
			"yusuf_safe": [
				"He's alive? Then get him moving before the next nest finds him.",
			],
			STATE_COMPLETED: [
				"Yusuf's asking to ride with the next caravan. Brave or foolish. Same thing, at his age.",
			],
		},
	},
	CITY_THE_SAND_ATE: {
		"title": "The City the Sand Ate",
		"type": "Lore",
		"giver": "Old Hamid",
		"giver_id": "hamid",
		"giver_location": "Saltwind Camp",
		"area": 2,
		"requires": [VOICE_IN_THE_DUNES],
		"summary": "Old Hamid knows the stories of Qasr Anuhm, a city of sun-priests swallowed by the sand in a single season. A scholar from the coast, Imani, has been camped in its ruins for months. Hamid wants you to find her before Malik's mistake does.",
		"objectives": [
			"Travel to the ruins of Qasr Anuhm, north-east in the Sands",
			"Find the scholar Imani's camp",
		],
		"stages": {
			STATE_ACCEPTED: {"objectives_done": 0, "status": "Travel to the ruins of Qasr Anuhm in the north-east of the Sands."},
			"ruins_reached": {"objectives_done": 1, "status": "You've reached Qasr Anuhm. Find the scholar Imani's camp among the ruins."},
			STATE_COMPLETED: {"objectives_done": 2, "status": "Completed. Imani is alive, and she knows what Malik broke."},
		},
		"events": [
			{"type": "find", "target": "qasr_anuhm", "requires_state": STATE_ACCEPTED, "sets_state": "ruins_reached"},
		],
		"talks": [
			{
				"npc": "imani",
				"requires_state": "ruins_reached",
				"sets_state": STATE_COMPLETED,
				"pages": [
					"*A woman in ink-stained robes looks up from a slab of stone, a stick of charcoal behind each ear.* Oh! A person. With a weapon. If you're here to rob me, I own nothing but paper.",
					"Hamid sent you? Then he finally believes me. I wrote him four letters. He answered none of them.",
					"I'm Imani, of the Library at Qasim. I came to read the obelisks of Qasr Anuhm. Then, nine days ago, the ground shook and every scorpion in the Sands woke up angry.",
					"Someone opened the vault under the city. I'm sure of it. And the obelisks say exactly what that means, if only I can read them before something eats me.",
				],
			},
		],
		"gold": 40,
		"experience": 200,
		"dialogue": {
			STATE_AVAILABLE: [
				"*The old man doesn't look up from the fire.* Yusuf told you about the door. Sit, then. You'll want to be sitting.",
				"Long ago, before Saltwind, before the trade road, there was a city east of here. Qasr Anuhm. Its priests wore gold and worshipped the sun, and they were afraid of something under the sand.",
				"In one season the sand rose and swallowed the city whole. The stories say the priests did it themselves, to bury what they feared.",
				"Your forest wolves - the great black one. It came north last spring, didn't it, when the ground first trembled? The beasts always know first.",
				"A scholar from the coast, Imani, is camped in those ruins. Stubborn as a mule. Find her before whatever Malik woke finds her. Will you go?",
			],
			"accepted_reply": [
				"North-east, where the pillars stick up out of the dunes like old teeth. She'll be the one arguing with a rock.",
			],
			"declined_reply": [
				"Hm. The sand has waited three hundred years. It can wait an evening.",
			],
			STATE_ACCEPTED: [
				"Qasr Anuhm. North-east. Go on.",
			],
			"ruins_reached": [
				"You've seen the city, then. Did you find Imani?",
			],
			STATE_COMPLETED: [
				"So she's alive. Good. She wrote me letters, you know. I couldn't bring myself to answer them.",
			],
		},
	},
	WORDS_IN_STONE: {
		"title": "Words in Stone",
		"type": "Exploration",
		"giver": "Imani",
		"giver_id": "imani",
		"giver_location": "the ruins of Qasr Anuhm",
		"area": 2,
		"requires": [CITY_THE_SAND_ATE],
		"summary": "Three obelisks still stand around Qasr Anuhm, each carved with part of the priests' last decree. Imani has never dared cross the scorpion nests to reach them, and needs their inscriptions copied.",
		"objectives": [
			"Copy the inscriptions of the 3 obelisks around Qasr Anuhm",
			"Bring the rubbings to Imani",
		],
		"stages": {
			STATE_ACCEPTED: {"objectives_done": 0, "status": "Find the three obelisks around Qasr Anuhm and copy their inscriptions.", "counter": {"label": "Obelisks copied", "count": 3}},
			"obelisks_read": {"objectives_done": 1, "status": "You've copied all three inscriptions. Bring them to Imani."},
			STATE_COMPLETED: {"objectives_done": 2, "status": "Completed. The obelisks name what sleeps beneath the city: the First Sting."},
		},
		"events": [
			{"type": "collect", "target": "obelisk", "requires_state": STATE_ACCEPTED, "sets_state": "obelisks_read", "count": 3},
		],
		"talks": [
			{
				"npc": "imani",
				"requires_state": "obelisks_read",
				"sets_state": STATE_COMPLETED,
				"pages": [
					"*Imani spreads the rubbings across her table and pins the corners with stones.* Here, the sun-disc. Here, the coiled tail. And here... oh. Oh, no.",
					"'Beneath us sleeps the First Sting, mother of all that crawls. We have bound her with the Sunstone and buried our city as her tomb. Let none open the door, lest the stone crack and she wake.'",
					"The Sunstone was the seal. If Malik broke the door, he may have broken the stone too. That's why the brood has gone mad. Their mother is stirring.",
					"*She presses a slim cedar case into your hands.* Take this. My grandmother's brush-case. I've copied enough for three lifetimes, and you've earned it.\n\nYou received Imani's Brush-Case.",
				],
			},
		],
		"reward": {
			"name": "Imani's Brush-Case",
			"description": "A slim cedar case holding three worn brushes and a stick of charcoal. Imani has copied the inscriptions of a dozen dead cities with them, and says they want to see more of the world.",
		},
		"gold": 50,
		"experience": 250,
		"dialogue": {
			STATE_AVAILABLE: [
				"Now that you're here, I can finally finish my work. Will you help? You look like someone scorpions are afraid of.",
				"Three obelisks still stand around the city - north, east and south of here. Each carries part of the priests' last decree.",
				"I've only ever read them through a spyglass. The nests are too thick. Walk out to each one and copy its carving: hold the paper to the stone and rub the charcoal across it.",
				"Will you read them for me?",
			],
			"accepted_reply": [
				"Wonderful! Take paper. Take charcoal. Take care. In that order, academically speaking. In the opposite order, personally.",
			],
			"declined_reply": [
				"Of course. I'll just keep squinting through the spyglass. For the fifth month.",
			],
			STATE_ACCEPTED: [
				"Three obelisks: north, east and south of the city. The carvings face the sun.",
			],
			"obelisks_read": [
				"You have all three? Give them here, quickly!",
			],
			STATE_COMPLETED: [
				"The First Sting. Three hundred years asleep, and one greedy man with a shovel. History is mostly greedy men with shovels.",
			],
		},
	},
	SUNKEN_VAULT: {
		"title": "The Sunken Vault",
		"type": "Dungeon",
		"giver": "Imani",
		"giver_id": "imani",
		"giver_location": "the ruins of Qasr Anuhm",
		"area": 2,
		"requires": [WORDS_IN_STONE],
		"summary": "Malik broke open the vault beneath Qasr Anuhm and cracked the Sunstone that kept the First Sting asleep. Imani believes the pieces still lie inside - but something vast has coiled itself in the vault since the door was opened.",
		"objectives": [
			"Go down the broken stair into the vault beneath Qasr Anuhm",
			"Defeat Venomcoil, the serpent of the vault",
			"Gather the 3 shards of the Sunstone",
			"Take the shards to Old Hamid in Saltwind Camp",
		],
		"stages": {
			STATE_ACCEPTED: {"objectives_done": 0, "status": "Find the broken stair in the heart of Qasr Anuhm and go down into the vault."},
			"entered": {"objectives_done": 1, "status": "Something vast slides through the dark. Defeat Venomcoil."},
			"serpent_slain": {"objectives_done": 2, "status": "Venomcoil is dead. Gather the shards of the Sunstone.", "counter": {"label": "Shards", "count": 3}},
			"shards_found": {"objectives_done": 3, "status": "You hold all three shards of the Sunstone. Take them to Old Hamid in Saltwind Camp."},
			STATE_COMPLETED: {"objectives_done": 4, "status": "Completed. Hamid has the Sunstone, and he's finally told you the truth."},
		},
		"events": [
			{"type": "enter", "target": "sunken_vault", "requires_state": STATE_ACCEPTED, "sets_state": "entered"},
			{"type": "kill", "target": "venomcoil", "requires_state": "entered", "sets_state": "serpent_slain"},
			{"type": "collect", "target": "sunstone_shard", "requires_state": "serpent_slain", "sets_state": "shards_found", "count": 3},
		],
		"talks": [
			{
				"npc": "hamid",
				"requires_state": "shards_found",
				"sets_state": STATE_COMPLETED,
				"pages": [
					"*Hamid holds the three shards in his open palm. In his hands they begin to glow, faint as embers, and he doesn't seem surprised.*",
					"Imani sent you to me because she guessed. Clever girl. Yes. My family were Sunkeepers. When the city went under, one priest walked out of the sand to keep the old knowledge. I am the last of his line.",
					"I could have warned Malik. I could have warned everyone. Instead I sat by this fire for forty years, telling stories as if they were only stories.",
					"No more. I can mend the Sunstone. It will take until dawn. Come back to me when you're ready to finish what my family began.",
				],
			},
		],
		"npc_lines": {
			"imani": {
				"shards_found": ["You have them all? Then go! Take them to Hamid. He'll know what to do. I'm almost sure. Mostly sure."],
			},
		},
		"reward": {
			"name": "Venomcoil's Fang",
			"description": "A hooked fang as long as your hand, still beaded with yellow venom that never quite dries. Pried from the serpent that coiled in the vault beneath Qasr Anuhm.",
		},
		"gold": 80,
		"experience": 350,
		"dialogue": {
			STATE_AVAILABLE: [
				"If the Sunstone cracked, its pieces must still be down there. Stone doesn't walk off. Usually.",
				"The stair to the vault is in the heart of the ruins, beneath the fallen arch. I went down three steps once and heard something slide across the floor below. Something very long.",
				"Bring the pieces out, all of them. Then take them to Hamid. Don't argue, just take them to him. I have a theory about Hamid.",
				"Will you go down?",
			],
			"accepted_reply": [
				"Thank you. And if the long sliding thing is what I think it is - aim for the head. That's general advice. It applies to most things.",
			],
			"declined_reply": [
				"No, no. Very sensible. I wouldn't go down there either. I didn't, in fact.",
			],
			STATE_ACCEPTED: [
				"The stair is beneath the fallen arch, in the heart of the ruins.",
			],
			"entered": [
				"You went down? And came back up? That's the best possible order.",
			],
			"serpent_slain": [
				"The serpent's dead? Then the shards! Find all three!",
			],
			STATE_COMPLETED: [
				"Hamid, a Sunkeeper. I knew it. Four letters, and he never once said.",
			],
		},
	},
	MOTHER_OF_STINGS: {
		"title": "The Mother of Stings",
		"type": "Climax",
		"giver": "Old Hamid",
		"giver_id": "hamid",
		"giver_location": "Saltwind Camp",
		"area": 2,
		"requires": [SUNKEN_VAULT],
		"summary": "Hamid has mended the Sunstone. To seal the First Sting again it must be set in the dais at the heart of the vault - and the moment it is, she will wake fully and fight to stop it. If she dies, her brood loses its hold on the Sands.",
		"objectives": [
			"Return to the vault beneath Qasr Anuhm",
			"Set the mended Sunstone in the seal",
			"Destroy the First Sting",
			"Return to Caravan Master Idris in Saltwind Camp",
		],
		"stages": {
			STATE_ACCEPTED: {"objectives_done": 0, "status": "Take the mended Sunstone back down into the vault beneath Qasr Anuhm."},
			"in_the_deep": {"objectives_done": 1, "status": "The seal-dais waits at the heart of the vault. Set the Sunstone in it."},
			"seal_set": {"objectives_done": 2, "status": "The First Sting has woken! Destroy her before she breaks the seal."},
			"sting_slain": {"objectives_done": 3, "status": "The First Sting is dead and the seal holds. Return to Idris in Saltwind Camp."},
			STATE_COMPLETED: {"objectives_done": 4, "status": "Completed. The First Sting is dead, the Sunstone holds, and the Sands are quiet."},
		},
		"events": [
			{"type": "enter", "target": "sunken_vault", "requires_state": STATE_ACCEPTED, "sets_state": "in_the_deep"},
			{"type": "collect", "target": "sun_seal", "requires_state": "in_the_deep", "sets_state": "seal_set"},
			{"type": "kill", "target": "first_sting", "requires_state": "seal_set", "sets_state": "sting_slain"},
		],
		"talks": [
			{
				"npc": "idris",
				"requires_state": "sting_slain",
				"sets_state": STATE_COMPLETED,
				"pages": [
					"*The whole camp has gathered round the fire. When you walk in, nobody speaks. Then Samir starts cheering, and everyone follows.*",
					"Hamid told us everything. The Sunkeepers, the seal, the First Sting. And then the ground stopped shaking, and the scorpions went back into the sand as if they'd been called home.",
					"I've buried too many drivers this season. Tonight, for the first time, I think I won't have to bury any more.",
					"Take this. It came down from the first caravan master ever to cross the Sands. I can't think of anyone who's earned it more.\n\nYou received Idris's Sun-Compass.",
				],
			},
		],
		"npc_lines": {
			"hamid": {
				"sting_slain": ["It's done? Then my family's watch is over. Go to Idris. Let the camp hear it from you."],
			},
			"imani": {
				"in_the_deep": ["Hamid told me. Go down, set the stone. I'll be writing all of this down. Try to survive. It makes a better ending."],
			},
		},
		"reward": {
			"name": "Idris's Sun-Compass",
			"description": "A brass sun-compass with a gnomon shaped like a camel's neck, handed down from the first caravan master to cross the Sunscorch Sands. Idris says it has never once pointed the wrong way home.",
		},
		"gold": 150,
		"experience": 600,
		"dialogue": {
			STATE_AVAILABLE: [
				"*Hamid is still at the fire, burned down now to coals. In his lap lies a disc of pale stone, whole again and faintly warm.* It's done. The Sunstone is mended.",
				"Listen to me. When the stone is set in the seal, she will feel it. She will wake fully, and she will come for the hand that set it.",
				"My ancestors buried a city to keep her asleep. We don't have a city to spare. We have you.",
				"Take the stone down into the vault and set it in the dais at its heart. Then kill her, while she's still weak from her long sleep. Will you do this?",
			],
			"accepted_reply": [
				"*He places the warm stone in your hands.* The sun goes with you. Come back alive. I'm too old to tell this story without a happy ending.",
			],
			"declined_reply": [
				"Then rest. But not for long. Every night she sleeps a little less.",
			],
			STATE_ACCEPTED: [
				"The vault beneath Qasr Anuhm. Set the stone in the dais, and be ready.",
			],
			"seal_set": [
				"She's awake. I felt it from here. Kill her!",
			],
			STATE_COMPLETED: [
				"Forty years I sat at this fire, afraid of a story. Thank you for ending it.",
			],
		},
	},
	# --- The Sunscorch Sands: Saltwind Camp's side quests ---------------------------------------------
	STONES_FOR_THE_LOST: {
		"title": "Stones for the Lost",
		"type": "Remembrance",
		"giver": "Leila",
		"giver_id": "leila",
		"giver_location": "Saltwind Camp",
		"area": 2,
		"requires": [LAST_CARAVAN],
		"summary": "Leila's brother Karim drove for Malik's caravan. The drivers who fell fleeing the wreck lie in the open sand, and in Saltwind the dead are covered with stone cairns so the wind can't carry them away.",
		"objectives": [
			"Raise cairns over 3 fallen drivers south of Malik's wreck",
			"Return to Leila in Saltwind Camp",
		],
		"stages": {
			STATE_ACCEPTED: {"objectives_done": 0, "status": "Raise cairns over the fallen drivers along the trail south of Malik's wreck.", "counter": {"label": "Cairns raised", "count": 3}},
			"cairns_raised": {"objectives_done": 1, "status": "The fallen are covered. Return to Leila in Saltwind Camp."},
			STATE_COMPLETED: {"objectives_done": 2, "status": "Completed. Karim and the others rest under stone."},
		},
		"events": [
			{"type": "collect", "target": "cairn", "requires_state": STATE_ACCEPTED, "sets_state": "cairns_raised", "count": 3},
		],
		"talks": [
			{
				"npc": "leila",
				"requires_state": "cairns_raised",
				"sets_state": STATE_COMPLETED,
				"pages": [
					"You covered them? All of them? *Leila closes her eyes.* Then the wind won't have them. Thank you.",
					"Was one of them wearing a blue scarf? Karim's scarf. I dyed it myself, the year he started driving.",
					"*You nod. She is quiet for a long time.* Then he's home, in the only way the Sands allow. Here. He made this for luck. It didn't work for him. Maybe it will for you.\n\nYou received Karim's Blue Bead.",
				],
			},
		],
		"reward": {
			"name": "Karim's Blue Bead",
			"description": "A glass bead the colour of deep water, threaded on a strand of camel hair. Karim made it for luck before his first crossing. Leila gave it to you after you raised his cairn.",
		},
		"gold": 40,
		"experience": 200,
		"dialogue": {
			STATE_AVAILABLE: [
				"You found Malik's wreck. Idris told me. *She twists a strand of blue thread round her finger.* My brother Karim rode with that caravan.",
				"If he's out there, he's lying in the open. The Sands don't bury their dead. They uncover them, again and again, until there's nothing left.",
				"Here we raise stones over the fallen, so the wind can't carry them off. Will you do that for them? For Karim, and the others who fell beside him?",
			],
			"accepted_reply": [
				"The drivers who ran would have fallen along the trail south of the wreck. Stack the stones high. The wind is greedy.",
			],
			"declined_reply": [
				"I understand. It's a sad errand. I'll ask Tarek, when he has a day.",
			],
			STATE_ACCEPTED: [
				"Along the trail south of Malik's wreck. Stack the stones high.",
			],
			STATE_COMPLETED: [
				"I walk to the edge of camp each evening and face south. It helps, a little.",
			],
		},
	},
	SALVAGE_RIGHTS: {
		"title": "Salvage Rights",
		"type": "Gathering",
		"giver": "Jamal",
		"giver_id": "jamal",
		"giver_location": "Saltwind Camp",
		"area": 2,
		"requires": [LAST_CARAVAN],
		"summary": "Malik's cargo was scattered across the Sands when the scorpions struck. Jamal means to recover the spice crates before the dunes swallow them - Saltwind can't afford to lose a whole season's trade.",
		"objectives": [
			"Salvage 4 spice crates scattered across the Sands",
			"Bring word to Jamal in Saltwind Camp",
		],
		"stages": {
			STATE_ACCEPTED: {"objectives_done": 0, "status": "Search the Sands for Malik's scattered spice crates.", "counter": {"label": "Crates salvaged", "count": 4}},
			"crates_salvaged": {"objectives_done": 1, "status": "You've salvaged four crates of spice. Bring word to Jamal."},
			STATE_COMPLETED: {"objectives_done": 2, "status": "Completed. Saltwind's winter is paid for."},
		},
		"events": [
			{"type": "collect", "target": "spice_crate", "requires_state": STATE_ACCEPTED, "sets_state": "crates_salvaged", "count": 4},
		],
		"talks": [
			{
				"npc": "jamal",
				"requires_state": "crates_salvaged",
				"sets_state": STATE_COMPLETED,
				"pages": [
					"Four crates! Saffron, cumin... and is that black pepper? *Jamal sniffs a lid and sighs happily.* That's the camp's winter paid for, right there.",
					"Malik sold the best of our goods for digging money. Serves him right that the scorpions got his camels and you got his spice.",
					"Here, your cut. Salvage rights - the finder keeps a share. That's the law of the Sands. Well, it's my law. Same thing, out here.",
				],
			},
		],
		"gold": 90,
		"experience": 220,
		"dialogue": {
			STATE_AVAILABLE: [
				"See that brute on its back? It tipped a wagon with one claw. And one wagon is nothing next to Malik's whole caravan.",
				"When they hit him, the cargo went everywhere. Spice crates scattered over half the Sands. Saffron, cumin, pepper - a season's trade, lying out there in the sun.",
				"I can't leave camp; Idris needs every hand. But you're going out there anyway. Bring back what you find and I'll pay you a finder's share.",
				"Four crates should see the camp through winter. Deal?",
			],
			"accepted_reply": [
				"Look for dunes with something square poking out of them. Crates are the only square things in the Sands.",
			],
			"declined_reply": [
				"Hm. Then the sand gets it. The sand always gets it in the end.",
			],
			STATE_ACCEPTED: [
				"Four crates. Square things in the dunes. You can't miss them. You can, but you shouldn't.",
			],
			STATE_COMPLETED: [
				"The spice merchants on the coast are going to weep when they see what I'm charging.",
			],
		},
	},
	TAIL_FOR_SAMIR: {
		"title": "A Tail for Samir",
		"type": "Hunt",
		"giver": "Samir",
		"giver_id": "samir",
		"giver_location": "Saltwind Camp",
		"area": 2,
		"summary": "Samir, the youngest in Saltwind, wants a scorpion's stinger to prove he's brave enough to keep watch. Tarek says he's too small. Samir intends to prove him wrong, with your help.",
		"objectives": [
			"Slay 6 scorpions in the Sunscorch Sands",
			"Bring Samir the best stinger",
		],
		"stages": {
			STATE_ACCEPTED: {"objectives_done": 0, "status": "Slay scorpions in the Sunscorch Sands.", "counter": {"label": "Scorpions slain", "count": 6}},
			"tail_taken": {"objectives_done": 1, "status": "You cut a perfect stinger from the last one. Bring it to Samir."},
			STATE_COMPLETED: {"objectives_done": 2, "status": "Completed. Samir is on watch. Half on watch, anyway."},
		},
		"events": [
			{"type": "kill", "target": "scorpion", "requires_state": STATE_ACCEPTED, "sets_state": "tail_taken", "count": 6},
		],
		"talks": [
			{
				"npc": "samir",
				"requires_state": "tail_taken",
				"sets_state": STATE_COMPLETED,
				"pages": [
					"Is that- that's a real one! It's bigger than my arm! *Samir holds the stinger up like a sword.* Tarek! TAREK! Look!",
					"Now he has to let me keep watch. That's the rule. I made the rule just now, but it's still a rule.",
					"You can have my lucky stone. I found it at the oasis. It looks like a camel if you squint. Don't squint too hard, though.\n\nYou received Samir's Camel Stone.",
				],
			},
		],
		"reward": {
			"name": "Samir's Camel Stone",
			"description": "A smooth pebble from the oasis that looks a little like a camel, if you squint. Samir traded it to you for a scorpion stinger, which he now carries everywhere.",
		},
		"gold": 30,
		"experience": 180,
		"dialogue": {
			STATE_AVAILABLE: [
				"Are you going into the Sands? Bring me back a scorpion tail! A big one!",
				"Tarek says I'm too small to keep watch. But if I have a stinger, a real one, everyone will know I've seen scorpions and I'm not scared.",
				"You don't have to kill lots of them. Just... six? Six is a good number. Then bring me the best tail. Please?",
			],
			"accepted_reply": [
				"YES! The pointy end goes away from you, remember. Tarek told me that.",
			],
			"declined_reply": [
				"Oh. Okay. I'll ask the next hero. There's usually another one.",
			],
			STATE_ACCEPTED: [
				"Six scorpions, then the best tail! I've been practising my watching face.",
			],
			STATE_COMPLETED: [
				"I'm on watch! Well, I'm on watch with Tarek. He says that counts as half.",
			],
		},
	},
	EYES_ON_THE_DUNES: {
		"title": "Eyes on the Dunes",
		"type": "Exploration",
		"giver": "Scout Tarek",
		"giver_id": "tarek",
		"giver_location": "Saltwind Camp",
		"area": 2,
		"summary": "Scout Tarek can't watch the whole of the Sands from one lookout. He wants signal flags raised on three high rocks at the far edges of the desert, so Saltwind's watch can see trouble coming from any direction.",
		"objectives": [
			"Raise signal flags on 3 lookout rocks at the edges of the Sands",
			"Report back to Tarek",
		],
		"stages": {
			STATE_ACCEPTED: {"objectives_done": 0, "status": "Raise signal flags on the lookout rocks in the far north-west, south-west and south-east of the Sands.", "counter": {"label": "Flags raised", "count": 3}},
			"flags_raised": {"objectives_done": 1, "status": "All three flags are flying. Report back to Tarek."},
			STATE_COMPLETED: {"objectives_done": 2, "status": "Completed. Saltwind's watch can see the whole of the Sands."},
		},
		"events": [
			{"type": "collect", "target": "signal_flag", "requires_state": STATE_ACCEPTED, "sets_state": "flags_raised", "count": 3},
		],
		"talks": [
			{
				"npc": "tarek",
				"requires_state": "flags_raised",
				"sets_state": STATE_COMPLETED,
				"pages": [
					"I saw them from the lookout this morning - three red flags at the very edge of sight. Thought my eyes were lying to me.",
					"Now when a nest stirs out there, someone raises the flag and we know a day before it reaches us. A day is the difference between packing up and being buried.",
					"You've walked more of the Sands than any scout I've trained. Here, my old spyglass. My eyes are better than it is, but yours may not be.\n\nYou received Tarek's Spyglass.",
				],
			},
		],
		"reward": {
			"name": "Tarek's Spyglass",
			"description": "A dented brass spyglass whose cracked lens splits every distant dune in two. Tarek says the trick is to look through the good half.",
		},
		"gold": 50,
		"experience": 260,
		"dialogue": {
			STATE_AVAILABLE: [
				"Scorpions the size of carts out past those dunes. They bury themselves and wait. By the time I see them from here, it's too late to warn anyone.",
				"There are three tall rocks at the very edges of the Sands: far north-west, far south-west and far south-east. Old scouts' lookouts. Nobody's climbed them in years.",
				"Raise a signal flag on each, and the watch can see the whole desert from camp. Will you do it?",
			],
			"accepted_reply": [
				"Take these flags. Red for the Sands, the way it's always been. Climb high and plant them deep - the wind will try to take them.",
			],
			"declined_reply": [
				"Then we keep doing it the old way. Squinting, and hoping.",
			],
			STATE_ACCEPTED: [
				"Far north-west, far south-west, far south-east. The tallest rocks you can find.",
			],
			STATE_COMPLETED: [
				"Three flags, all still flying. You plant them well.",
			],
		},
	},
	GLASSTAIL_BOUNTY: {
		"title": "Bounty: Old Glasstail",
		"type": "Bounty",
		"giver": "the Camp Guard",
		"giver_id": "saltwind_guard",
		"giver_location": "Saltwind Camp",
		"area": 2,
		"summary": "A scorpion with a tail like clouded glass has hunted the western salt flats for twenty years. Since the ground began to shake it has turned killer, and two outriders are dead. Idris has put up a purse for its tail.",
		"objectives": [
			"Hunt down Old Glasstail on the salt flats in the far west of the Sands",
			"Claim the bounty from the Camp Guard",
		],
		"stages": {
			STATE_ACCEPTED: {"objectives_done": 0, "status": "Track Old Glasstail on the salt flats in the far west of the Sands."},
			"glasstail_slain": {"objectives_done": 1, "status": "Old Glasstail is dead. Claim the bounty from the Camp Guard in Saltwind."},
			STATE_COMPLETED: {"objectives_done": 2, "status": "Completed. The western flats are safe to ride again."},
		},
		"events": [
			{"type": "kill", "target": "glasstail", "requires_state": STATE_ACCEPTED, "sets_state": "glasstail_slain"},
		],
		"talks": [
			{
				"npc": "saltwind_guard",
				"requires_state": "glasstail_slain",
				"sets_state": STATE_COMPLETED,
				"pages": [
					"That tail... that's Glasstail's, all right. Look at it - you can see the sun through it. *He whistles.*",
					"Twenty years that thing hunted the flats. My father lost a camel to it. My uncle lost a leg. I mostly lost my nerve.",
					"Here's the purse, every coin of it. And when they sing about the flats being safe again, I'll make sure they get your name right.",
				],
			},
		],
		"gold": 120,
		"experience": 300,
		"dialogue": {
			STATE_AVAILABLE: [
				"You look like you can handle yourself. Ever hunted something older than you are?",
				"Out on the western salt flats there's a scorpion with a tail like clouded glass. Old Glasstail. It's been out there twenty years, and since the ground shook it's turned killer.",
				"Two outriders last week. Neither came back in one piece. Idris has put up a purse - 120 gold for the beast's tail.",
				"Will you take the bounty?",
			],
			"accepted_reply": [
				"Far west, where the sand turns white with salt. Watch the tail. It's faster than it looks, and it already looks fast.",
			],
			"declined_reply": [
				"No shame in it. Glasstail's killed better... well. It's killed people.",
			],
			STATE_ACCEPTED: [
				"The western salt flats. Bring me that tail.",
			],
			STATE_COMPLETED: [
				"Quiet out on the flats. Haven't been able to say that in twenty years.",
			],
		},
	},
	SWEETWATER: {
		"title": "Sweetwater",
		"type": "Exploration",
		"giver": "Nadja",
		"giver_id": "nadja",
		"giver_location": "Saltwind Camp",
		"area": 2,
		"summary": "Saltwind's oasis sinks lower every week. Nadja's grandmother said it was fed from below by the old wells of Qasr Anuhm, scattered through the Sands - and Nadja fears the shaking has choked them with sand.",
		"objectives": [
			"Clear the sand from 3 old wells out in the Sands",
			"Return to Nadja at the oasis",
		],
		"stages": {
			STATE_ACCEPTED: {"objectives_done": 0, "status": "Find the old stone wells out in the Sands and dig them clear.", "counter": {"label": "Wells cleared", "count": 3}},
			"wells_cleared": {"objectives_done": 1, "status": "All three wells are flowing again. Return to Nadja at the oasis."},
			STATE_COMPLETED: {"objectives_done": 2, "status": "Completed. The oasis is rising again."},
		},
		"events": [
			{"type": "collect", "target": "old_well", "requires_state": STATE_ACCEPTED, "sets_state": "wells_cleared", "count": 3},
		],
		"talks": [
			{
				"npc": "nadja",
				"requires_state": "wells_cleared",
				"sets_state": STATE_COMPLETED,
				"pages": [
					"Look! Look at the water line! *Nadja points to a wet stripe on the stones, a hand higher than yesterday.* It's rising. It's actually rising.",
					"My grandmother said the oasis had roots, deep under the sand, reaching for the old city's wells. Everyone laughed at her. Now I get to laugh at all of them.",
					"This came up in the water this morning. It's older than Saltwind, older than anything. I think it wants to go with you.\n\nYou received a Sunkeeper's Coin.",
				],
			},
		],
		"reward": {
			"name": "Sunkeeper's Coin",
			"description": "A worn gold coin stamped with a sun-disc, washed up in the oasis when the old wells began to flow again. It's three hundred years old and still faintly warm, as if it remembers the sun over Qasr Anuhm.",
		},
		"gold": 45,
		"experience": 240,
		"dialogue": {
			STATE_AVAILABLE: [
				"The oasis is all that keeps this camp alive. And it's sinking - a finger lower every week, ever since the ground started shaking.",
				"My grandmother said it's fed from below, by wells the old city dug. Rings of carved stone, all over the desert. If the shaking choked them...",
				"Find three of them and dig them clear. Please. Without the oasis, there is no Saltwind.",
			],
			"accepted_reply": [
				"Look for rings of carved stone half buried in the dunes. Dig them out and listen. You'll hear the water when it moves.",
			],
			"declined_reply": [
				"Then I'll keep drawing what water there is. A little less each day.",
			],
			STATE_ACCEPTED: [
				"Three wells. Rings of old stone. Dig them clear and listen for the water.",
			],
			STATE_COMPLETED: [
				"The water's still rising. Come and drink, any time. You've earned more than a sip.",
			],
		},
	},
	SUNBLOOM_STEW: {
		"title": "Sunbloom Stew",
		"type": "Gathering",
		"giver": "Farah",
		"giver_id": "farah",
		"giver_location": "Saltwind Camp",
		"area": 2,
		"summary": "Farah keeps Saltwind's cookpot going from dawn to dusk. With no caravans coming in she's out of sunbloom, the sweet red fruit of the flowering cacti that makes her stew famous.",
		"objectives": [
			"Pick 5 sunbloom fruits from flowering cacti in the Sands",
			"Bring them to Farah",
		],
		"stages": {
			STATE_ACCEPTED: {"objectives_done": 0, "status": "Pick sunbloom fruit from the flowering cacti scattered across the Sands.", "counter": {"label": "Sunblooms picked", "count": 5}},
			"blooms_picked": {"objectives_done": 1, "status": "Your pack is sticky with sunbloom. Bring them to Farah."},
			STATE_COMPLETED: {"objectives_done": 2, "status": "Completed. Saltwind eats well tonight."},
		},
		"events": [
			{"type": "collect", "target": "sunbloom", "requires_state": STATE_ACCEPTED, "sets_state": "blooms_picked", "count": 5},
		],
		"talks": [
			{
				"npc": "farah",
				"requires_state": "blooms_picked",
				"sets_state": STATE_COMPLETED,
				"pages": [
					"Sunblooms! And ripe ones - see how the skin splits? *Farah is already peeling them over the pot.* Mind the spines. Everyone forgets the spines.",
					"My mother's stew. Sunbloom, lentils and a pinch of Jamal's 'salvaged' cumin. The drivers say it tastes like coming home.",
					"*She ladles you a bowl so full it spills.* Eat. All of it. Then have another. You're too thin for someone who fights giant scorpions.",
				],
			},
		],
		"gold": 30,
		"experience": 200,
		"dialogue": {
			STATE_AVAILABLE: [
				"Eat something. Out there you won't get the chance. Though... I'm running out of things worth eating.",
				"My sunbloom stew is the only reason half these drivers come back to Saltwind. Sunblooms grow on the flowering cacti out in the Sands - fat red fruit, sweet as honey.",
				"But no caravans means no gatherers. Would you pick some for me? Five will do. Six, if you're hungry.",
			],
			"accepted_reply": [
				"Look for cacti with red fruit on top. Twist, don't pull - and mind the spines!",
			],
			"declined_reply": [
				"Then it's plain lentils again. The drivers will riot. Quietly. They're too hungry to riot loudly.",
			],
			STATE_ACCEPTED: [
				"Five sunblooms. Red fruit on the flowering cacti. Mind the spines.",
			],
			STATE_COMPLETED: [
				"The pot's never been so full. Neither have the drivers.",
			],
		},
	},
	# --- The Sunscorch Sands: on to the Ice Caves -----------------------------------------------------
	NORTH_TO_RIMEHOLLOW: {
		"title": "North to Rimehollow",
		"type": "Journey",
		"giver": "Torsten",
		"giver_id": "torsten",
		"giver_location": "Saltwind Camp",
		"area": 2,
		"requires": [MOTHER_OF_STINGS],
		"requires_level": 2,
		"summary": "Torsten, a fur-trader from Rimehollow in the frozen north, has heard how the First Sting fell. Rimehollow has a terror of its own: a cryohydra frozen in the ice the town was built around - and the ice is thinning.",
		"objectives": [
			"Join Torsten's sledge-caravan in Saltwind Camp",
			"Reach Rimehollow, above the Ice Caves",
		],
		"stages": {
			STATE_ACCEPTED: {"objectives_done": 1, "status": "Torsten's caravan is ready to leave. Talk to him in Saltwind Camp to set out for Rimehollow."},
			STATE_COMPLETED: {"objectives_done": 2, "status": "Completed. You reached Rimehollow. The Ice Caves lie below."},
		},
		# Talking to Torsten in this state (as accepting does) sets out for the hub of level 3.
		"travel": {"hub": 3, "requires_state": STATE_ACCEPTED},
		"events": [
			{"type": "arrive", "target": "hub_3", "requires_state": STATE_ACCEPTED, "sets_state": STATE_COMPLETED},
		],
		"reward": {
			"name": "Torsten's Spare Mittens",
			"description": "A pair of enormous fur mittens, each big enough to hide a loaf of bread in. Torsten insisted you take them for the road north. They smell faintly of salt and very strongly of bear.",
		},
		"gold": 50,
		"experience": 250,
		"dialogue": {
			STATE_AVAILABLE: [
				"*A huge man in a sweat-soaked bearskin waves you over, fanning himself with a mitten.* You! The scorpion-killer! They say you went under the sand and came back up with a dead god. Is it true?",
				"Good. Then you're the one I need. I am Torsten. I trade furs for salt, and I come from Rimehollow, far to the north, where the cold never leaves.",
				"Our town is built around a cryohydra frozen in the ice. We call it the Sleeper. Our grandmothers found it there. Now Elder Sigrun says the ice is thinning, and some nights it breathes.",
				"I know that look. You've only just finished with one sleeping monster. But my sledges leave for the north today. Will you come with me to Rimehollow?",
			],
			"accepted_reply": [
				"Ha! Wonderful! You'll want furs. No, you'll want MORE furs than that.",
				"The road north is long and the cold comes on fast. Sleep in the sledge if you can. When you wake, your breath will be smoke.",
			],
			"declined_reply": [
				"Not yet? I understand. The heat makes everyone slow. I'll wait. I'll melt, but I'll wait.",
			],
			STATE_ACCEPTED: [
				"The sledges are loaded! Climb in, before I melt entirely.",
			],
			STATE_COMPLETED: [
				"Ah, the cold! Breathe it in! That's what air is supposed to feel like. Go and see Elder Sigrun by the Sleeper. She's expecting you.",
			],
		},
	},
}


static func get_definition(quest_id: String) -> Dictionary:
	return DEFINITIONS.get(quest_id, {})


static func get_npc_name(npc_id: String) -> String:
	return str(NPCS.get(npc_id, {}).get("name", npc_id.capitalize()))


static func is_active(quest_state: String) -> bool:
	return quest_state != STATE_AVAILABLE and quest_state != STATE_COMPLETED


static func is_quest_active(quest_id: String) -> bool:
	return is_active(GameState.get_quest_state(quest_id))


static func is_completed(quest_id: String) -> bool:
	return GameState.get_quest_state(quest_id) == STATE_COMPLETED


## Whether every quest this one requires has been completed, and the level it requires cleared.
static func is_unlocked(quest_id: String) -> bool:
	var quest := get_definition(quest_id)
	for required_id in quest.get("requires", []):
		if not is_completed(required_id):
			return false
	if quest.has("requires_level") and not GameState.get_completed_levels().has(int(quest["requires_level"])):
		return false
	return true


## The level transition quest that clearing this level opens, while it hasn't been completed, or "".
static func get_open_transition(level_id: int) -> String:
	for quest_id in DEFINITIONS:
		var quest: Dictionary = DEFINITIONS[quest_id]
		if quest.has("travel") and int(quest.get("requires_level", 0)) == level_id and not is_completed(quest_id) \
				and is_unlocked(quest_id):
			return quest_id
	return ""


## The hub (by level id) a conversation about this quest should end by travelling to, or 0: a level
## transition quest that is waiting to set out, talked over with its giver.
static func get_departure(quest_id: String, npc_id: String) -> int:
	var quest := get_definition(quest_id)
	if not quest.has("travel") or quest.get("giver_id", "") != npc_id:
		return 0
	var travel: Dictionary = quest["travel"]
	if GameState.get_quest_state(quest_id) != travel["requires_state"]:
		return 0
	return int(travel["hub"])


## Ids of the active character's quests in the given area that have been accepted (active or completed).
static func get_logged_quests_in_area(level_id: int) -> Array[String]:
	var quest_ids: Array[String] = []
	for quest_id in DEFINITIONS:
		if int(DEFINITIONS[quest_id]["area"]) == level_id \
				and GameState.get_quest_state(quest_id) != STATE_AVAILABLE:
			quest_ids.append(quest_id)
	return quest_ids


static func get_active_quest_count() -> int:
	var count := 0
	for quest_id in DEFINITIONS:
		if is_active(GameState.get_quest_state(quest_id)):
			count += 1
	return count


## The current stage of a quest: objectives done, status line and optional counter.
static func get_stage(quest_id: String) -> Dictionary:
	return get_definition(quest_id).get("stages", {}).get(GameState.get_quest_state(quest_id), {})


## Status line with the stage's tally, e.g. "Find wild apple trees...  (Trees picked 2/5)".
static func get_status_text(quest_id: String) -> String:
	var stage := get_stage(quest_id)
	var status: String = stage.get("status", "In progress")
	var progress := get_progress_text(quest_id)
	return status if progress.is_empty() else "%s  (%s)" % [status, progress]


## "Trees picked 2/5" while the current stage counts something, otherwise "".
static func get_progress_text(quest_id: String) -> String:
	var counter: Dictionary = get_stage(quest_id).get("counter", {})
	if counter.is_empty():
		return ""
	return "%s %d/%d" % [counter["label"], mini(GameState.get_quest_counter(quest_id), counter["count"]), counter["count"]]


## Rewards earned from completed quests, as dictionaries with name, description and quest title.
static func get_earned_rewards() -> Array[Dictionary]:
	var rewards: Array[Dictionary] = []
	for quest_id in DEFINITIONS:
		var quest: Dictionary = DEFINITIONS[quest_id]
		if quest.has("reward") and GameState.get_quest_state(quest_id) == STATE_COMPLETED:
			var reward: Dictionary = quest["reward"].duplicate()
			reward["quest_title"] = quest["title"]
			rewards.append(reward)
	return rewards


## "40 gold, 120 experience" for a quest's payout, or "" if it pays nothing.
static func get_payout_text(quest_id: String) -> String:
	var quest := get_definition(quest_id)
	var parts: Array[String] = []
	if int(quest.get("gold", 0)) > 0:
		parts.append("%d gold" % int(quest["gold"]))
	if int(quest.get("experience", 0)) > 0:
		parts.append("%d experience" % int(quest["experience"]))
	return ", ".join(parts)


# --- Conversations ---------------------------------------------------------------------------------------

## What an NPC says when the player talks to them, picked by what matters most: a quest step that happens
## by talking to them (handing something in), a quest they can offer, what they have to say about a quest
## in progress, then their last finished quest, then small talk. Returns quest_id ("" for small talk),
## pages, offer (true to end on Accept / Decline) and talk (the step to apply, or {}).
static func get_conversation(npc_id: String) -> Dictionary:
	for quest_id in DEFINITIONS:
		var talk := _get_talk_step(quest_id, npc_id)
		if not talk.is_empty():
			return {"quest_id": quest_id, "pages": talk["pages"], "offer": false, "talk": talk}
	for quest_id in DEFINITIONS:
		if _can_offer(quest_id, npc_id):
			return {"quest_id": quest_id, "pages": DEFINITIONS[quest_id]["dialogue"][STATE_AVAILABLE], "offer": true, "talk": {}}
	for quest_id in DEFINITIONS:
		var quest_state := GameState.get_quest_state(quest_id)
		if not is_active(quest_state):
			continue
		var quest: Dictionary = DEFINITIONS[quest_id]
		var lines: Array = quest.get("npc_lines", {}).get(npc_id, {}).get(quest_state, [])
		if lines.is_empty() and quest.get("giver_id", "") == npc_id:
			var dialogue: Dictionary = quest["dialogue"]
			lines = dialogue.get(quest_state, dialogue.get(STATE_ACCEPTED, []))
		if not lines.is_empty():
			return {"quest_id": quest_id, "pages": lines, "offer": false, "talk": {}}
	var finished_id := ""
	for quest_id in DEFINITIONS:
		if DEFINITIONS[quest_id].get("giver_id", "") == npc_id and is_completed(quest_id):
			finished_id = quest_id
	if not finished_id.is_empty():
		return {"quest_id": finished_id, "pages": DEFINITIONS[finished_id]["dialogue"][STATE_COMPLETED], "offer": false, "talk": {}}
	return {"quest_id": "", "pages": NPCS.get(npc_id, {}).get("idle", ["..."]), "offer": false, "talk": {}}


## Applies a talk step from get_conversation: moves the quest on and, if that completes it, pays out.
## Returns the payout line to show ("" if none).
static func apply_talk(quest_id: String, talk: Dictionary) -> String:
	if talk.is_empty() or GameState.get_quest_state(quest_id) != talk["requires_state"]:
		return ""
	if not GameState.set_quest_state(quest_id, talk["sets_state"]):
		push_error("Could not save progress for quest '%s'." % quest_id)
		return ""
	if talk["sets_state"] == STATE_COMPLETED:
		return _pay_out(quest_id)
	return ""


static func accept(quest_id: String) -> bool:
	if GameState.get_quest_state(quest_id) != STATE_AVAILABLE:
		return false
	if not GameState.set_quest_state(quest_id, STATE_ACCEPTED):
		push_error("Could not save acceptance of quest '%s'." % quest_id)
		return false
	return true


## Which quest marker an NPC should show: gold "?" if talking to them moves a quest on, gold "!" if they
## have a quest to offer, grey "?" while one of their quests is under way.
static func get_marker_mode(npc_id: String) -> QuestMarker.Mode:
	for quest_id in DEFINITIONS:
		if not _get_talk_step(quest_id, npc_id).is_empty():
			return QuestMarker.Mode.TURN_IN
	for quest_id in DEFINITIONS:
		if _can_offer(quest_id, npc_id):
			return QuestMarker.Mode.AVAILABLE
	for quest_id in DEFINITIONS:
		if DEFINITIONS[quest_id].get("giver_id", "") == npc_id and is_quest_active(quest_id):
			return QuestMarker.Mode.IN_PROGRESS
	return QuestMarker.Mode.HIDDEN


static func _get_talk_step(quest_id: String, npc_id: String) -> Dictionary:
	var quest_state := GameState.get_quest_state(quest_id)
	if not is_active(quest_state):
		return {}
	for talk in DEFINITIONS[quest_id].get("talks", []):
		if talk["npc"] == npc_id and talk["requires_state"] == quest_state:
			return talk
	return {}


static func _can_offer(quest_id: String, npc_id: String) -> bool:
	return DEFINITIONS[quest_id].get("giver_id", "") == npc_id \
			and GameState.get_quest_state(quest_id) == STATE_AVAILABLE and is_unlocked(quest_id)


static func _pay_out(quest_id: String) -> String:
	var quest := get_definition(quest_id)
	var gold := int(quest.get("gold", 0))
	var experience := int(quest.get("experience", 0))
	if gold > 0:
		GameState.add_gold(gold)
	if experience > 0 and not GameState.add_experience(experience):
		push_error("Could not award %d XP for quest '%s'." % [experience, quest_id])
	var payout := get_payout_text(quest_id)
	return "" if payout.is_empty() else "Quest complete! Reward: %s." % payout


# --- World events ----------------------------------------------------------------------------------------

## Something happened in the world: a monster slain ("kill", "wolf"), an object used ("collect", "apple",
## "forest_apple_3"), a place found ("find" / "enter"), someone saved ("rescue"), a hub reached ("arrive",
## "hub_2"). Advances every active
## quest waiting on it; collectables count once per object_id, and an event that finishes a quest pays it
## out. Returns one {quest_id, text} per quest that moved, where text is the new tally, status line or payout.
static func record_event(event_type: String, target: String, object_id := "") -> Array[Dictionary]:
	var updates: Array[Dictionary] = []
	for quest_id in DEFINITIONS:
		var event := _get_waiting_event(quest_id, event_type, target, object_id)
		if event.is_empty():
			continue
		if not object_id.is_empty() and not GameState.set_quest_counter("%s/%s" % [quest_id, object_id], 1):
			continue
		var count := GameState.get_quest_counter(quest_id) + 1
		var needed := int(event.get("count", 1))
		if needed > 1 and not GameState.set_quest_counter(quest_id, count):
			continue
		if count >= needed:
			if not GameState.set_quest_state(quest_id, event["sets_state"]):
				push_error("Could not save progress for quest '%s'." % quest_id)
				continue
			var text: String = get_stage(quest_id).get("status", "")
			if event["sets_state"] == STATE_COMPLETED:
				var payout := _pay_out(quest_id)
				text = text if payout.is_empty() else payout
			updates.append({"quest_id": quest_id, "text": text, "advanced": true})
		else:
			updates.append({"quest_id": quest_id, "text": "%s %d/%d" % [get_stage(quest_id)["counter"]["label"], count, needed], "advanced": false})
	return updates


## Whether some active quest is waiting on this event (and, for collectables, this particular object).
static func is_event_wanted(event_type: String, target: String, object_id := "") -> bool:
	for quest_id in DEFINITIONS:
		if not _get_waiting_event(quest_id, event_type, target, object_id).is_empty():
			return true
	return false


## Whether the quest that uses this object (any stage) has already used it, e.g. a tree already picked.
static func is_object_used(quest_id: String, object_id: String) -> bool:
	return GameState.get_quest_counter("%s/%s" % [quest_id, object_id]) > 0


static func _get_waiting_event(quest_id: String, event_type: String, target: String, object_id: String) -> Dictionary:
	var quest_state := GameState.get_quest_state(quest_id)
	if not is_active(quest_state):
		return {}
	for event in DEFINITIONS[quest_id].get("events", []):
		if event["type"] == event_type and event["target"] == target and event["requires_state"] == quest_state:
			if not object_id.is_empty() and is_object_used(quest_id, object_id):
				return {}
			return event
	return {}


# --- Boss chest quest items ------------------------------------------------------------------------------

## The quest items a boss chest should contain for the active character's current quest stages.
static func create_chest_quest_items() -> Array[ItemData]:
	var items: Array[ItemData] = []
	for quest_id in DEFINITIONS:
		var quest: Dictionary = DEFINITIONS[quest_id]
		if not quest.has("quest_item"):
			continue
		var quest_item: Dictionary = quest["quest_item"]
		if GameState.get_quest_state(quest_id) != quest_item["requires_state"]:
			continue
		var item := ItemData.new()
		item.display_name = quest_item["name"]
		item.equipment_slot = "Quest Item"
		item.icon_color = Color(quest_item["color"])
		item.price = 0
		item.quest_id = quest_id
		items.append(item)
	return items


## Called when a quest item is looted; advances its quest. Returns the new status line ("" if nothing changed).
static func loot_quest_item(quest_id: String) -> String:
	var quest := get_definition(quest_id)
	if quest.is_empty() or not quest.has("quest_item"):
		return ""
	var quest_item: Dictionary = quest["quest_item"]
	if GameState.get_quest_state(quest_id) != quest_item["requires_state"]:
		return ""
	if not GameState.set_quest_state(quest_id, quest_item["sets_state"]):
		push_error("Could not save progress for quest '%s'." % quest_id)
		return ""
	return quest["stages"][quest_item["sets_state"]]["status"]
