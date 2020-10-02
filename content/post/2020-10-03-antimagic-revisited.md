---
title: Antimagic and Force Cubes
subtitle: A lesson from weakly typed magic items
date: 2020-10-01
tags: ["dnd"]
categories: ["roleplaying"]
---

In 2018, I introduced the explosive [Cube of Force](https://roll20.net/compendium/dnd5e/Cube%20of%20Force) into our home campaign. If you are considering it, here are some outcomes after of our hour long cannoicalisation meeting that followed, subsequent nerfs, and later rethinkings that followed after more careful source consultations.

<!--more-->

## Word of wording
Spell combinations are an inherently powerful thing in D&D, and so any spells that "cancels out magic" - potentially interacting with [Dispel Magic](https://5thsrd.org/spellcasting/spells/dispel_magic/) - must be carefully worded, and the team does try their best. But despite their best efforts, ambiguously worded spell effects frequently end up at [JeremyECrawford](https://twitter.com/JeremyECrawford)'s table:

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Have a D&amp;D rules question? There&#39;s a good chance I&#39;ve answered it!<br><br>1. Search the Sage Advice Compendium: <a href="https://t.co/nlIvbEC7D7">https://t.co/nlIvbEC7D7</a>.<br>2. Search Twitter, typing my handle (<a href="https://twitter.com/JeremyECrawford?ref_src=twsrc%5Etfw">@JeremyECrawford</a>) and a relevant term, like &quot;Twinned Spell.&quot;<br>3. Search <a href="https://t.co/5oYKuatgLB">https://t.co/5oYKuatgLB</a>. <a href="https://twitter.com/hashtag/DnD?src=hash&amp;ref_src=twsrc%5Etfw">#DnD</a> <a href="https://t.co/JXtO9catjP">pic.twitter.com/JXtO9catjP</a></p>&mdash; Jeremy Crawford (@JeremyECrawford) <a href="https://twitter.com/JeremyECrawford/status/931742038474727424?ref_src=twsrc%5Etfw">November 18, 2017</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

<!--shortcode fails on my hugo install..< tweet 931742038474727424 >-->

the referenced [Sage Advice Compendium](https://dnd.wizards.com/articles/sage-advice/sage-advice-compendium) is large and has many erratas for published books.

## ForceCarge
Let's look at [ForceCage](https://roll20.net/compendium/dnd5e/Forcecage) (or `FC` for short) first; a `7th level` effective mechanism to trap players inside, that also comes with a lot of words about __how__ spells can interact with it.

> `FC`; "creating a solid barrier that prevents any matter from passing through it and blocking any Spells cast into or out of the area".

This wording only mentions the casting; i.e. the [line from the caster to the point of origin](https://www.dndbeyond.com/sources/basic-rules/spellcasting#Targets). It's possible to start a concentration spell, then wrap a cage around it, causing trapped players to take concentration damage __every round__ without proper recourse.

It can be pretty deadly when used in combination with spells like [Hunger of Hadar](https://www.dnd-spells.com/spell/hunger-of-hadar) (10 rounds), [Cloudkill](https://roll20.net/compendium/dnd5e/Cloudkill) (100 rounds), or [higher level clouds if available](https://5thsrd.org/spellcasting/spells/incendiary_cloud/), and you cannot even dispel it.

![hadar](/imgs/antimagic/hadar.jpg)

Scary prospect though it may be, its downfall is its size, and possibility to wrangle yourself out of it with; `[Plane Shift](https://roll20.net/compendium/dnd5e/Plane%20Shift#content) / [Teleport](https://roll20.net/compendium/dnd5e/Teleport#content) / [Misty Step](https://roll20.net/compendium/dnd5e/Misty%20Step#content) / [Dimension Door](https://roll20.net/compendium/dnd5e/Dimension%20Door#content) on a successful charisma check. All it takes is for one player to get outside and break the mage's concentration.

Still it highlights a difference with other "antimagic" in spells. The "effect" of the spell leeches through the barrier of the cage, which is perhaps somewhat confusing  if you treat "matter" as atoms. But quantum mechanics and magic is a bit of a strange thing to try to join. Magic in D&D is more like a `Strong Force` called the [Weave](https://forgottenrealms.fandom.com/wiki/Weave) in Forgotten Realms.

## Antimagic Field
An `8th level` sphere of [`Antimagic Field`](https://roll20.net/compendium/dnd5e/Antimagic%20Field) (or `AMF` for short), is a sphere that disallows spells cast in/out __as well as__ effects leeching through! The reason for the great increase in cancellation power is justified by its higher level, careful wording of magic, and the lack of entrapment (it does not prevent people leaving like `FC`).

> `AMF`: Any active spell or other magical Effect on a creature or an object in the Sphere is suppressed while the creature or object is in it.

Cast a fireball on the outside of a `ForceCage`, and the AOE will damage the people inside. Not so with `AMF`.


People __can try__ to throw a [Delayed Blast Fireball](https://roll20.net/compendium/dnd5e/Delayed%20Blast%20Fireball) inside an area, and put an `Antimagic Field` around the area to limit mages inside, while powering up the fireball from the outside (`DBF` powers up with time and concentration). This, I feel, really gets to the heart of the word __"suppressed"__; is the bead still there? Will it keep working after the `AMF` disappears? Has it powered up in the mean time? Has the duration elapsed?

This is a bit contentious already, and we've not even gotten to the true difficult ones like:

- class abilities like paladin's smite, monk's ki points, druid shapeshifting
- monster abilities like dragon's breath, beholder rays
- summoned creatures
- magical items vs. magical artifacts (even though magic items are referenced)

To answer these, we need to go to the source.

## What is a magical effect?
The best dismabiguation here come from the really insteresting [interview with Crawford from 2017](https://dnd.wizards.com/articles/features/tad-williams-storytelling) about antimagic and what they mean by `suppressing` magic.

The short answer is that spells are **not dispelled**, and the **duration of spells keeps ticking**, but that's not really getting to the meat of it.

He describes magic in the D&D world as always existing in the background as a loose weave. And magical effects is this fabric formed into a particular shape; __background magic woven into an effect - using a formula__. "AMF introduces a \[temporary\] bug in this formula." Whereas `Dispel Magic` disperses that woven magic from a spell into background magic.

Because the world is inherently magical - and creatures like dragons and beholders would not make sense without it - `AMF` cannot possibly cancel this type of magic (as this would undo the very nature of the multiverse). Similarly, it could not cancel non-magical effects that were created through the means of past magic. Still:

> `AMF`: "You will not see any effects of magic while inside this field. The area is divorced from the magical energy that suffuses the multiverse".

So we still need to distinguish those types of magic from the others. This is where we consult the __heuristic__ test from the [Sage Advice Compendium](https://media.wizards.com/2020/dnd/downloads/SA-Compendium.pdf) inlined below:

### Test for magical effects
Answer `YES` to any of these to be classified as magical (and thus have `AMF` suppress its effect):

- Is it a **magic item**?
- Is it a **spell**?
- Is it a **spell attack**?
- Is it creating the **effects of a spell mentioned in its description**?
- Is it **fueled by spell slots**
- Does the words `magic` or `magical` **appear in its effect description**?

### Examples
While this seems like a well-thought-out heuristic, the results they mention are interesting:

- Conjured creatures with concentration are magical
- Summoned creatures with instant cast duration are **NOT** magical

Because the summoning has already taken place in the latter case.

The corollary is that:

- Conjured creatures (concentration-based) disappear
- Conjured creatures reappear when the field disappear (unless concentration was lost)
- Summoned creatures that are instantaneous summons stay and can traverse the field (it's not persisting because of a spell anymore)
- [You still have to make concentration checks when hit](https://rpg.stackexchange.com/questions/93550/is-a-concentration-spell-suppressed-when-the-caster-is-in-antimagic-field)

Additionally, the following phenomenons (that at some point required magic to bring into existence) are __not considered magical__:

- Fire created by `Prestidigitation` (if it has a reason to keep burning)
- A `Dragon` and its breath weapon
- A `Beholder` and its `Antimagic Cone` (though it functions like `AMF`)

![beholder ray](/imgs/antimagic/beholder_ray.jpg)

### Artifacts
Finally, `Artifacts` - or magic items either unavailable to mortals, or long forgotten - are also unaffected by `AMF` by a special flavour text (to,  presumably, prevent you from destroying them):

> `AMF`: Spells and other magical Effects, **except those created by an artifact or a deity**, are suppressed in the Sphere and can't protrude into it.

Thus, they probably have their full abilities unmodified completely - even if it can cast spells, like `Blackrazor`'s `Haste` ability. The magic of deities can not be modified by mortals.

### Interpretting the rest
Spellcasters with an active `Find Familiar` leave a bunch of open ended questions on how you can interact with them, even though the familiar clearly lingers. [Telepathy is magical](https://rpg.stackexchange.com/questions/133610/which-features-of-a-wizards-familiar-if-any-are-considered-magical), and if telepathy is magical, then so is sharing of senses between a familiar (at least that is my interpretation).

Otherwise; a `warlock`'s `Pact Magic` is magical, as are `Eldritch Invocations`, blade pactweapons, and `Mystic Arcanum`.

A `sorcerer` can't use sorcery points, as they "create \[..\] magical effects", nor the clearly magical; `Metamagic`.

The `PHB` mentions that the `monk`'s `ki` energy draws on magical energy, but this is only meant to mean "background magic in the multiverse" `Crawford` says, and goes on to say:

> "we only consider individual monk ability to be magical if we've put the word magic/magical/magically in that particular monk ability

A quick [search through reference text](http://dnd5e.wikidot.com/monk) seem to only mention:

- KI-Empowered strikes
- Fey Step
- Blessing of the Raven Queen
- Casting spells via `Way of the Four Elements`

so Flurry/Patient Defense or even [Stunning Strike is not magical](https://rpg.stackexchange.com/questions/76005/does-ki-count-as-magic-for-the-purpose-of-an-antimagic-field-or-is-it-only-fluf).

The `paladin` only has a few similar references:

- Channel Divinity is magical
- Sacred Weapon is magical (weapon no longer get the +1 if it got it)
- Divine Health is magical (no longer immune to disease)
- Divine Smite is not magical - but you can't use it to expend spell slots!

The `druid`'s wild shape is magical and would temporarily drop within an `AMF`.

The `ranger` is more straightforward. Only spells matter, and while `Hunter's Mark` will linger, it does so under concentration, and is suppressed by an `AMF` if you/they touch it.

## Delayed Blast Fireball
This brings us to the curious case of [Delayed Blast Fireball](https://roll20.net/compendium/dnd5e/Delayed%20Blast%20Fireball).

Originally, I thought that the bead, while suppressed, would not increase in damage for the time inside the field because of the nature of the required concentration. [This is contentious](https://rpg.stackexchange.com/questions/136280/what-happens-if-a-delayed-blast-fireball-detonates-inside-an-antimagic-field#:~:text=A%20Delayed%20Fireball%20in%20an%20Antimagic%20Field%20wouldn't%20detonate&text=While%20an%20effect%20is%20suppressed,is%20suppressed%2C%20meaning%20nothing%20happens.), and even [Crawford's wording](https://www.sageadvice.eu/2015/12/09/delayed-blast-fireball-inside-an-antimagic-field/) implies wiggle room.

It's clear that the duration should tick from what `Crawford` says in the interview, but the nature of concentration here is unclear. Does it imply that the caster is the one imbuing the bead with the extra power each round (in which case you wouldn't be able to channel energy to it those rounds)? Or is it simply for remote controlling the detonation?

> `DBF`: When the spell ends, either because your concentration is broken or because you decide to end it, the bead blossoms with a low roar into an explosion of flame that spreads around corners.

Your concentration is not broken inside `AMF` (unless you fail a check), and there's nothing explicit indicating channelling. So let's __for the sake of argument__ assume that it's __only for remote controlling__ the detonation.

Now:

- [Fireball](https://roll20.net/compendium/dnd5e/Fireball#content) at `7th level` would deal `8d6+4d6` damage
- [DBF](https://www.dndbeyond.com/spells/delayed-blast-fireball) at `7th level` would deal `12d6` damage

So while the intial damage is equal, the higher level nature of `DBF` confers an extra passive bonus (as it should) of an extra `1d6` damage the bead can gain every round. This is a reasonable power justificaton for the bead being able to power up on its own.

It really comes down to the nature of the bead. Either it:

- extracts its magic from the _background magic_ around it
- uses some type of _magical_ reactor inside of it that slowly needs to power up

Either _should_ be impossible inside an `AMF`, **unless**; it is possible to have a _D&D natural_, power-increasing bead that can power up without magical effects.

I'm going to stop here for `DBF`. It's clear you can make the argument for either side (it gaining power / it not gaining power), but for consistency with _concentration_, I would rule the latter.


## Counterspell
A side-note, you cannot use `Dispel` on an `AMF`, but you can [`Counterspell`](https://www.dndbeyond.com/spells/counterspell) the casting of it.

![counterspell](/imgs/antimagic/counterspell.png)

A side-note, `Counterspell` cannot target `Wildshape` from a `druid` (as it's not a spell), it is a magical effect, that is surpressed by `AMF`

## ForceCage vs. AntiMagic Field
To illustrate even more, with the two cancellation texts interacting; `ForceCage` does not prevent magic being cast inside as long as the point of origin does not cross the boundary; so __you can cast `AMF` inside of a `ForceCage`__.

There is a [relevant Order of the Stick comic](https://www.giantitp.com/comics/oots0627.html) here.

The result being a `AMF` 10ft sphere sphere partially protruding a 10x10ft rectangle, allowing for some funny geometrical problems - if you are inclined to do some on-the-fly trig.

> AMF: If the Sphere overlaps an area of magic, the part of the area that is covered by the Sphere is suppressed.

Note that there's no __dynamic movement__ or __dynamic extensions__ for spell effects (movement typically happen as a discrete point at the start of a casters turn); `AMF` would leave the `ForceCage` active, just partially disabled where the the caster's sphere is covering it.

## Antimagic Field Concentration
`Crawford` notes that `AMF` is itentionally concentration spell, moves with you, to give the players a chance to take out the mage. In conclusion; __don't put it on an item__.

Funny you should mention that...

## Cube of Force
A cube with 36 fast-recharging charges, and special effects for each face.

> You can use an action to press one of the cube's faces. Each face has a different Effect. A barrier of Invisible force springs into existence, forming a cube 15 feet on a side. The barrier is centered on you, moves with you, and lasts for 1 minute, until you use an action to press the cube's sixth face, or the cube runs out of Charges.

> You can change the barrier's Effect by pressing a different face of the cube and expending the requisite number of Charges, resetting the Duration. If your Movement causes the barrier to come into contact with a solid object that can't pass through the cube, you can't move any closer to that object as long as the barrier remains.

![cube of force](/imgs/antimagic/cubeofforce.jpg)

### Face Effect:
- **1** Gases, wind, and fog can't pass through the barrier.
- **2** Nonliving matter can't pass through the barrier. Walls, floors, and ceilings can pass through at your discretion.
- **3** Living matter can't pass through the barrier. (`FC` ?)
- **4** Spell Effects can't pass through the barrier. (`AMF`)
- **5** Nothing can pass through the barrier. Walls, floors, and ceilings can pass through at your discretion. (`AMF` + `FC` ?)
- **6** The barrier deactivates.

There's also a number of charges on it, each face uses a particular amount of charges and certain spells hitting the barrier drains an amount of charges, but it's not that important.

But this is a lot more loosely worded, leaves a lot of room for interpretation, and [any questions about this item to @JeremyECrawford results in no real answers](https://twitter.com/search?q=JeremyECrawford%20%22cube%20of%20force%22) - almost like they want to pretend the item does not exist.

### Questions
TODO: tune - double check with Globe questions
#### 1. Does gas include air?
Who knows. It doesn't matter that much other than if they spend more than an hour inside of the bubble, in which case the use of oxygen and adding of carbon dioxide can make them a little light headed, but no more than spending an hour in a cramped meeting room

#### 2. Non-living matter?
So no walls, floors and ceilings, according to the flavourtext. You are effectively walking around with like an ~~inflatable ball~~ cube around you, being pushed by your surroundings. If you can't extend the ball fully, the activation probably has no effect? You need free space to cast it?

#### 3. Living matter?
This sounds like `ForceCage`, but without the cage. Just for protecting yourself. People can still `Cloudkill` you. In D&D `{living matter} union {non-living matter}` does _not_ equal `the multiverse`. There is still magical effects.

#### 4. Spell effects passing through?
This is more ambiguous than `AMF`. The wording of `passing through` is strange, particularly since D&D doesn't have a concept of spells effects moving (dynamic movement) so any spell effects covered by this barrier ought to be supressed exactly like `AMF` though it does not specify the comparison.

Maybe this implies it only targets spells, and not magical effects?

We almost certainly block spells being cast through, but it does not even specify this. Can we just cast `Fireball` inside from the outside? The point of origin stays inside..

#### 5. Nothing?
All matter, light, magical effects, spell effects, other forces. Welcome to your blindness/deafness cage. Vantablack inside, vantablack outside.

### Conclusion
After an hour of discussing this in person in 2018, we [initially came up with a vague plan](https://paper.dropbox.com/doc/CUBE-OF-FORCE-ijFUPdkLPXwXuux3hEkVe), but this was later nerfed, and discarded. It was not good enough.

The crux of the matter is that this item is too ambiguous, the wording does not match anything else in the normally pretty consistent spell list.

__If you want this type of Legendary item__; i recommend you homebrew something smarter. Here's my homebrew proposal:

![globe of invulnerability](/imgs/antimagic/globe_invuln.jpg)

#### Sphere of Umberlee
You can cast the following spells once per day (but one at a time only) from the following list of spells. The sphere will maintain concentration until made to drop it via a command word.

- [Globe of Invulnerability](https://5thsrd.org/spellcasting/spells/globe_of_invulnerability/)
- [Resilient Sphere](https://5thsrd.org/spellcasting/spells/resilient_sphere/) (on self only)
- [Hallow](https://5thsrd.org/spellcasting/spells/hallow/)
- [Blade Barrier](https://5thsrd.org/spellcasting/spells/blade_barrier/)

Different, but largely protective spells, with well-defined uses, and sufficiently different that they are all worth using.

This is still a `legendary` type of item, it's just not so gamebreaking that it would put near unlimited `AMF` on an item.

This homebrew item is named after a character in my game; a tempest cleric of `Umberlee` who was wielding `Wave` (previously containing the `Cube of Force`).
