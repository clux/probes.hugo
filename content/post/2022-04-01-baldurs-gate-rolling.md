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

TODO: gif/video of how it looks

It's a pretty dumb design idea to port the rolling mechanics from `d&d` into the game. In a normal campaign you'd get one chance rolling, but here, there's no downside to keeping going, encouraging excessive time investment (the irony in writing this blog post is not lost on me). They should have just gone for something like [5e point buy](https://chicken-dinner.com/5e/5e-point-buy.html).

Still, **suppose** (as an excuse to talk about multinomials, combinatorics, and weird `X` tools) you want to **automate rolling** and figure out **how long it will take** you to receive a **good roll** without doing anything.

> ..it's less time than it took to write this blogpost.

## Disclaimer

Using the script used herein to achieve higher rolls than you have patience for, is on some level; **cheating**. That said; no-one cares, and it's a fairly pointless effort:

- this is an [old](https://en.wikipedia.org/wiki/Baldur%27s_Gate_II:_Shadows_of_Amn) single player game, and you can reduce the difficulty
- having [dump stats](https://tvtropes.org/pmwiki/pmwiki.php/Main/DumpStat) is not heavily penalized in the game
- early items nullify effects of common dump stats ([19 STR girdle](https://baldursgate.fandom.com/wiki/Girdle_of_Hill_Giant_Strength) or [18 CHA ring](https://baldursgate.fandom.com/wiki/Ring_of_Human_Influence))
- you can get [max stats in 20 minutes](https://www.youtube.com/watch?v=5dDmh98lmkA) with by abusing inventory [bugs](https://baldursgate.fandom.com/wiki/Exploits#Potion_Swap_Glitch)
- some [NPCS](https://baldursgate.fandom.com/wiki/Edwin_Odesseiron) come with [gear](https://baldursgate.fandom.com/wiki/Edwin%27s_Amulet) that blows __marginally better stats__ out of the water

So assuming you have a reason to be here despite this; let's dive in to some maths.

## Multinomials and probabilities

> How many rolls would you need to get 90/95/100?

Rolling a 6 sided dice 18 times follows the [multinomial distribution](https://en.wikipedia.org/wiki/Multinomial_distribution) ($k=6$, and $p_i = 1/6$ for all $i$), and the expected value of 18 dice rolls would be $18*(7/2) = 63$.

We are going to follow the multinomial expansion at [mathworld/Dice](https://mathworld.wolfram.com/Dice.html) for `s=6` and `n=18` and find $P(x, 18, 6)$ which we will denote as $P(X = x)$:

$$P(X = x) = \frac{1}{6^{18}} \sum_{k=0}^{\lfloor(x-18)/6\rfloor} (-1)^k \binom{18}{k} \binom{x-6k-1}{17}$$
$$ = \sum_{k=0}^{k_{max}} (-1)^k \frac{18}{k!(18-k)!} \frac{(x-6k-1)!}{(x-6k-18)!}$$

which.. when cased for $k_{max}$ would yield 15 different sum expressions, and the ones we care about would all have 10+ expressions. So rather than trying to reduce this to a polynomial expression over $p$, we will [paste values into wolfram alpha](https://www.wolframalpha.com/input?i2d=true&i=+Divide%5B1%2CPower%5B6%2C18%5D%5DSum%5BPower%5B%5C%2840%29-1%5C%2841%29%2Ck%5D+*binomial%5C%2840%2918%5C%2844%29+k%5C%2841%29*binomial%5C%2840%2991-6k-1%5C%2844%29+17%5C%2841%29%2C%7Bk%2C0%2Cfloor%5C%2840%29Divide%5B%5C%2840%2991-18%5C%2841%29%2C6%5D%5C%2841%29%7D%5D) and tabulate for $[18, \ldots, 108]$.

<!--tabulated values:

```
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
-->

This yields the following distribution:

<div id="probhist" style="width:600px;height:450px;"></div>

<script>

// keys [18, 108]
window.ALL_X = [...Array(109).keys()].slice(18);

// probabilities for p=18 up to p=108 (sums to 0.9999999999999999 \o/)
window.MAIN_PROBS = [1/101559956668416, 1/5642219814912, 19/11284439629824, 95/8463329722368, 665/11284439629824, 1463/5642219814912, 33643/33853318889472, 9605/2821109907456, 119833/11284439629824, 1552015/50779978334208, 308465/3761479876608, 97223/470184984576, 2782169/5642219814912, 1051229/940369969152, 4550747/1880739938304, 786505/156728328192, 37624655/3761479876608, 36131483/1880739938304, 1206294965/33853318889472, 20045551/313456656384, 139474379/1253826625536, 1059736685/5642219814912, 128825225/417942208512, 17143871/34828517376, 8640663457/11284439629824, 728073331/626913312768, 2155134523/1253826625536, 3942228889/1586874322944, 4949217565/1410554953728, 3417441745/705277476864, 27703245169/4231664861184, 3052981465/352638738432, 126513483013/11284439629824, 240741263447/16926659444736, 199524184055/11284439629824, 60788736553/2821109907456, 2615090074301/101559956668416, 56759069113/1880739938304, 130521904423/3761479876608, 110438453753/2821109907456, 163027882055/3761479876608, 88576807769/1880739938304, 566880747559/11284439629824, 24732579319/470184984576, 101698030955/1880739938304, 461867856157/8463329722368, 101698030955/1880739938304, 24732579319/470184984576, 566880747559/11284439629824, 88576807769/1880739938304, 163027882055/3761479876608, 110438453753/2821109907456, 130521904423/3761479876608, 56759069113/1880739938304, 2615090074301/101559956668416, 60788736553/2821109907456, 199524184055/11284439629824, 240741263447/16926659444736, 126513483013/11284439629824, 3052981465/352638738432, 27703245169/4231664861184, 3417441745/705277476864, 4949217565/1410554953728, 3942228889/1586874322944, 2155134523/1253826625536, 728073331/626913312768, 8640663457/11284439629824, 17143871/34828517376, 128825225/417942208512, 1059736685/5642219814912, 139474379/1253826625536, 20045551/313456656384, 1206294965/33853318889472, 36131483/1880739938304, 37624655/3761479876608, 786505/156728328192, 4550747/1880739938304, 1051229/940369969152, 2782169/5642219814912, 97223/470184984576, 308465/3761479876608, 1552015/50779978334208, 119833/11284439629824, 9605/2821109907456, 33643/33853318889472, 1463/5642219814912, 665/11284439629824, 95/8463329722368, 19/11284439629824, 1/5642219814912, 1/101559956668416];

window.MAIN_LEGEND = window.MAIN_PROBS.map(x => "expected once in " + Intl.NumberFormat().format(Math.floor(1/x)) + " rolls")

var trace = {
  x: window.ALL_X,
  y: window.MAIN_PROBS,
  marker: {
    color: "rgba(255, 100, 102, 0.7)",
    line: {
      color:  "rgba(255, 100, 102, 1)",
    }
  },
  name: 'probability',
  text: window.MAIN_LEGEND,
  opacity: 0.8,
  type: "scatter",
};


var data = [trace];
var layout = {
  title: "Distribution for the sum of 18d6 dice rolls",
  // TODO: annotation on cutoff
  xaxis: {title: "Roll"},
  yaxis: {title: "Probability"},
};
PROBHIST = document.getElementById('probhist');
Plotly.newPlot(PROBHIST, data, layout);
</script>


This is how things should look on paper. From the chart you can extract:

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

**But is this really right?** A [lot](https://old.reddit.com/r/baldursgate/comments/svnyy5/this_is_why_i_let_my_gf_roll_my_stats_lol/hxhde5k/) of [people](https://old.reddit.com/r/baldursgate/comments/tak2m7/say_hello_to_my_archer_roll/) have [all](https://old.reddit.com/r/baldursgate/comments/rjnw22/less_than_a_minute_of_rolling_this_is_my_alltime/) rolled nineties in just a few hundred rolls.. was that just luck, or are higher numbers more likely than what this distribution says?

Well, let's start with the obvious. We don't see rolls below $75$:

<div id="probhist2" style="width:600px;height:450px;"></div>

<script>
var trace = {
  x: window.ALL_X,
  y: window.MAIN_PROBS,
  marker: {
    color: "rgba(255, 100, 102, 0.7)",
    line: {
      color:  "rgba(255, 100, 102, 1)",
    }
  },
  name: 'probability',
  text: window.MAIN_LEGEND,
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
PROBHIST = document.getElementById('probhist2');
Plotly.newPlot(PROBHIST, data, layout);
</script>

What's **left of this cutoff** actually accounts for `94%` of the distribution. If the game did not do this, you'd be as likely getting `36` as a `90`. We are effectively throwing away "19 bad rolls" on every roll.

> Note that `AD&D 2e` also had [ways to tilt the distribution towards the player](https://advanced-dungeons-dragons-2nd-edition.fandom.com/wiki/Rolling_Ability_Scores) that resulted in more "heroic" characters.

To compensate for this, we need to **scale up** the probabilities of the latter events. Let's assume that when the game rolls internally, it just discards results below the cutoff (so the distribution is otherwise unaltered). In that, case we would expect this:

<div id="probhist3" style="width:600px;height:450px;"></div>

<script>
var prob_over_74 = window.MAIN_PROBS.slice(75-18).reduce((acc, e) => acc + e, 0);
window.SCALED_PROBS = window.MAIN_PROBS.slice(75-18).map(x => x / prob_over_74); // scale up by whats left

var scaled_legend = window.SCALED_PROBS.map(x => "expected once in " + Intl.NumberFormat().format(Math.floor(1/x)) + " rolls");

//console.log("probability of rolling gte 75", prob_over_74);
//console.log(window.SCALED_PROBS.reduce((acc, e) => acc + e, 0)); // 1!

var trace = {
  x: window.ALL_X.slice(75-18),
  y: window.SCALED_PROBS,
  marker: {
    color: "rgba(255, 100, 102, 0.7)",
    line: {
      color:  "rgba(255, 100, 102, 1)",
    }
  },
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
PROBHIST = document.getElementById('probhist3');
Plotly.newPlot(PROBHIST, data, layout);
</script>

Here we have divided by the sum of the probabilities of the right hand side of the graph $P(X >= 75)$ as this creates a new distribution, that sums to `1`, but is otherwise a mere up-scaling of the right-hand side.

This is actually bang on for **most** cases, and we will **demonstrate** this.

But first, we are going to need to press the `reroll` button a lot...

## Automating Rolling

We will go through the [script we use](https://github.com/Thhethssmuz/bg2ee-stat-roll).

### Tools

We are playing on **Linux** with `X` and some obscure associated tooling:

- `scrot` - X screenshot utility
- `xdotool` - X CLI automation tool
- `xwininfo` - X window information utility

Basic strategy;

- find out where buttons are with `xwininfo`
- press the `re-roll` button with `xdotool`
- take screenshot of the `total` number with `scrot`
- compare screenshot to previous rolls
- press `store` when a new maximum is found

The script also does some extra stuff to determine the strength roll, but that's not relevant here.

### Initialization

My brother decided to write a completely overkill thing here; taking progressive screenshots and compensating for the window manager bar height, and relying on BG2EE's consistent layout to hardcode offsets. Not going through this, it is insanity. But, assuming you are on Linux with X, it should probably work for you...

The standardised approach also helps with dealing with rolls, and it let us populate a roll-table.

### Roll Tables

Taking screenshots is pretty easy. Use `scrot` at an `x,y` coordinate followed by `,width,height` as remaining arguments defining the square:

```sh
scrot -a "${STR_TOP_LEFT_X},${STR_TOP_LEFT_Y},49,17"
```

the output of this can be piped to a `.png` and passed to `compare` (part of `imagemagick` package), to compare values based on thresholds. However, this idea is actually overkill..

Because the background is static and nothing moves, the screenshots are actually completely deterministic per value and you can instead just compare them by their hashes (i.e. pipe to `md5`), and save the result in a table:

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

That's an excerpt of some of the later roll hashes from the [actual table](https://github.com/Thhethssmuz/bg2ee-stat-roll/blob/5a023de83c468224aa999b5b3c60f224aae76b97/roll.sh#L130-L159).

## Clicking

Clicking is pretty easy;

```sh
xdotool mousemove "$REROLL_BTN_X" "$REROLL_BTN_Y" click --delay=0 1
```

Notice the `--delay=0` to override the builtin delay between clicks.

It turns out BG performs internal buffering of clicks, so this allows you to blast through numbers faster than the screen can display them.

This means we have to compensate with a `sleep 0.001` after clicking to ensure we can grab the `scrot` of the roll before another click is registered.

## Showcase

TODO: video

On my PC we get just over **15 rolls per second**.



## Distribution

We rolled a human `fighter`, `paladin`, and a `ranger` overnight with roughly half a million rolls each (view source for details), and we get these distributions:

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
window.FIGHTER_ROLLS = y1.map(x => x / 555560);
window.PALADIN_ROLLS = y2.map(x => x / 555558);
window.RANGER_ROLLS = y3.map(x => x / 500054);

var y1legend = window.FIGHTER_ROLLS.map(x => "occurred once in " + Math.floor(1/x) + " rolls");
var y2legend = window.PALADIN_ROLLS.map(x => "occurred once in " + Math.floor(1/x) + " rolls");
var y3legend = window.RANGER_ROLLS.map(x => "occurred once in " + Math.floor(1/x) + " rolls");

var trace1 = {
  x: x,
  y: window.FIGHTER_ROLLS,
  marker: {
    color: "rgba(255, 100, 102, 0.7)",
    line: {
      color:  "rgba(255, 100, 102, 1)",
    //  width: 1
    }
  },
  name: 'fighter',
  text: y1legend,
  opacity: 0.8,
  type: "scatter",
};
var trace2 = {
  x: x,
  y: window.PALADIN_ROLLS ,
  marker: {
    color: "rgba(100, 200, 102, 0.7)",
    line: {
        color:  "rgba(100, 200, 102, 1)",
        //width: 1
    }
  },
  name: "paladin",
  text: y2legend,
  opacity: 0.75,
  type: "scatter",
};
var trace3 = {
  x: x,
  y: window.RANGER_ROLLS ,
  marker: {
    color: "rgba(100, 100, 200, 0.7)",
    line: {
        color:  "rgba(100, 100, 200, 1)",
        //width: 1
    }
  },
  name: "ranger",
  text: y3legend,
  opacity: 0.75,
  type: "scatter",
};

var data = [trace1, trace2, trace3];
var layout = {
  title: "Roll Results",
  xaxis: {title: "Roll"},
  yaxis: {title: "Probability"},
};
HISTOG = document.getElementById('rollhist');
Plotly.newPlot(HISTOG, data, layout);
</script>

Let's start with the **fighter**. If we compare the fighter graph with the computed, scaled distribution, they are almost identical:

<div id="probhist4" style="width:600px;height:450px;"></div>

<script>
var prob_over_74 = window.MAIN_PROBS.slice(75-18).reduce((acc, e) => acc + e, 0);
window.SCALED_PROBS = window.MAIN_PROBS.slice(75-18).map(x => x / prob_over_74); // scale up by whats left

var scaled_legend = window.SCALED_PROBS.map(x => "expected once in " + Intl.NumberFormat().format(Math.floor(1/x)) + " rolls");

//console.log(window.SCALED_PROBS.reduce((acc, e) => acc + e, 0)); // 1!
var trace_fighter = {
  x: window.ALL_X.slice(75-18),
  y: FIGHTER_ROLLS,
  marker: {
    color: "rgba(0, 100, 102, 0.7)",
    line: {
      color:  "rgba(0, 100, 102, 1)",
    //  width: 1
    }
  },
  name: 'fighter',
  text: y1legend,
  opacity: 0.8,
  type: "scatter",
};

var trace_prob = {
  x: window.ALL_X.slice(75-18),
  y: window.SCALED_PROBS,
  marker: {
    color: "rgba(100, 255, 0, 0.7)",
    line: {
      color:  "rgba(100, 255, 0, 1)",
    }
  },
  name: 'probability',
  text: scaled_legend,
  opacity: 0.8,
  type: "scatter",
};

var data = [trace_prob, trace_fighter];
var layout = {
  title: "Distribution vs. Fighter",
  xaxis: {title: "Roll"},
  yaxis: {title: "Chance"},
};
PROBHIST = document.getElementById('probhist4');
Plotly.newPlot(PROBHIST, data, layout);
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

So in conclusion; comparing to the unscaled calculation, we are actually quite a lot more likely to get a good roll early than what just the pure dice math would indicate (likely `95` rather than estimated `90` for 50k rolls).


However, what's up with the paladins and rangers?

### Class/Race Variance

The final point here is something that's harder to account for: [stat floors based on races/class](https://rpg.stackexchange.com/questions/165377/how-do-baldurs-gate-and-baldurs-gate-2s-rolling-for-stats-actually-get-gene).

For some classes, these **stat floors** actually push their mean above the `75` cutoff even though it's 12 points above the mean of the original underlying distribution.

- **fighter** mins: `STR=9`, rest `3`
- **mage** mins: `INT=9`, rest `3`
- **paladin** mins: `CHA=17`, `WIS=13`, `STR=12`, `CON=9`, rest `3`
- **ranger** mins: `CON=14`, `WIS=14`, `STR=13`, `DEX=13`, rest `3`
- **[other classes](https://old.reddit.com/r/baldursgate/comments/reevp6/everyone_enjoys_a_good_high_ability_score_role_so/)** mins: generally light floors

_In other words_: paladins and rangers have significantly higher rolls on average.

> Sidenote: in `2e` you actually rolled stats first, and **only if** you met the **requirements** could you become a Paladin / Ranger. That seems crazy exclusionary to me, but hey.

<!--
How the __flooring__ is performed would matter to our distribution. I.e. does the game:

- does it roll each stat, and return `min(roll, statmin)`?
- keep rolling internally until the minimums are met?
- generate a random number uniformly in the range rather than roll 3 dice?
- something else?

We can probably rule out the second option; if it just discarded rolls internally the resulting distribution would look scaled, not translated right. The third option also feels unlikely, the falloff for paladin looks similarly steep.

Short of reverse engineering, it's hard to nail down the distribution exactly without recomputing the entire thing.
-->

Calculating distributions with all these restrictions is beyond the scope of what is sane here. We will do the simplifying step we should probably have used at the beginning, and note that multinomial distributions with this `n` [approximate a normal distribution very closely](https://mathworld.wolfram.com/Dice.html), and so does [most sums of independent random variables with sufficient degrees of freedom](https://en.wikipedia.org/wiki/Central_limit_theorem).

So let's assume we are at the tail end of some normal distribution $\mathcal{N}(μ, σ)$, where we can estimate `μ` by inspection `σ`

<script>
// values fighter (75 -> 98)
var y1 = [137379, 109198, 85620, 65004, 48256, 35041, 24987, 17545, 11981, 7883, 5007, 3139, 1946, 1138, 670, 368, 199, 103, 49, 26, 12, 6, 2, 1];

// values paladin (75 -> 102)
var y2 = [50888, 54911, 57338, 57442, 55589, 52357, 47503, 41339, 34458, 28599, 21997, 16722, 12322, 8697, 5997, 3774, 2371, 1489, 822, 465, 251, 129, 56, 24, 12, 4, 1, 1];

// values ranger (75 -> 100)
var y3 = [32296, 37790, 43118, 46609, 48108, 47589, 45774, 41963, 36876, 30973, 25272, 19904, 14730, 10430, 7285, 4667, 2991, 1696, 986, 529, 254, 121, 56, 26, 10, 1]

// NB: these are useless... need the underlying distribution...
//var FIGHTER_MEAN = y1.map((x, i) => x*(i+75)).reduce((acc, e) => acc + e, 0) / 555560;
//var PALADIN_MEAN = y2.map((x, i) => x*(i+75)).reduce((acc, e) => acc + e, 0) / 555558;
//var RANGER_MEAN = y3.map((x, i) => x*(i+75)).reduce((acc, e) => acc + e, 0) / 500054;
// sum squares for variance calc later
//let y1sqsum = y1.map((x, i) => x*Math.pow(2, i+75 - FIGHTER_MEAN)).reduce((acc, e) => acc + e, 0);
//let y2sqsum = y2.map((x, i) => x*Math.pow(2, i+75 - PALADIN_MEAN)).reduce((acc, e) => acc + e, 0);
//let y3sqsum = y3.map((x, i) => x*Math.pow(2, i+75 - RANGER_MEAN)).reduce((acc, e) => acc + e, 0);
// standard deviation
//var FIGHTER_STD = Math.sqrt(y1sqsum / 555560);
//var PALADIN_STD = Math.sqrt(y2sqsum / 555558);
//var RANGER_STD = Math.sqrt(y3sqsum / 500054);
//console.log("Fighter: " + FIGHTER_MEAN + ", " + FIGHTER_STD);
//console.log("Paladin: " + PALADIN_MEAN + ", " + PALADIN_STD);
//console.log("Fighter: " + RANGER_MEAN + ", " + RANGER_STD);

// paladin: we estimate mean as 77.6 from curve, and work out 50% prob from RHS of that
var y2values = y2.slice();
y2values[0] = 0; // discount 75
y2values[1] = 0; // discount 76
y2values[2] = Math.floor(y2[2]*0.6); // discount 40% of 77
y2_tail = y2values.reduce((acc, e) => acc + e, 0) / 555558;
y2_tail = Math.floor(y2_tail* 100 * 100) / 100; // 2 significant digits as percent
console.log("Paladin is at the " + y2_tail + "% tail of a normal distribution centered at 77.6");

// ranger: we estimate mean as 79.3 from curve, and work out 50% prob from RHS of that
var y3values = y3.slice();
y3values[0] = 0; // discount 75
y3values[1] = 0; // discount 76
y3values[2] = 0; // discount 77
y3values[3] = Math.floor(y2[2]*0.3); // discount 70% of 78
y3_tail = y3values.reduce((acc, e) => acc + e, 0) / 500054;
y3_tail = Math.floor(y3_tail* 100 * 100) / 100; // 2 significant digits as percent
console.log("Ranger is at the " + y3_tail + "% tail of a normal distribution centered at 79.3");

// fighter.. re-use existing computation since we wouldn't know the mean easily otherwise
// and we've already shown it's very very close.
//- we know we are in 94% tail
//- we know true mean (63)
//- we can estimate true std deviation (from perfect bell curve)
console.log("Fighter is at the 94% tail of a normal distribution centered at 63");

</script>

- $Fighter \sim$ 94th percentile tail of $\mathcal{N}(63, ?)$
- $Paladin \sim$ 77h percentile tail of $\mathcal{N}(77.6, ?)$
- $Ranger \sim$ 71th percentile tail of $\mathcal{N}(79.3, ?)$

<div id="rollhistall" style="width:600px;height:450px;"></div>

<script>

// keys [75, 108]
var x = [...Array(109).keys()].slice(75);

var y1legend = window.FIGHTER_ROLLS.map(x => "occurred once in " + Math.floor(1/x) + " rolls");
var y2legend = window.PALADIN_ROLLS.map(x => "occurred once in " + Math.floor(1/x) + " rolls");
var y3legend = window.RANGER_ROLLS.map(x => "occurred once in " + Math.floor(1/x) + " rolls");

var trace1 = {
  x: x,
  y: window.FIGHTER_ROLLS,
  marker: {
    color: "rgba(255, 100, 102, 0.7)",
    line: {
      color:  "rgba(255, 100, 102, 1)",
    //  width: 1
    }
  },
  name: 'fighter',
  text: y1legend,
  opacity: 0.8,
  type: "scatter",
};
var trace2 = {
  x: x,
  y: window.PALADIN_ROLLS ,
  marker: {
    color: "rgba(100, 200, 102, 0.7)",
    line: {
        color:  "rgba(100, 200, 102, 1)",
        //width: 1
    }
  },
  name: "paladin",
  text: y2legend,
  opacity: 0.75,
  type: "scatter",
};
var trace3 = {
  x: x,
  y: window.RANGER_ROLLS ,
  marker: {
    color: "rgba(100, 100, 200, 0.7)",
    line: {
        color:  "rgba(100, 100, 200, 1)",
        //width: 1
    }
  },
  name: "ranger",
  text: y3legend,
  opacity: 0.75,
  type: "scatter",
};

var data = [trace1, trace2, trace3];
var layout = {
  title: "Roll Results",
  annotations: [
    // {
    //   y: 1/13,
    //   x: 82,
    //   xref: 'x',
    //   yref: 'y',
    //   text: '1σ',
    //   showarrow: true,
    //   arrowhead: 7,
    //   arrowcolor: "green",
    //   ax: 0,
    //   ay: -40
    // },
    // {
    //   y: 1/63,
    //   x: 88,
    //   xref: 'x',
    //   yref: 'y',
    //   text: '2σ',
    //   showarrow: true,
    //   arrowhead: 7,
    //   arrowcolor: "green",
    //   ax: 0,
    //   ay: -40
    // },
    {
      y: 1/675,
      x: 93,
      xref: 'x',
      yref: 'y',
      text: '3σ',
      showarrow: true,
      arrowhead: 7,
      arrowcolor: "green",
      ax: 0,
      ay: -40
    },
    {
      y: 1/23148,
      x: 98,
      xref: 'x',
      yref: 'y',
      text: '4σ',
      showarrow: true,
      arrowhead: 7,
      arrowcolor: "green",
      ax: 0,
      ay: -40
    },
    // {
    //   y: 1/138889,
    //   x: 100,
    //   xref: 'x',
    //   yref: 'y',
    //   text: '4.5σ',
    //   showarrow: true,
    //   arrowhead: 7,
    //   arrowcolor: "green",
    //   ax: 0,
    //   ay: -40
    // },
    // and for mage
    // {
    //   y: 1/9,
    //   x: 78,
    //   xref: 'x',
    //   yref: 'y',
    //   text: '1σ',
    //   showarrow: true,
    //   arrowhead: 7,
    //   arrowcolor: "red",
    //   ax: 0,
    //   ay: -40
    // },
    // {
    //   y: 1/46,
    //   x: 83,
    //   xref: 'x',
    //   yref: 'y',
    //   text: '2σ',
    //   showarrow: true,
    //   arrowhead: 7,
    //   arrowcolor: "red",
    //   ax: 0,
    //   ay: -40
    // },
    {
      y: 1/829,
      x: 89,
      xref: 'x',
      yref: 'y',
      text: '3σ',
      showarrow: true,
      arrowhead: 7,
      arrowcolor: "red",
      ax: 0,
      ay: -40
    },
    {
      y: 1/21367,
      x: 94,
      xref: 'x',
      yref: 'y',
      text: '4σ',
      showarrow: true,
      arrowhead: 7,
      arrowcolor: "red",
      ax: 0,
      ay: -40
    },
    // {
    //   y: 1/27780,
    //   x: 96,
    //   xref: 'x',
    //   yref: 'y',
    //   text: '4.5σ',
    //   showarrow: true,
    //   arrowhead: 7,
    //   arrowcolor: "red",
    //   ax: 0,
    //   ay: -40
    // },
  ],
  xaxis: {title: "Roll"},
  yaxis: {title: "Probability"},
};
HISTOG = document.getElementById('rollhistall');
Plotly.newPlot(HISTOG, data, layout);
</script>

Interestingly, ranger has the highest mean, but paladin has the fattest tail.

## Raw data

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
