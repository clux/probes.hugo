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
    <p>Rust, open source, cloud tech, kubernetes</p>
  </a>
  <a href="/categories/roleplaying/">
    <h3>roleplaying</h3>
    <p>dungeon mastering, universe, ideas, homebrew</p>
  </a>
  <a href="/categories/gaming/">
    <h3>gaming</h3>
    <p>solutions, theorycrafting, minmaxing, speedrunning</p>
  </a>
  <a href="/categories/music/">
    <h3>music</h3>
    <p>classical, piano, violin</p>
  </a>
  <a class="blah">
    <h3>life</h3>
    <p>tab accidentally left blank</p>
  </a>
  <a href="/categories/misc/">
    <h3>misc</h3>
    <p>photography, harware, cooking, offtopic</p>
  </a>
</section>
