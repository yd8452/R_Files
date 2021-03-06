# Flowing Data Tutorials and some Virginia Accident Mapping

setwd("/Users/stuart/DataSets/FlowingData/")
library(maptools)   # To plot maps
library(maps)       # To draw maps
library(foreign)    # To read .dbf file
library(dplyr)      # Data formatting
library(rgdal)      # Map Projections
library(proj4)      # Map Projections
library(plyr)
library(choroplethr)
library(choroplethrMaps)

# RTTYP designations:
# C = County
# I = Interstate
# M = Common Name
# O = Other
# S = State recognized
# U = U.S.

# MTFCC designations:
#  S1100   Primary Road
#  R1011   Railroad Feature (Main, Spur, or Yard)
#  R1051   Carline, Streetcar Track, Monorail, Other Mass Transit Rail)
#  R1052   Cog Rail Line, Incline Rail Line, Tram
#  S1100   Primary Road
#  S1200   Secondary Road  

##### Lesson 1. Getting Started with ShapeFiles #########################################
priroads <- readShapeLines("tl_2014_us_primaryroads/tl_2014_us_primaryroads.shp")
png("primary-roads.png", width=960, height=700)
par(mar=c(0,0,0,0))
plot(0, 0, type="n", axes=FALSE, xlim=c(-125.97,-66.32), ylim=c(24.39, 49.7), xlab=NA, ylab=NA)
lines(priroads)
dev.off()

# Virginia Roads -- State
varoads <- readShapeLines("tl_2014_51_prisecroads/tl_2014_51_prisecroads.shp")
vausroads <- subset(varoads, RTTYP == "U")
vacountyroads <- subset(varoads, RTTYP == "C")
vainterstateroads <- subset(varoads, RTTYP == "I")
vaotherroads <- subset(varoads, RTTYP != "U" | RTTYP != "C" | RTTYP != "I")

par(mfrow=c(1,1), mar=c(0.2,0.2,0.2,0.2))
plot(0, 0, type="n", axes=FALSE, xlim=varoads@bbox["x",], ylim=varoads@bbox["y",], xlab=NA, ylab=NA)
lines(vausroads, col="red", lwd=2)
lines(vacountyroads, col="purple", lwd=2)
lines(vainterstateroads, col="blue", lwd=2)
lines(vaotherroads, col="black", lwd=0.3)


# Virginia Roads -- Fairfax County
# File Name: tl_2014_[state-county FIPS]_roads.shp
fairfaxroads <- readShapeLines("tl_2014_51059_roads/tl_2014_51059_roads.shp")
usroads <- subset(fairfaxroads, RTTYP == "U")
countyroads <- subset(fairfaxroads, RTTYP == "C")
interstateroads <- subset(fairfaxroads, RTTYP == "I")
otherroads <- subset(fairfaxroads, RTTYP != "U" | RTTYP != "C" | RTTYP != "I")
names(countyroads)  # See what other fields are available


# Plot Virginia Roads -- Fairfax County
# Note: if you leave off first and last lines, get local R Plot
png("fairfax_county-roads-color-3.png", width=960, height=700, bg="#f0f0f0")
par(mar=c(0.2,0.2,0.2,0.2))
plot(0, 0, type="n", axes=FALSE, xlim=countyroads@bbox["x",], ylim=countyroads@bbox["y",], xlab=NA, ylab=NA)
lines(usroads, col="red", lwd=2)
lines(countyroads, col="purple", lwd=2)
lines(interstateroads, col="blue", lwd=2)
lines(otherroads, col="black", lwd=0.3)
dev.off()

##### Lesson 2. Getting Started with Map Projections ########################################
# Primary roads from previous tutorial (data from TIGER)
priroads <- readShapeLines("tl_2014_us_primaryroads/tl_2014_us_primaryroads.shp")
# Everything is the same as before so far. Now starting the projection stuff, which actually isn't that much. Specify the PROJ.4 string for the current shapefile. It's unprojected and contains latitude and longitude coordinates. This is specified with "+proj=longlat" using PROJ.4.

