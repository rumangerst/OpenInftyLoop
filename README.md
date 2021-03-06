OpenInftyLoop is a small puzzle game I ported to PC (Windows/Mac/Linux)  from games that are unfortunately
exclusive to mobile platforms.
Just install the program, start it to play.

The goal of each level is to complete the curves on the map by clicking on them.

[OpenInftyLoop on GitHub](https://github.com/rumangerst/OpenInftyLoop) [OpenInftyLoop on itch.io](https://mrnotsoevil.itch.io/openinftyloop)

# Download

You can download the game directly from [GitHub](https://github.com/rumangerst/OpenInftyLoop/releases) or
from [itch.io](https://mrnotsoevil.itch.io/openinftyloop)

# Features

* Multiple independent modes such as a campaign or specific field sizes
* Saves yet-to-complete puzzles automatically
* OpenSource: If you want, you can review the game for your own projects or build upon it

# Credits

This game uses the [Godot Engine](http://godotengine.org/) version 3.
This game uses sound effects created by *Lokif* obtained from https://opengameart.org/content/gui-sound-effects
and the "Xylophone A" effect created by *DANMITCH3LL* obtained from https://freesound.org/people/DANMITCH3LL/sounds/232004/.
The background music is [Garden Music by Kevin MacLeod](https://incompetech.com/wordpress/2015/12/garden-music/).

# Building and deploying

The `deploy.sh` script is used to deploy OpenInftyLoop for all supported platforms.
Please note that you need to install the Godot export templates first before using this script.
The packages will be placed in the `deploy-bin` folder.

Deploying requires:

* Installed Godot 3 export templates
* WINE
* [Inno Setup](http://www.jrsoftware.org/isinfo.php) installed in default WINEPREFIX (or change the WINEPREFIX in the deployment script)

The deployment script will automatically fetch Godot 3 x64 and place it into the `bin` directory.

# Screenshots

![Screenshot](https://raw.githubusercontent.com/rumangerst/OpenInftyLoop/master/docs/assets/img/screenshot1.png)
![Screenshot](https://raw.githubusercontent.com/rumangerst/OpenInftyLoop/master/docs/assets/img/screenshot2.png)
![Screenshot](https://raw.githubusercontent.com/rumangerst/OpenInftyLoop/master/docs/assets/img/screenshot3.png)
