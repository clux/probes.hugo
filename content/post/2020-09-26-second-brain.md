---
title: Campaign Brain
subtitle: Exploring alternatives for a second brain for campaign tracking
date: 2020-09-26
tags: ["zettelkasten"]
categories: ["roleplaying"]
---

After 2 years of running a D&D campaign, my last note taking setup has reached serious problems. If you're using OneNote or another online managed system for tracking notes/cities/npcs/pcs/events, but know how to use programmers tools like `git` and `code`; boy are there a world of advantages available to you.

This is a story of my original note talking setup, a comparison between newer technologies, and how I am back to writing markdown in a folder.

<!--more-->

## The OneNote Setup
Early in 2018, we were starting to play weekly, and my various documents in google docs were not cutting it.

I watched a couple of videos detailing how to [Manage a D&D campaign with OneNote](https://www.youtube.com/watch?v=SqhePj9ratI). The double categorisation setup where Sections contain many Pages was nice, the promise of links was promising, but unfortunately, the [difficulty of creating them](https://youtu.be/SqhePj9ratI?t=1856) made them too slow to really be viable.

A year down the line, my OneNote looked like this:

![one note campaign](/imgs/foam/onenote-campaign.png)

Still, image integration straight from a google search and into your document was great. Well, not google, but bing, I guess. In practice, I wasn't always sure what I was going for, so I often ended up searching for images in my browser first via google, getting shunted to pinterest and find something promising there. Since OneNote returned completely different images, I generally had to save and upload my findings anyway.

OneNote did let you place random text fields anywhere on your page (like it was some kind of janky e-scrap book), and this did actually help get around the actual problem I was having; **splitting the data is hard in a browser**.

Why? You click on a link, the browser makes several HTTP requests, and after waiting 400ms you finally get to see the results (one drive is not super responsive), but this movement drops your place to the current page you needed to cross reference with. So now you either go back, and shift-click the reference so you now have two tabs that you can Shift-Tab between, or you prepare those tabs up in advance (typically before the session).

In practice I often ended up with a 20 tab browser window for every session, which generally, looked something like:

- 5 from OneNote (campaign brain)
- 2 from Kobold Fight Club (potential encounters)
- 6 from monsters / items
- 2 youtube ambient music tabs
- 5 from lore/wikis related to the story or NPCs

and the squished icon/tab name meant you kind of had to tab between them a lot to figure out which one you wanted, and then eventually break the tab order when players did something out of left field (DMs; have this ever happened to you?).

So there were definitely some problems with this. That said, it was free, it __generally__ was responsive, and (when the WIFI was perfectly reliable) the 400ms link opening time wasn't too much of a drain on the improv. However, it was definitely noticable, and it just took a few times where OneNote's **QoS** dropped, or my WIFI signals started getting a little dodgy (from one of the more farady cagey meeting rooms we occassionally played in), for it all to feel pointless. Then there was a whole week where I was unable to save anything with no errors shown to me. I didn't even get to the bottom of it, I just knew this could not continue.

## The Git Repository
After these problems, I realised that there's one thing I'm unwilling to compromise on:

> My notes must be available offline

If that means I have to do a full sync up front; fine. A folder of documents behind `git` solves this. Incidentally, it also solves the merge conflict resolution problem that OneNote was giving me due to the way it hid its sync successes/failures. Imagine arriving back at your desktop computer only to find that your laptop didn't sync, so you either have to bring your laptop back up, or solve a merge conflict (with yourself..) the next time you open your laptop (on an interface worse than git's no less). Super annoying. Now just `git commit` and `git push`, and if you play your cards right you never get a merge conflict.

That means that no matter how slick the following solutions look:

- World Anvil
- Notion
- Roam

These solutions are off the table for me. Even if some of them might be a reasonable abstraction.

With an offline document repo, it was immediately easy to get back the basic functionality needed; categorised text in sections (folders) and pages (markdown files within folder), and an offline way to access them (git repo).

