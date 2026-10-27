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
		if quest.has("travel") and int(quest.get("requires_level", 0)) == level_id and not is_completed(quest_id):
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
