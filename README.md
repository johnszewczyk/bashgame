# bashgame
A top-down, randomly-generated tile game written in BASH 5+.

<br>

<h3>Features</h3>
<ul>
  <li>Emoji graphics</li>
  <li>Collision detection</li>
  <li>Scaleable game board size</li>
</ul>

<br>

<h3>Functionality Overview</h3>
<p>A player-controlled cursor is pursued by an AI-controlled enemy across a tile-based gameboard. Players make their way toward the exit tile while taking cover from the enemy on "safe" tiles.</p>
<br>

<h3>Mechanics</h3>
<p>A square map of customisable size is stored as an array. Each index is assigned a tile type by random number generation. Tile outcomes are hard-coded. A general list of tile types:</p>

<ul>
  <li>Stanard passable tile</li>
  <li>Impassible tile</li>
  <li>Safe tile; not passable by enemy</li>
  <li>Exit/ win tile</li>
</ul>

<p>Once the map is generated, a second array is created to use as a framebuffer (the 'pixel' data to draw). Referencing the inital array, which serves as a database, is too slow to utilize as a framebuffer. The second array, which is updated only incrementally, is drawn repeatedly. (More to come.)</p>

<br>

<h3>Future</h3>

<ul>

  <li>
    Method to display only a small area of the map.</li>
  <li>
    Collectable items & power-ups.
  </li>
  <li>
    Multiple enemies
  </li>
</ul>
