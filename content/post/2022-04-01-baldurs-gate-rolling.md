---
title: "Baldur's Gate: Multinomial Edition"
subtitle: Auto-rolling and getting nerd sniped before venturing forth
date: 2022-04-01
tags: []
categories: ["gaming"]
---

In a ~~brief~~ bout of escapism from the world and responsibilities, I booted up [Baldur's Gate 2](https://store.steampowered.com/app/257350/Baldurs_Gate_II_Enhanced_Edition/) with my brother. It's an amazing game, once you have figured out how to **[roll](https://old.reddit.com/r/baldursgate/search?q=roll&restrict_sr=on)** your character. Rather than telling you about the game, let's talk about and simulate the maths behind rolling a `2e` character.

TODO: gif of roll clicking...
TODO: maybe just a reroll button that links to the article?

<!--more-->
<script src="https://cdn.plot.ly/plotly-2.9.0.min.js"></script>

## Rolling a character

Basics; D&D (2e) has:

- `6` ability scores
- each ability == sum of rolling `3d6`

This should give you a character with an expected "10.5" points per ability (or a sum of `63` in total), but that's **not** how it works.

TODO: gif/video of how it looks

It's a pretty dumb design idea to port the rolling mechanics from `d&d` into the game. In a normal campaign you'd get one chance rolling, but here, there's no downside to keeping going, encouraging excessive time investment (the irony in writing this blog post is not lost on me). They should have just gone for something like [5e point buy](https://chicken-dinner.com/5e/5e-point-buy.html).

## Disclaimer

Using the script used herein to achieve higher rolls than you have patience for, is on some level; **cheating**. That said; is a fairly pointless effort:

- this is a single player game, you can reduce the difficulty
- having [dump stats](https://tvtropes.org/pmwiki/pmwiki.php/Main/DumpStat) is not heavily penalized in the game
- early items nullify effects of common dump stats ([19 STR girdle](https://baldursgate.fandom.com/wiki/Girdle_of_Hill_Giant_Strength) or [18 CHA ring](https://baldursgate.fandom.com/wiki/Ring_of_Human_Influence))
- you can get [max stats in 20 minutes](https://www.youtube.com/watch?v=5dDmh98lmkA) with by abusing inventory [bugs](https://baldursgate.fandom.com/wiki/Exploits#Potion_Swap_Glitch)
- some [NPCS](https://baldursgate.fandom.com/wiki/Edwin_Odesseiron) come with [gear](https://baldursgate.fandom.com/wiki/Edwin%27s_Amulet) that blows marginally better stats out of the water


## Multinomials and probabilities

> How many rolls would you need to get 90/95/100?

Rolling a 6 sided dice 18 times follows the [multinomial distribution](https://en.wikipedia.org/wiki/Multinomial_distribution) ($k=6$, and $p_i = 1/6$ for all $i$), and the expected value of 18 dice rolls would be $18*(7/2) = 63$. The distribution should also [approximate a normal distribution very closely](https://mathworld.wolfram.com/Dice.html) for this amount of dice.

Let's stick with the precise calculation for now because we are mostly concerned with the tail end where the detail matters. (`n=18` and `s=6`)

$$P(p, 18, 6) = \frac{1}{6^{18}} \sum_{k=0}^{\lfloor(p-18)/6\rfloor} (-1)^k \binom{18}{k} \binom{p-6k-1}{17}$$
$$ = \sum_{k=0}^{k_{max}} (-1)^k \frac{18}{k!(18-k)!} \frac{(p-6k-1)!}{(p-6k-18)!}$$

which.. when cased for $k_{max}$ (follow argument in [mathworld/Dice](https://mathworld.wolfram.com/Dice.html)) would yield 15 different sum expressions, and the ones we care about would all have 10+ expressions. So rather than trying to make this nice (hint, it's not going to eve look nice), we will [paste this into wolfram alpha](https://www.wolframalpha.com/input?i2d=true&i=+Divide%5B1%2CPower%5B6%2C18%5D%5DSum%5BPower%5B%5C%2840%29-1%5C%2841%29%2Ck%5D+*binomial%5C%2840%2918%5C%2844%29+k%5C%2841%29*binomial%5C%2840%2991-6k-1%5C%2844%29+17%5C%2841%29%2C%7Bk%2C0%2Cfloor%5C%2840%29Divide%5B%5C%2840%2991-18%5C%2841%29%2C6%5D%5C%2841%29%7D%5D) and tabulate values for $[18, \ldots, 108]$.

tabulated values:

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

Which yields the following distribution:

<div id="probhist" style="width:600px;height:450px;"></div>

<script>

// keys [18, 108]
var x = [...Array(109).keys()].slice(18);

// probabilities for p=18 up to p=108
var probs = [1/101559956668416, 1/5642219814912, 19/11284439629824, 95/8463329722368, 665/11284439629824, 1463/5642219814912, 33643/33853318889472, 9605/2821109907456, 119833/11284439629824, 1552015/50779978334208, 308465/3761479876608, 97223/470184984576, 2782169/5642219814912, 1051229/940369969152, 4550747/1880739938304, 786505/156728328192, 37624655/3761479876608, 36131483/1880739938304, 1206294965/33853318889472, 20045551/313456656384, 139474379/1253826625536, 1059736685/5642219814912, 128825225/417942208512, 17143871/34828517376, 8640663457/11284439629824, 728073331/626913312768, 2155134523/1253826625536, 3942228889/1586874322944, 4949217565/1410554953728, 3417441745/705277476864, 27703245169/4231664861184, 3052981465/352638738432, 126513483013/11284439629824, 240741263447/16926659444736, 199524184055/11284439629824, 60788736553/2821109907456, 2615090074301/101559956668416, 56759069113/1880739938304, 130521904423/3761479876608, 110438453753/2821109907456, 163027882055/3761479876608, 88576807769/1880739938304, 566880747559/11284439629824, 24732579319/470184984576, 101698030955/1880739938304, 461867856157/8463329722368, 101698030955/1880739938304, 24732579319/470184984576, 566880747559/11284439629824, 88576807769/1880739938304, 163027882055/3761479876608, 110438453753/2821109907456, 130521904423/3761479876608, 56759069113/1880739938304, 2615090074301/101559956668416, 60788736553/2821109907456, 199524184055/11284439629824, 240741263447/16926659444736, 126513483013/11284439629824, 3052981465/352638738432, 27703245169/4231664861184, 3417441745/705277476864, 4949217565/1410554953728, 3942228889/1586874322944, 2155134523/1253826625536, 728073331/626913312768, 8640663457/11284439629824, 17143871/34828517376, 128825225/417942208512, 1059736685/5642219814912, 139474379/1253826625536, 20045551/313456656384, 1206294965/33853318889472, 36131483/1880739938304, 37624655/3761479876608, 786505/156728328192, 4550747/1880739938304, 1051229/940369969152, 2782169/5642219814912, 97223/470184984576, 308465/3761479876608, 1552015/50779978334208, 119833/11284439629824, 9605/2821109907456, 33643/33853318889472, 1463/5642219814912, 665/11284439629824, 95/8463329722368, 19/11284439629824, 1/5642219814912, 1/101559956668416];

// TODO: do a regular plus a cumulative one


var legend = probs.map(x => "expected once in " + Math.floor(1/x) + " rolls")

var trace = {
  x: x,
  y: probs,
  marker: {
    color: "rgba(255, 100, 102, 0.7)",
    line: {
      color:  "rgba(255, 100, 102, 1)",
    }
  },
  name: 'probability',
  text: legend,
  opacity: 0.8,
  type: "scatter",
};


var data = [trace];
var layout = {
  title: "Precise Distribution",
  // TODO: annotation on cutoff
  xaxis: {title: "Roll"},
  yaxis: {title: "Probability"},
};
PROBHIST = document.getElementById('probhist');
Plotly.newPlot(PROBHIST, data, layout);
// TODO: figure out probability sum less than 75
// scale by this and see how it lines up
</script>


This is how things should look on paper with vanilla rules. However, is that's what is going on?

> Wait, you rolled a 94 on a mage after a few hundred rolls.. was that just luck, or are higher numbers more likely than this?


thankfully, last two matches my calculations... 63 with > 5.4% chance of occurring
this is a strong indication that the probabilities are right, but need to be adjusted for filtering out everything <75 since they are lower than what we are seeing

how much chance of 18 <= p <= 74 ?

getting a number in the thirties or lower would have been as likely than getting >= 87 if it wasnt for flooring. 36 is as likely as 90..


This is hard to see in the above graph, because it doesn't account for extraneous limits:

- minimum sum of `75`
- [stat floors based on races/class](https://rpg.stackexchange.com/questions/165377/how-do-baldurs-gate-and-baldurs-gate-2s-rolling-for-stats-actually-get-gene)

For some classes, these stat floors actually push their mean above the `75` cutoff even though it's 12 points above the mean of the underlying distribution:

- **fighter** `STR=9`, rest `>=3`
- **mage** `INT=9`, rest `>=3`
- **paladin** `CHA=17`, `WIS=13`, `STR=12`, `CON=9`, rest `>=3`

How the __flooring__ is performed would also matter to our distribution. I.e. does the engine:

- roll `3d6 x 6` until it gets a sum `>=75`?
- roll `3d6 x 6` but add bias as we go along to ensure number `>=75`?

and similarly:

- does it roll each stat, and return `floor(roll, statmin)`?
- generate a random number in the range rather than roll 3 dice?
- something different?

Short of reverse engineering, it's hard to nail down the distribution exactly. However, from the graph, the frequency of extremely high rolls do seem to align, indicating that the rolls that would have exceeded the floors, follow standard multinomial data.

If my combinatorics is correct we should see a distribution falloff like this:

- `108` is a once in `101 trillion` event (`6^18`)
- `107` is a once in `5 trillion` event (`6^18/18`)
- `106` is a once in `300 billion` event (5s in two places + 4 in one place)
- `105` is a once in `19 billion` event (3x5s + 1x4 and 1x5 + 1x3)
- `104` is a once in `1 billion` event (4x5s, 2x5s and 1x4, 2x4s, 1x5 and 1x3, 1x2)
- `103` is a once in `91 million` event (5x5s, 3x5s and 1x4, 2x5s and 1x3, 1x5 and 1x2, 2x4 and 1x5, 1x3 and 1x4, 1x1)
- `102` is a once in `7 million` event (need at least two dice to remove 6, six routes for 2 dice 1/5+2/4+3/3, 3 routes for 3 dice 4/4/4+4/3/5+5/5/2, 2 routes for 4 dice 5/5/5/3+5/5/4/4, 1 route for 5 dice 5/5/5/5/4, 1 route for 6 dice 5/5/5/5/5 so `total ways 18*17*6 + 18*17*16*3 + 18*17*16*15*2 + 18*17*16*15*14 + 18*17*16*15*14*13`)

..but that's clearly too high for a paladin. People have gotten 103s. I have gotten a 103, and regularly get 102s in a few hours. If my math above is correct, there should be `14 million` ways to roll a `102` compared to just `324` ways to roll a `106`.


## Distribution

We rolled a human `fighter` and `paladin` overnight with roughly `550k` rolls each (view source for details).



...if we wanted the perfect paladin we would __just__ need 15 dice to be perfect to roll a `107` or a `108` (charisma is free for that), then we still would need to a `6^-15` chance roll - one in 500 billion), a 7 sigma event.

Given `900 rolls per minute` with this script, that would be **1000 years of rolling**.

If we rolled for a day, on the other hand (`1.3M` rolls), we are likely get a [5 sigma event](https://en.wikipedia.org/wiki/68%E2%80%9395%E2%80%9399.7_rule#Table_of_numerical_values) and a roll a `103` with paladin or `99` with fighter.

<div id="rollhist" style="width:600px;height:450px;"></div>

<script>

// keys [75, 108]
var x = [...Array(109).keys()].slice(75);

// values fighter (75 -> 98)
var y1 = [137379, 109198, 85620, 65004, 48256, 35041, 24987, 17545, 11981, 7883, 5007, 3139, 1946, 1138, 670, 368, 199, 103, 49, 26, 12, 6, 2, 1].map(x => x / 555560);

// values paladin (75 -> 102)
var y2 = [50888, 54911, 57338, 57442, 55589, 52357, 47503, 41339, 34458, 28599, 21997, 16722, 12322, 8697, 5997, 3774, 2371, 1489, 822, 465, 251, 129, 56, 24, 12, 4, 1, 1].map(x => x / 555558); // divide by number of rolls


var y1legend = y1.map(x => "occurred once in " + Math.floor(1/x) + " rolls")
var y2legend = y2.map(x => "occurred once in " + Math.floor(1/x) + " rolls")

var trace1 = {
  x: x,
  y: y1,
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
  y: y2,
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

var data = [trace1, trace2];
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
HISTOG = document.getElementById('rollhist');
Plotly.newPlot(HISTOG, data, layout);
</script>

Estimated sigma numbers from distribution seen from 550k rolls on either class. For the rest we need math.

## Tools

We are playing on Linux with an `X` based window manager, so we will use a couple of standard tools:

- `scrot` - X screenshot utility
- `xdotool` - X CLI automation tool
- `xwininfo` - X window information utility

Basic strategy;

- find out where buttons are with `xwininfo`
- press the `re-roll` button with `xdotool`
- take screenshot of the `total` number with `scrot`
- compare screenshot to previous rolls
- press `store` when a new maximum is found

## Initialization

My brother decided to write a completely overkill for this, taking progressive screenshots and compensating for the window manager bar height, and relying on BG2EE's consistent layout to hardcode some offsets. Not going through this, it is insanity. It also means it probably works for everyone. Well, everyone on Linux with X..

The standardised approach also helps with dealing with rolls, and populating a roll-table.

## Roll Tables

Taking screenshots is pretty easy:

```sh
scrot -a "${STR_TOP_LEFT_X},${STR_TOP_LEFT_Y},49,17"
```

which you can pipe to a `.png` and pass to `compare` (part of `imagemagick` package), to compare values based on thresholds (which was the initial idea).

Turns out, doing this is overkill. The background is static, nothing moves, the screenshots are deterministic per value and you can instead just compare them by their hashes (i.e. pipe to `md5`).

TODO: link to roll table

## Clicking

Clicking is pretty easy;

```sh
xdotool mousemove "$REROLL_BTN_X" "$REROLL_BTN_Y" click --delay=0 1
```

Notice the `--delay=0` to override the builtin delay between clicks.

It turns out BG performs internal buffering of clicks, so this allows you to blast through numbers faster than the screen can display them.

This means we have to compensate with a `sleep 0.001` after clicking to ensure we can grab the `scrot` of the roll.

## Showcase

TODO: video

On my PC we get about 15 rolls per second.


## Raw data

10 hour paladin roll (`555558` rolls in 601m)

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



10 hour fighter roll (`555560` rolls in 608m)

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
