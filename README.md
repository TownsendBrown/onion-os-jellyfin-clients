# Onion OS Jellyfin Client

# Description
This program uses the ffplay port already on Onion OS to stream video content from a Jellyfin server. This program is currently set up to use an API Key and specifically find movie type content on the server.

# Installation
* Update the SERVER_URL and API_KEY lines in the jellyfin_config.txt file inside the app folders.
* Place jellyfin client folder(s) into the App folder located in the root of the SD card.

# Usage
* Refresh Movie / Show List: Refreshes list of movies or shows.
* Browse: Go to list of seasons, then episodes, or browse list of movies
* Menu / Center Button: Open app main menu / exit content.

# Quirks
* Only forward skip: Due to the limitations of the specific version of ffplay, only forward skip is available.

# Known Issues
* Some instability with playback
* Crashing when selecting new content, particularly when reselecting after initially starting the app.