proj4string(priroads) <- CRS("+proj=longlat")

#You have to do this so that R knows what to convert from. We're dealing with national US data, so we'll go with the Albers equal area projection, as is the standard these days.

# Set projection and transform
albers <- "+proj=aea +lat_1=29.5 +lat_2=45.5 +lon_0=97.2w"
priroads_albers <- spTransform(priroads, CRS(albers))
# Draw projected lines
png("priroads-albers.png", width=960, height=600)
par(mar=c(0,0,0,0), bg="#f0f0f0")
plot(0, 0, xlim=c(-1000000, 1000000), ylim=c(2356848, 5500627), asp=1, type="n")
lines(priroads_albers, lwd=0.1)
dev.off()

# Although the plot limits are different because the coordinates are projected. This took some trial and error on my part. I looked at the bounding box (enter priroads_albers@bbox to see for yourself) and adjusted from there.
priroads_albers@bbox

# Try a Map Projection of Virginia Roads
proj4string(varoads) <- CRS("+proj=longlat")
albers <- "+proj=aea +lat_1=36.5 +lat_2=39.1 +lon_0=78.7w"
varoads_albers <- spTransform(varoads, CRS(albers))

par(mar=c(0,0,0,0), bg="#f0f0f0")
plot(0, 0, xlim=c(-400000, 300000), ylim=c(3823804.8, 4145766.0), asp=1, type="n")
lines(varoads_albers, lwd=0.1)

###### Lesson 3: Small Maps and Grids #########################################################
# Load the data. You'll be looking at fatal automobile accidents in the United States in 2001.
# Note: library(foreign) allows us to read .dbf files and put in dataframe format
# Note: If working in the U.S. maps() handles projections etc., with less 'pain'

acc <- read.dbf("accident2001.dbf")
acc2013 <- read.dbf("accident2013.dbf")
acc2012 <- read.dbf("accident2012.dbf")

table(acc$STATE)   # Note the FIPS code for each STATE
acc_va2001 <- subset(acc, STATE==51)  # subset the acc dataframe to get only virginia
acc_va2013 <- subset(acc2013, STATE==51)
acc_va2012 <- subset(acc2012, STATE==51)

# The map() function from the maps package does a lot of the work for you map-wise. In the code below, the first line draws a blank map with state boundaries. The second line draws points on the map, one point per accident. Notice the order of longitude and latitude.

map("state", region="virginia", lwd=1, col="red")      # Default projection is rectangular

map('county', 'virginia', col = palette())             # OR i can map virginia with counties outlined

points(acc_va2001$longitud, acc_va2001$latitude, col="red", bg="#000000", pch=21, cex=0.20)
points(acc_va2012$LONGITUD, acc_va2012$LATITUDE, col="red", bg="#000000", pch=21, cex=0.20)
points(acc_va2013$LONGITUD, acc_va2013$LATITUDE, col="red", bg="#000000", pch=21, cex=0.20)

# You don't have to stick with the default map() rectangular projection. For example, you can use the Albers projection, as shown below. Notice that mapproject() is used in points(). This transforms the latitude and longitude coordinates so that they are placed properly on the new space.
# Albers projection
map("state", region="virginia", proj="albers", param=c(39,45), lwd=1, col="#cccccc")
map("county", region="virginia", proj="albers", param=c(39,45), lwd=1, col="black")
points(mapproject(acc_va2001$longitud, acc_va2001$latitude), col="red", bg="#00000030", pch=21, cex=0.20)
points(mapproject(acc_va2013$LONGITUD, acc_va2013$LATITUDE), col="red", bg="#00000030", pch=21, cex=0.20)

# Multiple Maps at Once -- Now plot fatal accidents in 2001 and 2013 side by side
par(mfrow=c(1,2), mar=c(0,0,0,0))
map("county", region="virginia", proj="albers", param=c(39,45), lwd=1, col="black")
points(mapproject(acc_va2001$longitud, acc_va2001$latitude), col="red", bg="#00000030", pch=21, cex=0.20)
map("county", region="virginia", proj="albers", param=c(39,45), lwd=1, col="black")
points(mapproject(acc_va2013$LONGITUD, acc_va2013$LATITUDE), col="red", bg="#00000030", pch=21, cex=0.20)

