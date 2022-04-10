---
title: "Baldur's Gate: Multinomial Edition"
subtitle: Auto-rolling and getting nerd sniped before venturing forth
date: 2022-04-01
tags: []
categories: ["gaming"]
---

In a ~~brief~~ bout of escapism from the world and responsibilities, I booted up [Baldur's Gate 2](https://store.steampowered.com/app/257350/Baldurs_Gate_II_Enhanced_Edition/) with my brother. It's an amazing game, once you have figured out how to **[roll](https://old.reddit.com/r/baldursgate/search?q=roll&restrict_sr=on)** your character.

For today's installment; rather than telling you about the game, let's talk about the **maths** behind rolling a `2e` character for `BG2`, and then running simulations with weird `X`-based linux tools.

TODO: gif of roll clicking...
TODO: maybe just a reroll button that links to the article?

<!--more-->
<script src="https://cdn.plot.ly/plotly-2.9.0.min.js"></script>

## Rolling a character

Basics; D&D (2e) has:

- `6` ability scores
- each ability == sum of rolling `3d6`

This **should** give you a character with an expected "10.5" points per ability (or a sum of `63` in total), and the process looks like this:

TODO: gif of boring rolling

It's a pretty dumb design idea to port the rolling mechanics from `d&d` into the game. In a normal campaign you'd get one chance rolling, but here, there's no downside to keeping going, encouraging excessive time investment (the irony in writing this blog post is not lost on me). They should have just gone for something like [5e point buy](https://chicken-dinner.com/5e/5e-point-buy.html).

Still, **suppose** you want to **automate rolling** (or want to think about combinatorics, multinomials, and weird `X` tools), then you can use this post. You can also figure out **how long it will take** you to receive your _"good roll"_.

> HINT: ..it's less time than it took to write this blogpost.

## Disclaimer

Using the script used herein to achieve higher rolls than you have patience for, is on some level; **cheating**. That said; no-one cares, and it's a fairly pointless effort:

- this is an [old](https://en.wikipedia.org/wiki/Baldur%27s_Gate_II:_Shadows_of_Amn) single player game, and you can reduce the difficulty
- having [dump stats](https://tvtropes.org/pmwiki/pmwiki.php/Main/DumpStat) is not heavily penalized in the game
- early items nullify effects of common dump stats ([19 STR girdle](https://baldursgate.fandom.com/wiki/Girdle_of_Hill_Giant_Strength) or [18 CHA ring](https://baldursgate.fandom.com/wiki/Ring_of_Human_Influence))
- you can get [max stats in 20 minutes](https://www.youtube.com/watch?v=5dDmh98lmkA) with by abusing inventory [underflow](https://baldursgate.fandom.com/wiki/Exploits#Potion_Swap_Glitch)
- some [NPCS](https://baldursgate.fandom.com/wiki/Edwin_Odesseiron) come with [gear](https://baldursgate.fandom.com/wiki/Edwin%27s_Amulet) that blows __marginally better stats__ out of the water

So assuming you have a reason to be here despite this; let's dive in to some maths.

## Multinomials and probabilities

> How likely are you to get a 90/95/100?

Rolling a 6 sided dice 18 times follows a degenerate case of the [multinomial distribution](https://en.wikipedia.org/wiki/Multinomial_distribution) where all events are equally likely, and each sampling follows the same distribution. We are going to follow the multinomial expansion at [mathworld/Dice](https://mathworld.wolfram.com/Dice.html) for `s=6` and `n=18` and find $P(x, 18, 6)$ which we will denote as $P(X = x)$:

$$P(X = x) = \frac{1}{6^{18}} \sum_{k=0}^{\lfloor(x-18)/6\rfloor} (-1)^k \binom{18}{k} \binom{x-6k-1}{17}$$
$$ = \sum_{k=0}^{k_{max}} (-1)^k \frac{18}{k!(18-k)!} \frac{(x-6k-1)!}{(x-6k-18)!}$$

where $k_{max} = \lfloor(x-18)/6\rfloor$. If we were to expand this expression, the variability of $k_{max}$ would yield 15 different sum expressions - and the ones we care about would all have 10+ expressions. So rather than trying to reduce this to a polynomial expression over $p$, we will [paste values into wolfram alpha](https://www.wolframalpha.com/input?i2d=true&i=+Divide%5B1%2CPower%5B6%2C18%5D%5DSum%5BPower%5B%5C%2840%29-1%5C%2841%29%2Ck%5D+*binomial%5C%2840%2918%5C%2844%29+k%5C%2841%29*binomial%5C%2840%2991-6k-1%5C%2844%29+17%5C%2841%29%2C%7Bk%2C0%2Cfloor%5C%2840%29Divide%5B%5C%2840%2991-18%5C%2841%29%2C6%5D%5C%2841%29%7D%5D) and tabulate for $[18, \ldots, 108]$.

You can `view-source` or see the <a href="#appendix">appendix</a> for the numbers, but we can more easily graph the distribution:

<div id="probhist" style="width:600px;height:450px;"></div>

<script>

// keys [18, 108]
var ALL_X = [...Array(109).keys()].slice(18);

// probabilities for p=18 up to p=108 (sums to 0.9999999999999999 \o/)
var MAIN_PROBS = [1/101559956668416, 1/5642219814912, 19/11284439629824, 95/8463329722368, 665/11284439629824, 1463/5642219814912, 33643/33853318889472, 9605/2821109907456, 119833/11284439629824, 1552015/50779978334208, 308465/3761479876608, 97223/470184984576, 2782169/5642219814912, 1051229/940369969152, 4550747/1880739938304, 786505/156728328192, 37624655/3761479876608, 36131483/1880739938304, 1206294965/33853318889472, 20045551/313456656384, 139474379/1253826625536, 1059736685/5642219814912, 128825225/417942208512, 17143871/34828517376, 8640663457/11284439629824, 728073331/626913312768, 2155134523/1253826625536, 3942228889/1586874322944, 4949217565/1410554953728, 3417441745/705277476864, 27703245169/4231664861184, 3052981465/352638738432, 126513483013/11284439629824, 240741263447/16926659444736, 199524184055/11284439629824, 60788736553/2821109907456, 2615090074301/101559956668416, 56759069113/1880739938304, 130521904423/3761479876608, 110438453753/2821109907456, 163027882055/3761479876608, 88576807769/1880739938304, 566880747559/11284439629824, 24732579319/470184984576, 101698030955/1880739938304, 461867856157/8463329722368, 101698030955/1880739938304, 24732579319/470184984576, 566880747559/11284439629824, 88576807769/1880739938304, 163027882055/3761479876608, 110438453753/2821109907456, 130521904423/3761479876608, 56759069113/1880739938304, 2615090074301/101559956668416, 60788736553/2821109907456, 199524184055/11284439629824, 240741263447/16926659444736, 126513483013/11284439629824, 3052981465/352638738432, 27703245169/4231664861184, 3417441745/705277476864, 4949217565/1410554953728, 3942228889/1586874322944, 2155134523/1253826625536, 728073331/626913312768, 8640663457/11284439629824, 17143871/34828517376, 128825225/417942208512, 1059736685/5642219814912, 139474379/1253826625536, 20045551/313456656384, 1206294965/33853318889472, 36131483/1880739938304, 37624655/3761479876608, 786505/156728328192, 4550747/1880739938304, 1051229/940369969152, 2782169/5642219814912, 97223/470184984576, 308465/3761479876608, 1552015/50779978334208, 119833/11284439629824, 9605/2821109907456, 33643/33853318889472, 1463/5642219814912, 665/11284439629824, 95/8463329722368, 19/11284439629824, 1/5642219814912, 1/101559956668416];

var MAIN_LEGEND = MAIN_PROBS.map(x => "expected once in " + Intl.NumberFormat().format(Math.floor(1/x)) + " rolls")

var trace = {
  x: ALL_X,
  y: MAIN_PROBS,
  name: 'probability',
  text: MAIN_LEGEND,
  opacity: 0.8,
  type: "scatter",
};


var data = [trace];
var layout = {
  title: "Distribution for the sum of 18d6 dice rolls",
  xaxis: {title: "Roll"},
  yaxis: {title: "Probability"},
};
Plotly.newPlot(document.getElementById('probhist'), data, layout);

// extra: precise expectation and variance
var expectation_orig = MAIN_PROBS.map((x,i) => (i+18)*x).reduce((acc, e) => acc+e, 0);
var variance_orig = MAIN_PROBS.map((x,i) => Math.pow(i+18 - expectation_orig, 2)*x).reduce((acc, e) => acc+e, 0);
console.log("Precise Expectation and variance for 18d6", expectation_orig, variance_orig);
</script>

and with the precise distribution we can also calculation expectation and variance:

- $E(X) = 63$
- $Var(X) = 52.5 \thickapprox 7.24^2$

This is how things **should** look on paper. From the chart you can extract:

- `108` would be a once in `101 trillion` ($6^{18}$) event
- `107` would be a once in `5 trillion` event (`6^18/18`)
- `106` would be a once in `600 billion` event (5s in two places, or 4 in one place)
- `105` would be a once in `90 billion` event (3x5s, or 1x4 and 1x5, or 1x3)
- `104` would be a once in `16 billion` event (4x5s, 2x5s and 1x4, 2x4s, 1x5 and 1x3, 1x2)
- `103` would be a once in `4 billion` event (...)
- `102` would be a once in `1 billion` event
- `101` would be a once in `290 million` event
- `100` would be a once in `94 million` event
- `99` would be a once in `32 million` event
- $\ldots$
- `95` would be a once in `900k` event (first number with prob < 1 in a million)

**But is this really right for BG?** A [lot](https://old.reddit.com/r/baldursgate/comments/svnyy5/this_is_why_i_let_my_gf_roll_my_stats_lol/hxhde5k/) of [people](https://old.reddit.com/r/baldursgate/comments/tak2m7/say_hello_to_my_archer_roll/) have [all](https://old.reddit.com/r/baldursgate/comments/rjnw22/less_than_a_minute_of_rolling_this_is_my_alltime/) rolled nineties in just a few hundred rolls, and many even getting [100](https://old.reddit.com/r/baldursgate/comments/phr68a/my_new_highest_roll_10049_elf_mclovin_fightermage/) or [more](https://old.reddit.com/r/baldursgate/comments/sq54wo/how_high_can_you_roll/)..was that extreme luck, or are higher numbers more likely than what this distribution says?

Well, let's start with the obvious:

> **The distribution is [censored](https://en.wikipedia.org/wiki/Censoring_(statistics)). We don't see the rolls below $75$.**

<div id="probhist2" style="width:600px;height:450px;"></div>

<script>
var trace = {
  x: ALL_X,
  y: MAIN_PROBS,
  name: 'probability',
  text: MAIN_LEGEND,
  opacity: 0.8,
  type: "scatter",
};

var data = [trace];
var layout = {
  annotations: [
   {
     y: 1/70,
     x: 75,
     xref: 'x',
     yref: 'y',
     text: 'cutoff',
     showarrow: true,
     arrowhead: 7,
     arrowcolor: "blue",
     ax: 0,
     ay: -40
   },
  ],
  xaxis: {title: "Roll"},
  yaxis: {title: "Probability"},
};
Plotly.newPlot(document.getElementById('probhist2'), data, layout);
</script>

What's **left of this cutoff** actually accounts for `94%` of the distribution. **If** the game **did not do this**, you'd be as likely getting `36` as a `90`. We are effectively throwing away "19 bad rolls" on every roll.

> `AD&D 2e` had its [own ways to tilt the distribution](https://advanced-dungeons-dragons-2nd-edition.fandom.com/wiki/Rolling_Ability_Scores) in a way that resulted in more powerful characters.

How such a truncation or censoring is performed is at the mercy of the BG engine. We will [rectify](https://en.wikipedia.org/wiki/Rectified_Gaussian_distribution) the distribution by **scaling up** a truncated version of our distribution, and show that this is correct later.

<div id="probhist3" style="width:600px;height:450px;"></div>

<script>
var prob_over_74 = window.MAIN_PROBS.slice(75-18).reduce((acc, e) => acc + e, 0);
window.SCALED_PROBS = window.MAIN_PROBS.slice(75-18).map(x => x / prob_over_74); // scale up by whats left

var scaled_legend = window.SCALED_PROBS.map(x => "expected once in " + Intl.NumberFormat().format(Math.floor(1/x)) + " rolls");

//console.log("probability of rolling gte 75", prob_over_74);
//console.log(window.SCALED_PROBS.reduce((acc, e) => acc + e, 0)); // 1!
// TODO: show zeroes on left side to seed idea of truncation better?
var trace = {
  x: window.ALL_X.slice(75-18),
  y: window.SCALED_PROBS,
  name: 'probability',
  text: scaled_legend,
  opacity: 0.8,
  type: "scatter",
};

var data = [trace];
var layout = {
  title: "Scaled Distribution",
  xaxis: {title: "Roll"},
  yaxis: {title: "Probability"},
};
Plotly.newPlot(document.getElementById('probhist3'), data, layout);

// extra: precise expectation and variance
var expectation_trunc = SCALED_PROBS.map((x,i) => (i+75)*x).reduce((acc, e) => acc+e, 0);
var variance_trunc = SCALED_PROBS.map((x,i) => Math.pow(i+75 - expectation_trunc, 2)*x).reduce((acc, e) => acc+e, 0);
console.log("Precise Truncated Expectation and variance for 18d6", expectation_trunc, variance_trunc);

</script>

Here we have divided by the sum of the probabilities of the right hand side of the graph $P(X \ge 75)$ to get the new probability sum to `1`.

Using this scaled data, we can get precise, truncated distribution parameters:

- $E(X_T) = 77.525$
- $Var(X_T) = 2.61^2$

This _censored multinomial distribution_ is actually very close for **most** cases, and we will **demonstrate** this.

But first, we are going to need to press the `reroll` button a lot...

## Automating Rolling

The simulation script / hacks we made is [found here](https://github.com/Thhethssmuz/bg2ee-stat-roll).

### Tools

We are playing on **Linux** with `X` and some obscure associated tooling:

- `scrot` - X screenshot utility
- `xdotool` - X CLI automation tool
- `xwininfo` - X window information utility

Basic strategy;

- find out where buttons are with `xwininfo`
- press the `reroll` button with `xdotool`
- take screenshot of the `total` number with `scrot`
- compare screenshot to previous rolls
- press `store` when a new maximum is found

The script also does some extra stuff to determine the strength roll, but that's not relevant here (it just makes perfect type rolls 100 times less likely if it's a stat you optimize for).

### Initialization

To standardise what we are taking screenshots of, we need a consistent frame of reference.

`xwininfo` will give us the `x,y` coordinates of the top left corner of the game window, and then hard-code the offsets from that because the game has a consistent layout. There is [some complexity](https://github.com/Thhethssmuz/bg2ee-stat-roll/blob/5a023de83c468224aa999b5b3c60f224aae76b97/roll.sh#L20-L84) in doing this, but it has so far worked well.

> **Caveat**: You need to have **scaled the window** to size >= 1024x768 to avoid UI downscaling.

The standardised approach also helps with dealing with rolls, and it let us populate a roll-table quickly.

### Roll Tables

Taking screenshots is pretty easy. Use `scrot` at an `x,y` coordinate followed by lenghts; `,width,height` as remaining arguments defining the square to screenshot:

```sh
scrot -a "${STR_TOP_LEFT_X},${STR_TOP_LEFT_Y},49,17" -
```

the output of this can be piped to a `.png` and passed to `compare` (part of `imagemagick` package), to compare values based on thresholds. However, this idea is actually overkill..

The menu background is **static** and the resulting screenshots are actually **completely deterministic per value**, so we can instead just compare them by their hashes in one big `switch` (i.e. after piping to `md5`) and use that as our [roll table](https://github.com/Thhethssmuz/bg2ee-stat-roll/blob/5a023de83c468224aa999b5b3c60f224aae76b97/roll.sh#L130-L159), Excerpt:

```sh
    d74939b47327e4f2c1b781d64e2ab28d*) CURRENT_ROLL=90 ;;
    ca49ce8b4c9c0f814dab24668f7313fe*) CURRENT_ROLL=91 ;;
    3e6f8127ac0634bb1fc20acf40c95c48*) CURRENT_ROLL=92 ;;
    7f849edd84a4be895f5c58b4f5b20d4e*) CURRENT_ROLL=93 ;;
    b8f90179e2a0e975fc2647bc7439d9c6*) CURRENT_ROLL=94 ;;
    b1d3b73de16d750b265f5c63000ccd54*) CURRENT_ROLL=95 ;;
    87413f7310bd06b0b66fb4d2e61c5c7a*) CURRENT_ROLL=96 ;;
    b489ad2a17456f8eebe843e4b7e3e685*) CURRENT_ROLL=97 ;;
    25112e67464791f24f9e2e99d38ef9d7*) CURRENT_ROLL=98 ;;
    9c3720b9d3ab1d7f0d11dfb9771a1aef*) CURRENT_ROLL=99 ;;
    3ef9bf6cd4d9946d89765870e5b21566*) CURRENT_ROLL=100 ;;
```

## Clicking

Clicking is pretty easy;

```sh
xdotool mousemove "$REROLL_BTN_X" "$REROLL_BTN_Y" click --delay=0 1
```

Notice the `--delay=0` to override the builtin delay between clicks.

The only complication here is that BG performs **internal buffering** of clicks, so this allows us to blast through numbers faster than the screen can display them.

This means we have to compensate with a `sleep 0.001` after clicking to ensure we can grab the `scrot` of the roll before another click is registered.

## Showcase

{{< youtube 849xInj3GmI >}}

On my machine, we get just over **15 rolls per second**.

## Sampling

We rolled a human `fighter`, `paladin`, and a `ranger` overnight with roughly half a million rolls each (view-source / <a href="#appendix">appendix</a> for details), and we got these values:

<div id="rollhist" style="width:600px;height:450px;"></div>

<script>

// keys [75, 108]
var x = [...Array(109).keys()].slice(75);

// values fighter (75 -> 98)
var y1 = [137379, 109198, 85620, 65004, 48256, 35041, 24987, 17545, 11981, 7883, 5007, 3139, 1946, 1138, 670, 368, 199, 103, 49, 26, 12, 6, 2, 1];

// values paladin (75 -> 102)
var y2 = [50888, 54911, 57338, 57442, 55589, 52357, 47503, 41339, 34458, 28599, 21997, 16722, 12322, 8697, 5997, 3774, 2371, 1489, 822, 465, 251, 129, 56, 24, 12, 4, 1, 1];

// values ranger (75 -> 100)
var y3 = [32296, 37790, 43118, 46609, 48108, 47589, 45774, 41963, 36876, 30973, 25272, 19904, 14730, 10430, 7285, 4667, 2991, 1696, 986, 529, 254, 121, 56, 26, 10, 1]

// divide by number of rolls
var FIGHTER_ROLLS = y1.map(x => x / 555560);
var PALADIN_ROLLS = y2.map(x => x / 555558);
var RANGER_ROLLS = y3.map(x => x / 500054);

var trace1 = {
  x: x,
  y: FIGHTER_ROLLS,
  name: 'fighter',
  text: FIGHTER_ROLLS.map(x => "occurred once in " + Math.floor(1/x) + " rolls"),
  opacity: 0.8,
  type: "scatter",
};
var trace2 = {
  x: x,
  y: PALADIN_ROLLS ,
  name: "paladin",
  text: PALADIN_ROLLS.map(x => "occurred once in " + Math.floor(1/x) + " rolls"),
  opacity: 0.75,
  type: "scatter",
};
var trace3 = {
  x: x,
  y: RANGER_ROLLS ,
  name: "ranger",
  text: RANGER_ROLLS.map(x => "occurred once in " + Math.floor(1/x) + " rolls"),
  opacity: 0.75,
  type: "scatter",
};

var data = [trace1, trace2, trace3];
var layout = {
  title: "Roll Results",
  xaxis: {title: "Roll"},
  yaxis: {title: "Observed probability"},
};
Plotly.newPlot(document.getElementById('rollhist'), data, layout);
</script>

Let's start with the **fighter**. If we compare the fighter graph with our precise, censored multinomial distribution, they are **very close**:

<div id="probhist4" style="width:600px;height:450px;"></div>

<script>
var prob_over_74 = MAIN_PROBS.slice(75-18).reduce((acc, e) => acc + e, 0);
var SCALED_PROBS = MAIN_PROBS.slice(75-18).map(x => x / prob_over_74); // scale up by whats left

var scaled_legend = SCALED_PROBS.map(x => "expected once in " + Intl.NumberFormat().format(Math.floor(1/x)) + " rolls");

//console.log(SCALED_PROBS.reduce((acc, e) => acc + e, 0)); // 1!
var trace_fighter = {
  x: ALL_X.slice(75-18),
  y: FIGHTER_ROLLS,
  marker: {
    color: "rgba(0, 100, 102, 0.7)",
  },
  name: 'fighter',
  text: FIGHTER_ROLLS.map(x => "occurred once in " + Math.floor(1/x) + " rolls"),
  opacity: 0.8,
  type: "scatter",
};

var trace_prob = {
  x: ALL_X.slice(75-18),
  y: SCALED_PROBS,
  marker: {
    color: "rgba(100, 255, 0, 0.7)",
  },
  name: 'probability',
  text: scaled_legend,
  opacity: 0.8,
  type: "scatter",
};

var data = [trace_prob, trace_fighter];
var layout = {
  title: "Distribution vs. Observed Fighter",
  xaxis: {title: "Roll"},
  yaxis: {title: "Probability"},
};
Plotly.newPlot(document.getElementById('probhist4'), data, layout);
</script>

So for **fighters**, we can be pretty happy with the calculations we have done, and can use the precise probabilities as a guide.

> How long would it take you to achieve >95 for a fighter using the script?

- `108` is a once in `5 trillion` event (10,000 years)
- `107` is a once in `300 billion` event (600 years)
- `106` is a once in `33 billion` event (69 years)
- `105` is a once in `5 billion` event (10 years)
- `104` is a once in `900 million` event (2 years)
- `103` is a once in `200 million` event (5 months)
- `102` is a once in `50 million` event (5 weeks)
- `101` is a once in `16 million` event (2 weeks)
- `100` is a once in `5 million` event (4 days)
- `99` is a once in `2 million` event (1.5 day)
- `98` is a once in `700k` event (12h)
- `97` is a once in `270k` event (5h)
- `96` is a once in `110k` event (2h)
- `95` is a once in `50k` event (55m)

So if we only look at human fighters or mages, we can stop here:

> We are actually quite a lot more likely to get a good roll early than what just the pure dice math would indicate thanks to censoring (50k rolls => likely `95` rather than estimated `90` without censoring).

However, what's up with the paladins and rangers? Time for another math detour.

### Class/Race Variance

The reason for the discrepancy is simple: [stat floors based on races/class](https://rpg.stackexchange.com/questions/165377/how-do-baldurs-gate-and-baldurs-gate-2s-rolling-for-stats-actually-get-gene).

These stat floors are insignificant in some cases, but highly significant in others. Some highly floored classes actually push the uncensored mean above the `75` cutoff even though it's a whole 12 points above the mean of the original underlying distribution.

The floors for a some of the classes:

- **fighter** mins: `STR=9`, rest `3`
- **mage** mins: `INT=9`, rest `3`
- **paladin** mins: `CHA=17`, `WIS=13`, `STR=12`, `CON=9`, rest `3`
- **ranger** mins: `CON=14`, `WIS=14`, `STR=13`, `DEX=13`, rest `3`
- **[other classes](https://old.reddit.com/r/baldursgate/comments/reevp6/everyone_enjoys_a_good_high_ability_score_role_so/)** mins: generally light floors

<!-- TODO: can we calculate the expectation here? not unless we have a distribution to map it onto... -->

_In other words_: paladins and rangers have significantly higher rolls on average.


> Sidenote: in `2e` you actually rolled stats first, and **only if** you met the **requirements** could you become a Paladin / Ranger. This seems very anti-fun, but hey.

Now, how do we go about actually calculating useful values here?

<!--
### Idea 1: Normal Approximation

Calculating distributions when more than half of the distribution is truncated would difficult, but we can do some tricks for the `paladin` and `ranger` distribution in particularly:

We could do a simplifying step and note that multinomial distributions with a high `n` [pproximate a normal distribution](https://mathworld.wolfram.com/Dice.html) very closely (as does [most sums of independent random variables with sufficient degrees of freedom](https://en.wikipedia.org/wiki/Central_limit_theorem)).

Thus, let's assume we are at the tail end of __some__ normal distribution $\mathcal{N}(μ, σ)$, where we can estimate `μ` by inspection (in the ranger and paladin case where it exceeds the truncation point), and then we can calculate `σ` of that distribution by considering the right half we have and using symmetry.

#### With Truncation
Then, we can maybe use methods on [truncated normal distributions](https://en.wikipedia.org/wiki/Truncated_normal_distribution),


if we are dealing with [one-sided truncation of lower tail](https://en.wikipedia.org/wiki/Truncated_normal_distribution#One_sided_truncation_(of_lower_tail))), and we can use some complicated looking formulae to compute $\mathcal{E}(X | X > a)$ and $Var(X | X > a)$ (where $a$ is the cutoff point) which feels like what we can misguidedly estimate.

$Var(X | X > a) = \sigma^2[1 + \alpha \phi(\alpha)/Z - (\phi(\alpha)/Z)^2]$ where $Z = 1 - \Phi(\alpha)$

which requires us to know $\sigma$ of the underlying distribution..



#### With Censoring

...maybe we can fashion the extension methods from the [rectified normal distribution](https://en.wikipedia.org/wiki/Rectified_Gaussian_distribution) because they seem easy... just not sure if they apply. the line between censoring and truncation is a bit hard to tell which is which for us. I THINK it's truncation because in most cases we don't know much outside our range. but censoring also seems to apply; values can occur outside the range of our measring instrument (these values are not shown to us).

https://rdrr.io/cran/crch/man/cnorm.html

[this problem is very similar](https://www.rhayden.us/regression-model/the-censored-normal-distribution.html), but badly written...

[rectified normal extension](https://en.wikipedia.org/wiki/Rectified_Gaussian_distribution#Extension_to_general_bounds) (from 2017) shows that:


$\sigma_R^2 = \sigma^2 \sigma_t^2$ where:

- $\sigma^2$ is the variance of the original (unknown distribution)
- $\sigma_t^2$ is the variance of the new distribution (what we see and can measure)

similarly:

$\mu_R = \mu + \sigma \mu_t$ where:

- $\mu$ is the mean of the original unknown distribution
- $\mu_t$ is the mean of the truncated distribution (and can measure directly)

We can quickly compute $\mu_t$ and $\sigma_t$ using values from our full sample.

For $\mu$ and $\sigma$ from the original distribution, we would not always be able to, but we can be sneaky and extract it in the *paladin* and *ranger* case because we can see the mean and know the underlying distribution is symmetrical.

<script>
// values fighter (75 -> 98)
var y1 = [137379, 109198, 85620, 65004, 48256, 35041, 24987, 17545, 11981, 7883, 5007, 3139, 1946, 1138, 670, 368, 199, 103, 49, 26, 12, 6, 2, 1];

// values paladin (75 -> 102)
var y2 = [50888, 54911, 57338, 57442, 55589, 52357, 47503, 41339, 34458, 28599, 21997, 16722, 12322, 8697, 5997, 3774, 2371, 1489, 822, 465, 251, 129, 56, 24, 12, 4, 1, 1];

// values ranger (75 -> 100)
var y3 = [32296, 37790, 43118, 46609, 48108, 47589, 45774, 41963, 36876, 30973, 25272, 19904, 14730, 10430, 7285, 4667, 2991, 1696, 986, 529, 254, 121, 56, 26, 10, 1]

// 1. calculate the worthless \mu_t and \sigma_t of the truncated distribution
var y1mean = y1.map((x, i) => x*(i+75)).reduce((acc, e) => acc + e, 0) / 555560;
var y2mean = y2.map((x, i) => x*(i+75)).reduce((acc, e) => acc + e, 0) / 555558;
var y3mean = y3.map((x, i) => x*(i+75)).reduce((acc, e) => acc + e, 0) / 500054;
// sum squares for variance calc later
let y1sqsum = y1.map((x, i) => x*Math.pow(2, i+75 - y1mean)).reduce((acc, e) => acc + e, 0);
let y2sqsum = y2.map((x, i) => x*Math.pow(2, i+75 - y2mean)).reduce((acc, e) => acc + e, 0);
let y3sqsum = y3.map((x, i) => x*Math.pow(2, i+75 - y3mean)).reduce((acc, e) => acc + e, 0);
// standard deviation
var y1stddev = Math.sqrt(y1sqsum / 555560);
var y2stddev = Math.sqrt(y2sqsum / 555558);
var y3stddev = Math.sqrt(y3sqsum / 500054);
console.log("Fighter: (mu_t, sigma_t) = (" + y1mean + ", " + y1stddev + ")");
console.log("Paladin: (mu_t, sigma_t) = (" + y2mean + ", " + y2stddev + ")");
console.log("Ranger: (mu_t, sigma_t) = (" + y3mean + ", " + y3stddev + ")");
// NB: these are reasonable (sigma between 7 and 12)

// 2. estimate \mu and \sigma of the original distribution
// TODO: fix this, the variance should decrease here

// paladin: we estimate mean as 77.6 from curve, and work out 50% prob from RHS of that
var y2values = y2.slice();
y2values[0] = 0; // discount 75
y2values[1] = 0; // discount 76
y2values[2] = Math.floor(y2[2]*0.6); // discount 40% of 77
console.log('y2vals', y2values);
// how big is our sample size at RHS now? orig minus the ones we discarded
var y2_cut_samples = 555558 - y2values.reduce((acc, e) => acc+e, 0);
// calculate stddev (count every sample twice for symmetry)
var y2sqs = y2values.map((x, i) => x*2*Math.pow(2, i+75 - 77.6)).reduce((acc, e) => acc + e, 0);
var y2stddev_t = Math.sqrt(y2sqs / (y2_cut_samples*2));
y2_tail = y2values.reduce((acc, e) => acc + e, 0) / 555558;
y2_tail = Math.floor(y2_tail* 100 * 100) / 100; // 2 significant digits as percent
console.log("Paladin is at the " + y2_tail + "% tail of a normal distribution centered at 77.6 with estimated stddev_t", y2stddev_t);

// ranger: we estimate mean as 79.3 from curve, and work out 50% prob from RHS of that
var y3values = y3.slice();
y3values[0] = 0; // discount 75
y3values[1] = 0; // discount 76
y3values[2] = 0; // discount 77
y3values[3] = 0; // discount 78
y3values[4] = Math.floor(y3[2]*0.3); // discount 30% of 79
// how big is our sample size at RHS now? orig minus the ones we discarded
var y3_cut_samples = 555558 - y3values.reduce((acc, e) => acc+e, 0);
// calculate stddev (count every sample twice to fake symmetry)
var y3sqs = y3values.map((x, i) => x*2*Math.pow(2, i+75 - 79.3)).reduce((acc, e) => acc + e, 0);
var y3stddev_t = Math.sqrt(y3sqs / (y3_cut_samples*2));

y3_tail = y3values.reduce((acc, e) => acc + e, 0) / 500054;
y3_tail = Math.floor(y3_tail* 100 * 100) / 100; // 2 significant digits as percent
console.log("Ranger is at the " + y3_tail + "% tail of a normal distribution centered at 79.3 with estimated stddev_t", y3stddev_t);

// fighter.. re-use existing computation since we wouldn't know the mean easily otherwise
// and we've already shown it's very very close.
//- we know we are in 94% tail
//- we know true mean (63)
//- can we estimate the true std deviation? surely possible somehow.... TODO
console.log("Fighter is at the 94% tail of a normal distribution centered at 63");

// 3. combine the values to find the rectified distribution values:
y2_mean_rect = 75.3 + y2stddev * y2mean; // u_r = u + s * u_t
y3_mean_rect = 79.3 + y2stddev * y2mean; // u_r = u + s * u_t

y2_stddev_rect = y2stddev * y2stddev_t
y3_stddev_rect = y3stddev * y3stddev_t

console.log("Rectified Paladin has mu, sigma as: " + y2_mean_rect + ", " + y2_stddev_rect);
console.log("Rectified Ranger has mu, sigma as: " + y3_mean_rect + ", " + y3_stddev_rect);

</script>

- $Fighter \sim$ 94th percentile tail of $\mathcal{N}(63, ?)$
- $Paladin \sim$ 77h percentile tail of $\mathcal{N}(77.6, ?)$
- $Ranger \sim$ 71th percentile tail of $\mathcal{N}(79.3, ?)$

TODO: we can use $Paladin \sim \mathcal{N}^R(\mu, \sigma^2)$ at cutoff 75.

<div id="rollhistall" style="width:600px;height:450px;"></div>
<script>
// keys [75, 108]
var x = [...Array(109).keys()].slice(75);
var trace1 = {
  x: x,
  y: FIGHTER_ROLLS,
  name: 'fighter',
  text: FIGHTER_ROLLS.map(x => "occurred once in " + Math.floor(1/x) + " rolls"),
  opacity: 0.8,
  type: "scatter",
};
var trace2 = {
  x: x,
  y: PALADIN_ROLLS,
  name: "paladin",
  text: PALADIN_ROLLS.map(x => "occurred once in " + Math.floor(1/x) + " rolls"),
  opacity: 0.75,
  type: "scatter",
};
var trace3 = {
  x: x,
  y: RANGER_ROLLS,
  name: "ranger",
  text: RANGER_ROLLS.map(x => "occurred once in " + Math.floor(1/x) + " rolls"),
  opacity: 0.75,
  type: "scatter",
};
var data = [trace1, trace2, trace3];
var layout = {
  title: "Roll Results",
  xaxis: {title: "Roll"},
  yaxis: {title: "Probability"},
};
Plotly.newPlot(document.getElementById('rollhistall'), data, layout);
</script>

Interestingly, ranger has the highest mean, but paladin has the fattest tail.

-->

## New distribution from ability sums

Suppose we take a step back. We __can__ compute expectations for **individual ability scores** (even if floored) if we plot the distribution for $P(x, 3, 6)$ from [mathworld/Dice](https://mathworld.wolfram.com/Dice.html) where `s=6` and `n=3` and censor it at a cutoff point similar to how we censor the total distribution.

Same idea as when we did 18 dice; use [wolfram alpha](https://www.wolframalpha.com/input?i2d=true&i=+Divide%5B1%2CPower%5B6%2C3%5D%5DSum%5BPower%5B%5C%2840%29-1%5C%2841%29%2Ck%5D+*binomial%5C%2840%293%5C%2844%29+k%5C%2841%29*binomial%5C%2840%2910-6k-1%5C%2844%29+2%5C%2841%29%2C%7Bk%2C0%2Cfloor%5C%2840%29Divide%5B%5C%2840%2910-3%5C%2841%29%2C6%5D%5C%2841%29%7D%5D) and tabulate for $[3, \ldots, 18]$:

<div id="probhist3roll" style="width:600px;height:450px;"></div>

<script>
var THREEROLL_X = [3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18];
// probabilities for p=3 up to p=18 (also sums to 0.9999999999999999)
var THREEROLL_PROBS = [1/216, 1/72, 1/36, 5/108, 5/72, 7/72, 25/216, 1/8, 1/8, 25/216, 7/72, 5/72, 5/108, 1/36, 1/72, 1/216];
console.log("probability sum for 3d6 =", THREEROLL_PROBS.reduce((acc, e) => acc+e, 0));

var expectation_unt = THREEROLL_PROBS.map((x,i) => (i+3)*x).reduce((acc, e) => acc+e, 0);
var variance_unt = THREEROLL_PROBS.map((x,i) => Math.pow(i+3 - expectation_unt, 2)*x).reduce((acc, e) => acc+e, 0);
console.log("Expectation, variance for untruncated 3d6", expectation_unt, variance_unt);


var THREE_LEGEND = THREEROLL_PROBS.map(x => "expected once in " + Intl.NumberFormat().format(Math.floor(1/x)) + " rolls")

var trace = {
  x: THREEROLL_X,
  y: THREEROLL_PROBS,
  marker: {
    color: "rgba(255, 100, 102, 0.7)",
    line: {
      color:  "rgba(255, 100, 102, 1)",
    }
  },
  name: 'probability',
  text: THREE_LEGEND,
  opacity: 0.8,
  type: "scatter",
};


var data = [trace];
var layout = {
  title: "Distribution for the sum of 3d6 dice rolls",
  xaxis: {title: "Roll"},
  yaxis: {title: "Probability"},
};
Plotly.newPlot(document.getElementById('probhist3roll'), data, layout);
</script>

then we truncate this at the observed floor points `9`, `12`, `13`, `14`, and `17`:


<div id="probhist3rolltruncs" style="width:600px;height:450px;"></div>

<script>
var truncated_trace = function (t) {
  // calculate probability up to cutoff point:
  var TRUNC_T_SUM = THREEROLL_PROBS.slice(t-3).reduce((acc, e) => acc+e, 0);
  // truncate and scale (rectify) the right side of the distribution:
  var THREE_TRUNC_T = THREEROLL_PROBS.slice(t-3).map(x => x / TRUNC_T_SUM);
  // sanity sum (all 1)
  //console.log("Sum of 3d6 truncated at ", t, ":", THREE_TRUNC_T.reduce((acc, e)=>acc+e, 0));
  var expectation = THREE_TRUNC_T.map((x,i) => (i+t)*x).reduce((acc, e) => acc+e, 0);
  var variance = THREE_TRUNC_T.map((x,i) => Math.pow(i+t - expectation, 2)*x).reduce((acc, e) => acc+e, 0);
  console.log("Expectation, variance for truncated 3d6 at", t, expectation, variance);
  var trace = {
    x: THREEROLL_X.slice(t-3),
    y: THREE_TRUNC_T,
    name: 'floor ' + t,
    text: THREE_TRUNC_T.map(x => "expected once in " + Intl.NumberFormat('en-IN', {maximumSignificantDigits: 2}).format(1/x) + " rolls"),
    opacity: 0.8,
    type: "scatter",
  };
  return trace;
};

let trace_9 = truncated_trace(9);
let trace_12 = truncated_trace(12);
let trace_13 = truncated_trace(13);
let trace_14 = truncated_trace(14);
let trace_17 = truncated_trace(17);

var data = [trace_9, trace_12, trace_13, trace_14, trace_17];
var layout = {
  title: "Rectified Distribution for the sum of 3d6 dice rolls",
  xaxis: {title: "Roll"},
  yaxis: {title: "Probability"},
};
Plotly.newPlot(document.getElementById('probhist3rolltruncs'), data, layout);
</script>

We can then compute precise conditional expectations by floor:

- $E(X) = 3\sum_{k=1}^{6}\frac{k}{6} = 3*3.5 = 10.5$
- $E(X | X\ge9) = 11.8125$
- $E(X | X\ge12) = 13.5555$
- $E(X | X\ge13) = 14.2500$
- $E(X | X\ge14) = 15.0000$
- $E(X | X\ge17) = 17.2500$

and use this to compute class means by summing across the 6 main stats:

- $E(Fighter) = E(X | X \ge 9) + 5E(X) = 64.31$
- $E(Ranger) = 2E(X | X\ge14) + 2E(X | X\ge13) + 2E(X) = 79.5$
- $E(Paladin) = E(X | X\ge17) + E(X | X\ge13) + E(X | X\ge12) + E(X | X\ge9)+ 2E(X) = 77.86$

Similarly, we can compute precise variances:

- $Var(X) = 3\sum_{k=1}^6\frac{(x_i - 3.5)^2}{6} = 3*2.92 = 8.75$
- $Var(X | X\ge9) = 4.5773$
- $Var(X | X\ge12) = 2.2469$
- $Var(X | X\ge13) = 1.6875$
- $Var(X | X\ge14) = 1.2000$
- $Var(X | X\ge17) = 0.1875$

and sum them up across the 6 main stats:

- $Var(Fighter) = Var(X | X \ge 9) + 5Var(X) \thickapprox 6.95^2$
- $Var(Ranger) = 2Var(X | X\ge14) + 2Var(X | X\ge13) + 2Var(X) \thickapprox 4.82^2$
- $Var(Paladin) = Var(X | X\ge17) + Var(X | X\ge13) + Var(X | X\ge12) + Var(X | X\ge9)+ 2Var(X) \thickapprox 5.12^2$

noting that variables are independent under the observed two stage censoring.

> Why can we rely on two stage censoring and their independence? If any of these internal mechanisms used some kind of `min` function, it would be immediately obvious from the distribution. The paladin distribution of charisma is clearly a `~1/4` for an `18`, and `~3/4` for a `17`; it would have been **very** rare to see an 18 otherwise.

Thus, the classes follow truncated multinomial-based distributions $\mathcal{M}^T(\mu, \sigma^2)$ with the following initial moments:

- $Fighter \sim \mathcal{M}^T(64.31, 6.95^2)$
- $Ranger \sim \mathcal{M}^T(79.5, 4.82^2)$
- $Paladin \sim \mathcal{M}^T(77.86, 5.12^2)$

### Rough Estimation of Values

We can do a hand-wavy estimating from [normal distributed sigma-level events](https://en.wikipedia.org/wiki/68%E2%80%9395%E2%80%9399.7_rule), an [error function calculator](https://keisan.casio.com/exec/system/1180573449), and our 15 roll per second time for the script.

This is not going to give very accurate numbers, because the data is not normally distributed at this low level of dice rolling, but it should give a very rough guideline.

#### Ranger estimations

We compute $\sigma$ breakpoints using $79.5 + n*4.82$:

- 108 is a $5.9\sigma$ event, once in 275M (30 weeks)
- 106 is a $5.5\sigma$ event, once in 26M (3 weeks)
- 104 is a $5.1\sigma$ event, once in 3M (2 days)
- 101 is a $4.5\sigma$ event, once in 150k (3h)
- 99 is a $4\sigma$ event, once in 16k (17m)
- 96 is a $3.4\sigma$ event, once in 1500 (2m)
- 94 is a $3\sigma$ event, once in 400 (30s)

#### Paladin estimations

We compute $\sigma$ breakpoints using $78.86 + n*5.12$:

- 108 is a $5.7\sigma$ event, once in 83M (9 weeks)
- 106 is a $5.3\sigma$ event, once in 9M (7 days)
- 104 is a $4.9\sigma$ event, once in 1M (18h)
- 102 is a $4.5\sigma$ event, once in 150k (3h)
- 99 is a $3.9\sigma$ event, once in 10k (11m)
- 97 is a $3.5\sigma$ event, once in 2k (2m)
- 94 is a $3\sigma$ event, once in 400 (30s)

As we can see, the high variance of paladin compensates for its lower mean compared to the ranger, and is therefore your best bet for record breaking rolls.

If this calculation is semi-accurate then if `63` people roll the script for paladin for `1 day`, we are likely to collectively get an `108`...

### Getting precise probabilities

Because estimating tends to fall over a bit at high sigma levels (where we are interested in the values), we ideally want to have a precise [PDF](https://en.wikipedia.org/wiki/Probability_density_function) for a random variable:

$Z_{paladin} = X_1^{\lfloor17\rfloor} + X_2^{\lfloor13\rfloor} + X_3^{\lfloor12\rfloor} + X_4^{\lfloor9\rfloor} + X_5^{\lfloor0\rfloor} + X_6^{\lfloor0\rfloor}$

where $X_i^{\lfloor N \rfloor}$ is the precise, `3d6` based multinomial distribution rectified at $N$.

We have already computed the first [moments](https://en.wikipedia.org/wiki/Moment_(mathematics)) (expectations and variance) of these sum random variables, but precise probabilities is harder.

It is actually possible to [inductively compute](https://stats.libretexts.org/Bookshelves/Probability_Theory/Book%3A_Introductory_Probability_(Grinstead_and_Snell)/07%3A_Sums_of_Random_Variables/7.01%3A_Sums_of_Discrete_Random_Variables) the pdfs of $Z$ via convolution. This [answer explains it in the simplest terms](https://stats.stackexchange.com/questions/3614/how-to-easily-determine-the-results-distribution-for-multiple-dice/3684#3684).

However, this also requires **either** mathematica functions (that we do not have here in our inlined source), **or** we need to go through a laborious and manual through [characteristic functions](https://en.wikipedia.org/wiki/Characteristic_function_(probability_theory)) (see [sum of multinomials answer](https://math.stackexchange.com/questions/3076634/sum-of-two-multinomial-random-variables)) and [convolution](https://en.wikipedia.org/wiki/Convolution#Discrete_convolution). If someone wants to contribute or help out here, I'd be interested to see, but for my own sanity; we will leave this here for now.

Hope you have enjoy this infrequent brain dump.

<small>/me closes 20 tabs</small>

## Appendix
<details><summary style="cursor:pointer"><b>1. Raw data</b></summary>
<p>

10 hour paladin roll (`555558` rolls in `601m`)

```yaml
75: 50888
76: 54911
77: 57338
78: 57442
79: 55589
80: 52357
81: 47503
82: 41339
83: 34458
84: 28599
85: 21997
86: 16722
87: 12322
88: 8697
89: 5997
90: 3774
91: 2371
92: 1489
93: 822
94: 465
95: 251
96: 129
97: 56
98: 24
99: 12
100: 4
101: 1
102: 1
```

10 hour fighter roll (`555560` rolls in `608m`)

```yaml
75: 137379
76: 109198
77: 85620
78: 65004
79: 48256
80: 35041
81: 24987
82: 17545
83: 11981
84: 7883
85: 5007
86: 3139
87: 1946
88: 1138
89: 670
90: 368
91: 199
92: 103
93: 49
94: 26
95: 12
96: 6
97: 2
98: 1
```

9 hour ranger roll (`500054` rolls in `548m`)

```yaml
75: 32296
76: 37790
77: 43118
78: 46609
79: 48108
80: 47589
81: 45774
82: 41963
83: 36876
84: 30973
85: 25272
86: 19904
87: 14730
88: 10430
89: 7285
90: 4667
91: 2991
92: 1696
93: 986
94: 529
95: 254
96: 121
97: 56
98: 26
99: 10
100: 1
```

</p>
</details>

<details><summary style="cursor:pointer"><b>2. Tabulated values for 18 dice multinomial probability distribution</b></summary>
<p>

[Wolfram Alpha Query](https://www.wolframalpha.com/input?i2d=true&i=+Divide%5B1%2CPower%5B6%2C18%5D%5DSum%5BPower%5B%5C%2840%29-1%5C%2841%29%2Ck%5D+*binomial%5C%2840%2918%5C%2844%29+k%5C%2841%29*binomial%5C%2840%2991-6k-1%5C%2844%29+17%5C%2841%29%2C%7Bk%2C0%2Cfloor%5C%2840%29Divide%5B%5C%2840%2991-18%5C%2841%29%2C6%5D%5C%2841%29%7D%5D)

```yaml
18  : 1/101559956668416
19  : 1/5642219814912
20  : 19/11284439629824
21  : 95/8463329722368
22  : 665/11284439629824
23  : 1463/5642219814912
24  : 33643/33853318889472
25  : 9605/2821109907456
26  : 119833/11284439629824
27  : 1552015/50779978334208
28  : 308465/3761479876608
29  : 97223/470184984576
30  : 2782169/5642219814912
31  : 1051229/940369969152
32  : 4550747/1880739938304
33  : 786505/156728328192
34  : 37624655/3761479876608
35  : 36131483/1880739938304
36  : 1206294965/33853318889472
37  : 20045551/313456656384
38  : 139474379/1253826625536
39  : 1059736685/5642219814912
40  : 128825225/417942208512
41  : 17143871/34828517376
42  : 8640663457/11284439629824
43  : 728073331/626913312768
44  : 2155134523/1253826625536
45  : 3942228889/1586874322944
46  : 4949217565/1410554953728
47  : 3417441745/705277476864
48  : 27703245169/4231664861184
49  : 3052981465/352638738432
50  : 126513483013/11284439629824
51  : 240741263447/16926659444736
52  : 199524184055/11284439629824
53  : 60788736553/2821109907456
54  : 2615090074301/101559956668416
55  : 56759069113/1880739938304
56  : 130521904423/3761479876608
57  : 110438453753/2821109907456
58  : 163027882055/3761479876608
59  : 88576807769/1880739938304
60  : 566880747559/11284439629824
61  : 24732579319/470184984576
62  : 101698030955/1880739938304
63  : 461867856157/8463329722368
64  : 101698030955/1880739938304
65  : 24732579319/470184984576
66  : 566880747559/11284439629824
67  : 88576807769/1880739938304
68  : 163027882055/3761479876608
69  : 110438453753/2821109907456
70  : 130521904423/3761479876608
71  : 56759069113/1880739938304
72  : 2615090074301/101559956668416
73  : 60788736553/2821109907456
74  : 199524184055/11284439629824
75  : 240741263447/16926659444736
76  : 126513483013/11284439629824
77  : 3052981465/352638738432
78  : 27703245169/4231664861184
79  : 3417441745/705277476864
80  : 4949217565/1410554953728
81  : 3942228889/1586874322944
82  : 2155134523/1253826625536
83  : 728073331/626913312768
84  : 8640663457/11284439629824
85  : 17143871/34828517376
86  : 128825225/417942208512
87  : 1059736685/5642219814912
88  : 139474379/1253826625536
89  : 20045551/313456656384
90  : 1206294965/33853318889472
91  : 36131483/1880739938304
92  : 37624655/3761479876608
93  : 786505/156728328192
94  : 4550747/1880739938304
95  : 1051229/940369969152
96  : 2782169/5642219814912
97  : 97223/470184984576
98  : 308465/3761479876608
99  : 1552015/50779978334208
100 : 119833/11284439629824
101 : 9605/2821109907456
102 : 33643/33853318889472
103 : 1463/5642219814912
104 : 665/11284439629824
105 : 95/8463329722368
106 : 19/11284439629824
107 : 1/5642219814912
108 : 1/101559956668416
```
</p>
</details>

<details><summary style="cursor:pointer"><b>3. Tabulated values for 3 dice multinomial probability distribution</b></summary>
<p>

[Wolfram Alpha Query](https://www.wolframalpha.com/input?i2d=true&i=+Divide%5B1%2CPower%5B6%2C3%5D%5DSum%5BPower%5B%5C%2840%29-1%5C%2841%29%2Ck%5D+*binomial%5C%2840%293%5C%2844%29+k%5C%2841%29*binomial%5C%2840%2910-6k-1%5C%2844%29+2%5C%2841%29%2C%7Bk%2C0%2Cfloor%5C%2840%29Divide%5B%5C%2840%2910-3%5C%2841%29%2C6%5D%5C%2841%29%7D%5D)

```yaml:
3: 1/216
4: 1/72
5: 1/36
6: 5/108
7: 5/72
8: 7/72
9: 25/216
10: 1/8
11: 1/8
12: 25/216
13: 7/72
14: 5/72
15: 5/108
16: 1/36
17: 1/72
18: 1/216
```

</p>
</details>
