---
title: Posts
type: "page"
showthedate: false
comments: false
---

<style>
  .intro {
    display: flex;
    flex-wrap: wrap;
    justify-content: space-between;
  }
  .intro > a {
    text-align: center;
    justify-content: center;
    align-items: center;
    flex-grow: 0;
    flex-shrink: 0;
    flex-basis: 33.33%;
    /*border: 1px solid #ccc;*/
    width: 30%
  }
  .intro > a:hover {
    background: #114;
    color: #ddd;
    text-decoration: none;
  }
  .intro > a.blah:hover {
    background: #ff69b4;
    color: #000;
  }
  </style>

  <section class="intro">
    <a href="/categories/software/">
      <h3>software</h3>
      <p>rust, open source, cloud, kubernetes</p>
    </a>
    <a href="/categories/roleplaying/">
      <h3>roleplaying</h3>
      <p>dungeon mastering, universe, ideas, homebrew</p>
    </a>
    <a href="/categories/gaming/">
      <h3>gaming</h3>
      <p>theorycrafting, minmaxing, speedrunning</p>
    </a>
    <a href="/categories/music/">
      <h3>music</h3>
      <p>classical, piano, violin</p>
    </a>
    <a class="blah">
      <h3>hopes and dreams</h3>
      <p>tab left blank</p>
    </a>
    <a href="/categories/life">
      <h3>life</h3>
      <p>experiments, thoughts, running</p>
    </a>
  </section>