### Applying the same ideas to Choropleth maps
# Instead of point maps, you want to aggregate by state and map with choropleth. The logic is still the same: Learn to make one map and then make more of them.

# It might be useful to map the number of accidents by state, but instead of absolute counts, let's look at number of accidents per million population. 
# NOTE: the below data munging could be done using dplyr() -- maybe do similar calcs later
# NOTE: Want to do the same thing tutorial does but for virginia counties...
# Read in accident files:
acc <- read.dbf("accident2001.dbf")
acc2013 <- read.dbf("accident2013.dbf")
acc2012 <- read.dbf("accident2012.dbf")

table(acc$STATE)   # Note the FIPS code for each STATE
# Isolate accident files to Virginia only
acc_va2001 <- subset(acc, STATE==51)  # subset the acc dataframe to get only virginia
acc_va2013 <- subset(acc2013, STATE==51)
acc_va2012 <- subset(acc2012, STATE==51)

# Read in population files (note for VA counties, read from different dir and munging required)
statepop <- read.csv("states.csv")
statecnts <- count(acc$STATE)
states <- merge(statepop, statecnts, by.x="code", by.y="x")
glimpse(states)
states$accrate <- states$freq/(states$pop2012/1000000)

countypop <-read.table("/Users/stuart/DataSets/virginia/population.txt", header=TRUE, sep="\t", stringsAsFactors = FALSE)
countypop <- subset(countypop, grepl(" County", countypop$areaname, perl=TRUE))
countypop = tbl_df(countypop)
countypop2012 <- countypop %>% 
  filter(periodyear == 2012) %>%
  select(area, areaname, population)

# write out countypop2012 to csv file so that it matches wtih counties2.fin
#write.csv(countypop2012, file = "countypopulation2012.csv")
#countypop2012 <- read.csv("countypopulation2012.csv", sep=",", header=TRUE, stringsAsFactors= FALSE)

countypop2012$area <- as.numeric(as.character(countypop2012$area))
countypop2012$area <- as.integer(countypop2012$area)
str(countypop2012)

countycnts <- count(acc_va2012$COUNTY)
counties <- merge(countypop2012, countycnts, by.x="area", by.y="x")
counties$areaname <- gsub(" County", "", counties$areaname)  # before match() remove "County" from each areaname value in counties df
counties$areaname <- gsub(" city", "", counties$areaname)
counties$accrate <- counties$freq/(counties$population/60000)  # 60K is based on mean of county populations

# write out counties to csv file so that it can be munged to include cities/counties that did not show up in acc or countypop data sets (that merge into counties) to that it matches with counties2.fin
write.csv(counties, file = "counties_file.csv", row.names=FALSE)  # to get munged manually
counties <- read.csv("counties_file.csv", sep=",", header=TRUE, stringsAsFactors= FALSE)
#countypop2012 <- read.csv("countypopulation2012.csv", sep=",", header=TRUE, stringsAsFactors= FALSE)
# Ideally, you'd be able to plug in the data as-is to the map() function, but it doesn't quite work. Some states in the map database are split into separate parts. For example, New York is split as Manhattan, "main" New York, Staten Island, and Long Island. You have to match these individual regions to the state values.
# DO SAME THING FOR FOR COUNTYPOP USING CODE IN POP SECTION OF NOVA.R (SEE VA.COUNTY.POP2012)

# Match values to database region names
mapnames <- map("state", plot=FALSE)$names
regionlist <- strsplit(mapnames, ":")   # a list is returned
mapnames.fin <- sapply(regionlist, "[", 1)
m <- match(mapnames.fin, tolower(states$name)) # match returns a vector of the positions
maprates <- states$accrate[m]

