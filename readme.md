This is a rewrite of the backend of my [London commutes vs rent visualizer](https://github.com/andyljones/commutes-and-rent-preprocessor).
The last version was one of my first programming projects, and so ended up being buggy and unwieldy. This version
uses the TfL API for commute data and the Zoopla API for rental information, leading to it being a lot more accurate.

Right now it's just a collection of scripts; it hasn't been tied together into a single application yet. There are also no comments, and one of the scripts is written in Python rather than Lua.

Summary:
 - `commute_scraper.lua` fetches journey times between pairs of stations on the same line from the TfL API
 - `commute_calculator.lua` uses that data to calculate journey times between all pairs of stations
 - `coord_scraper.lua` uses the TfL API to get geographic coordinates for each station
 - `rent_scraper.py` fetches property information from the Zoopla API for each set of station coordinates
 - `commutes_and_rents.lua` synthesizes the commute and rent data into some useful statistics