## The Markdown
Using [Markdown](https://guides.github.com/features/mastering-markdown/) as the documention format is a no-brainer to me as a software engineer. Codified styling in a generic editor is so much more useful than a WYSIWYG tool like Word when you got the practice. But many of the same problems I had with OneNote still manifested themselves, albeit in slightly different ways:

- linking markdown files requires lookup and hard-coding of filesystem paths
- tendency to store everything in one file because linking is annoying
- guessing what tabs are needed in your editor before the session
- embedding images is a bit of a pain

Now, none of these in theory were unsolvable. But was this something where homegrowing my own content management markdown system was really a smart way forward? After all, surely people writing books needs some kind of linked system to keep track of everything right?

## Zettelkasten
There are probably millions of ways to organise your stuff and still be successful, just take a look at some famous writers' desks:

{{< tweet 1308030597688971265 >}}

However, this [article on sociologist Niklas Luhmann and his Zettelkasten system](
https://writingcooperative.com/zettelkasten-how-one-german-scholar-was-so-freakishly-productive-997e4e0ca125) did highlight some very important data modelling problems on note taking:

- categorising notes by folders is flawed
- categorising notes by tags is flawed
- categorising notes by links is flawed

You really need all three, and if you can achieve this with a simple slip box system of index cards, then there must be ways to do this with an editor you know without delving into [orgmode](https://orgmode.org/) land and having to re-learn something equivalent to markdown.

The principles listed in this article is also interesting. Particularly 3:

> 3. Always link your notes
> Whenever you add a note, make sure to link it to already existing notes. Avoid notes that are disconnected from other notes. As Luhmann himself put it, "each note is just an element that derives its quality from the network of links in the system. A note that is not connected to the network will be lost, will be forgotten by the Zettelkasten"

The same can be said about D&D campaigns. An NPC already linked to a player can be a lot easier, and more sensible to quickly re-instate, than to copy or slightly tweak [one of your 10 existing characters](https://old.reddit.com/r/dndmemes/comments/iuajhd/im_basically_a_voice_actor/) - at least if they are popular/good. Plus, it will help the players remember them better. A campaign quickly accumulates a lot of information. No need to make this harder than it already is.

## Obsidian
The article by [joshwin](joshwin.imprint.to) on how he [uses obsidian to manage goals, tasks, notes, and more](https://joshwin.imprint.to/post/how-i-use-obsidian-to-manage-my-goals-tasks-notes-and-software-development-knowledge-base) is compelling. One install of some custom software and you have a system set up already, and it's flexible enough to let you handle all these different things. It might be worth [looking into](https://obsidian.md/) if you don't exactly know your need. Their [feature list](https://obsidian.md/features) is at the very least interesting.

Personally, though, there are **reasons why I'm not going for this**:

### Custom Editor
While it looks like you __can__ customize this scope-limited editor close to what you fancy, it does mean that, you, as a software engineer, will need to do that yet another time in your career. Having battled with Vim/Sublime/VSCode and various editors over the course of my life, there's a point where I have started feeling __satisfied__ with what [past-clux has already configured](https://github.com/clux/dotfiles).

### Custom Install
The only provided [linux install](https://obsidian.md/) a single [snap package](https://snapcraft.io/). While snap **might become** a successful and perhaps the most prominent packaging distribution system on linux, it's nowhere near that point yet; especially on [Arch](https://www.archlinux.org/). There's no need for me to introduce an [extra daemon](https://wiki.archlinux.org/index.php/Snap) to auto-upgrade packages when there's already [a solid system](https://wiki.archlinux.org/index.php/pacman) on Arch that lets me do this.

### Custom Formats
Obsidian comes bundled in a prepackaged electron app downloadable from their site. What version of electron? [9 atm, AFAIKT](https://github.com/NixOS/nixpkgs/issues/89089), but presumably this will not be kept up to date if development stops.

Sure, they say you can keep your data because you technically own it; i.e. you can store it wherever, but if they control the system that defines the format then it would be super annoying to have to do a migration to something else.

### Vendor locked plugins
One way out of this would be to have custom plugins, but their plugin API is not exposed (though on their [roadmap](https://trello.com/c/Z7qqKVXd/19-public-plugin-api-v10)).

Ultimately, even if this eventually did get solved, I'd still rather go with a plugin system in a code editor I already know how to use, and backup, than to get locked in to something forked off electron where the development may stop at any time.

So my preferred options would really be for Sublime and VSCode. Both very popular code editors. So what's out there?

## Sublime ZK
There are [zettelkasten plugins for sublime](https://github.com/renerocksai/sublime_zk), but they looks pretty abandoned at the moment. It also does not seem to let you build a graph of your links (one of the main selling points of Obsidian).

## Foam
We close with [foam](https://foambubble.github.io/foam/), the system we ended up using. Inspired by Roam (a system I neglected to talk about because of sync/offline problems, and it's also not cheap).

The selling point here, is really that `Foam` is really just a collection of [VS Code](https://github.com/microsoft/vscode) extensions, that you can [default-recommend](https://code.visualstudio.com/docs/editor/extension-gallery#_recommended-extensions) at the [repo level](https://github.com/foambubble/foam-template/blob/master/.vscode/extensions.json).

The main ones here are:

- [foam.foam-vscode](https://marketplace.visualstudio.com/items?itemName=foam.foam-vscode) - Foam's own extension
- [tchayen.markdown-links](https://marketplace.visualstudio.com/items?itemName=tchayen.markdown-links) - Adds `show graph` command that displays graph of linked notes
- [yzhang.markdown-all-in-one](https://marketplace.visualstudio.com/items?itemName=yzhang.markdown-all-in-one) - Tons of markdown goodies (lists, tables of content, so much more)
- [kortina.vscode-markdown-notes](https://marketplace.visualstudio.com/items?itemName=kortina.vscode-markdown-notes) - `[[wiki-links]]`, backlinking etc
- [esbenp.prettier-vscode](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode) - Prettier for auto formatting code
- [eamodio.gitlens](https://marketplace.visualstudio.com/items?itemName=eamodio.gitlens) - GitLens for seeing version history inline

All of which are very popular, standard programming extensions, with the sole exception of the `foam`; a [smaller looking](https://github.com/foambubble/foam/tree/master/packages/foam-vscode) extension that helps manage the wiki links. Frankly, it's somewhat strange to me that they list the off-putting "tolerance for alpha software" as a requirement when most of their logic resides outside their codebase.

If you've dealt with a code editors plugin ecosystem before, this is a lot more welcoming than obsidian to me. Bug in the system? Well, probably one of the extensions. You've got options for dealing with it: report & wait, fork + fix, try other replacement extensions.

Oh, and I can we can out the [default provided dark theme](https://marketplace.visualstudio.com/items?itemName=philipbe.theme-gray-matter) for one you like (mine is [Seti](https://marketplace.visualstudio.com/items?itemName=tnaseem.theme-seti))

And if you need extra functionality for special needs, you now have the whole [wealth of the vs code ecosystem available](https://marketplace.visualstudio.com/).

So far, these have been useful addons for providing extra functionality:

- [mushan.vscode-paste-image](https://marketplace.visualstudio.com/items?itemName=mushan.vscode-paste-image) - paste image from clipboard functionality

## Result
So that was a lot of information about comparison of note taking technology. How does my system actually end up looking? Depends on whether I am editing or running a game. Here is a 3-way split between editing and showing the graph update live.

![foam 3-way split](/imgs/foam/3-split-irae.png)

The [graphs sometimes overlaps](https://github.com/tchayen/markdown-links/issues/58) and [rebalances awkwardly](https://github.com/tchayen/markdown-links/issues/64) ([help seems to be requested](https://github.com/foambubble/call-for-visualization)), but the naive implementation still help out a whole lot.

Most of the time, I am editing with markdown on the left, preview on the right, or markdown on the left plus graph on the right, or just 100% markdown in a single view, depending on what type of work needs focus. The flexibility of this system is equivalent to that of a popular professional code editor by inheritance.

Even if some of these plugins don't evolve much, I see this as a pretty future proof setup (the [why foam issue](https://github.com/foambubble/foam/issues/88) is also refreshingly honest). The investment in new tech is small, and migration cost away from said tech is also minimal.

From a RPG perspective, the need to pre-empt players with pre-prepared tabs is now a little less problematic as we can quickly browse to the resource either with the standard editor fuzzy file search, or by following links. We also have complete full text search locally with [ripgrep](https://github.com/BurntSushi/ripgrep).

The hope with all this is that the amount of hard-to-navigate "running the game tabs" should be significantly reduced with this setup, and my world should feel more integrated thanks to the extensive Zettelkasten style linking. Well. Fingers crossed anyway.