# Match values to database for county names (munging required)
countynames <- map("county", "virginia", plot=FALSE)$names
countylist <- strsplit(countynames, ",")
countynames.fin <- sapply(countylist, "[", 2)  
#NOTE(20150314): may want to stop here and match
countylist2 <- strsplit(countynames.fin, ":")  # Need to do strsplit twice because map() contains "," and ":" as seps
countynames2.fin <- sapply(countylist2, "[", 1)
countynames2.fin

# Let's try to get the 3 key datasets to have the same counties as countynames2.fin
setdiff(tolower(counties$areaname), countynames2.fin)
setdiff(countynames2.fin, tolower(counties$areaname) )
setdiff(countynames2.fin, tolower(merged_acc_bridges$areaname) )
setdiff(tolower(merged_acc_bridges$areaname), countynames2.fin)

# so from the above, it appears that i am missing the following counties from counties:
#missing <- setdiff(countynames2.fin, tolower(counties$areaname) )
mc <- match(countynames2.fin, tolower(counties$areaname))
countyrates <- counties$accrate[mc]

mb <- match(countynames2.fin, tolower(merged_acc_bridges$areaname))
bridgenums <- merged_acc_bridges$bridges[mb]

# helper function that will help in the next step. It takes a value and returns a color based on that number.
getColor <- function(x) {
  if(x > 200) {
    col <- "#13373e" 
  } else if (x > 150) {
    col <- "#246571"
  } else if (x > 100) {
    col <- "#308898"
  } else {
    col <- "#7bc7d5"
  }  
  return(col)
}
getColorCounty <- function(x) {
  if(x > 20) {
    col <- "#13373e" 
  } else if (x > 15) {
    col <- "#246571"
  } else if (x > 10) {
    col <- "#308898"
  } else {
    col <- "#7bc7d5"
  }  
  return(col)
}

getColorBridge <- function(x) {
  if(x > 300) {
    col <- "#13373e" 
  } else if (x > 150) {
    col <- "#246571"
  } else if (x > 78) {
    col <- "#308898"
  } else {
    col <- "#7bc7d5"
  }  
  return(col)
}
# Now get a color for each accident rate per state. Apply the getColor() helper function to each value. Then all you have to do is map regions with those colors. Be sure to set fill to TRUE and col to statecols.
statecols <- sapply(maprates, FUN=getColor)
map("state", regions=states$name[m], proj="albers", param=c(39,45),fill=TRUE, col=statecols, border=NA, resolution=0)

countycols <- sapply(countyrates, FUN=getColorCounty)
map("county", regions=counties$name[mc], proj="albers", param=c(39,45),fill=TRUE, col=countycols, border=NA, resolution=0)

bridgecols <- sapply(bridgenums, FUN=getColorBridge)

# DID IT!! -- the key is to ensure that the maps() regions() line up with whatever you're feeding it. Had to manually create counties_file.csv
# Plot of county accident rates
map("county", regions="virginia", proj="albers", param=c(39,45),fill=TRUE, col=countycols, border=NA, resolution=0)

# Plot of county bridge county
map("county", regions="virginia", proj="albers", param=c(39,45),fill=TRUE, col=bridgecols, border=NA, resolution=0)

plot(0,0,type="n", axes=FALSE, xlim=c(0,30), ylim=c(0,2))
rect(c(5,10,15,20), c(1,1,1,1), c(10,15,20,25), c(1.25,1.25,1.25,1.25), , col=sapply(c(50,79,151,350), getColorBridge), border="white", lwd=0.4)
text(15, 1.35, "Bridge Totals")
text(c(78,150,300), c(0.8,0.8,0.8), c(78,150,300), cex=0.8) # Tick labels

## NOTE: Appears that I can't do a basic map-choropleth package for only virginia counties... it requires state level then zoom in on a given state

######## Try the choroplethr Package
data(df_pop_county)
county_choropleth(df_pop_county,
                  title="US 2012 County Population Estimates",
                  legend="Population",
                  buckets=5,
                  zoom=c("virginia"))