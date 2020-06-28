#This script generates the leaflet map

#Loading and installing packages
init.pacs <- function(package.list){
  check <- unlist(lapply(package.list, require, character.only = TRUE))
  #Install if not in default library
  if(any(!check)){
    for(pac in package.list[!check]){
      install.packages(pac)
    }
    lapply(package.list, require, character.only = TRUE)
  }
}


init.pacs(c("tidyverse",      #shortcut to many useful packages (eg, dplyr, ggplot)
            "conflicted",     #resolves function conflict across packages
            "lubridate",      #working with dates
            "sf",             #for GIS
            "USAboundaries",  #easily access US maps in sf
            "svDialogs",      #dialog boxes on all platforms
            "data.table",
            "haven",
            "leaflet",
            "htmlwidgets",
            "htmltools",
            "googledrive"     #for accessing googledrive
            
))

#source("functions/sim_functions.R")  #all of the functions called in the model 
conflict_prefer("filter", "dplyr")

##################################################
#load cached data from sim runs
bender <- data.table::fread("maps/distancing/bender_current_summary.csv.gz",
                            keepLeadingZeros = T)
#x=cnty.sim.out[[420]]


us_st <- us_states(resolution = "low") %>%
  filter(stusps!="PR")


df.rename <- tibble(sim = c("cnty_home","cnty_away","state_home","state_away"),
                    group_name = c("County Start, Home Time","County Start, Away Time","State Start, Home Time","State Start, Away Time"))
###########################
plot.out <- bender %>%
  mutate(sim=str_replace(sim,"\\.","_")) %>%
  inner_join(df.rename)


###################################
category_labels <- c("Still Rising","Riskier than pre-epidemic","Risk of Resurgence","Past Peak")
#Bind map data into dataframe and make spatial
map.data <- plot.out %>%
  mutate(epi_effect=case_when(
    yellow.slope>0 & green.slope>0 ~ category_labels[1],
    #yellow.slope<0 & green.slope>0 ~ category_labels[2],
    yellow.slope>0 & green.slope<=0 ~ category_labels[3],
    yellow.slope<0 & green.slope<0 ~ category_labels[4]
  ),
  epi_effect=ifelse(is.na(epi_effect),"Uncertain",epi_effect),
  epi_effect=factor(epi_effect,levels = category_labels),
  start.date=as_date(start.date)) %>%
  inner_join(us_counties(resolution="low") %>% select(geoid,county=name,state_abbr),
             .,
             by=c("geoid"="fips")) %>%
  group_split(sim)

  

#Set Palette
pal_factor <- map(map.data,function(x){
  colorFactor(palette = "YlOrRd",domain = map.data$epi_effect,reverse = T)
})


#Set label values
labels_hover <- 
  map(map.data,
      function(x){
        sprintf(
          #"<strong>County</strong>: %s, %s  <br/> <strong>Cases Avoided</strong>: %g%%  <br/> <strong>Behavioral Effect</strong>: %s  <br/> <img src = 'https://jbayham.github.io/maps/distancing/png_simsv2/fig_%s_%s.png', width='200' height='150' > ",
          "<strong>County</strong>: %s, %s  <br/>  <strong>Behavioral Effect</strong>: %s  <br/> <img src = 'https://jbayham.github.io/maps/distancing/png/fig_%s_%s.png', width='350' height='200' >  <br/> <img src = 'https://jbayham.github.io/maps/distancing/time_png/time_use%s.png', width='350' height='200' >",
          x$county,
          x$state_abbr,
          #x$percent.immune.helps,
          x$epi_effect,
          x$sim,
          x$geoid,
          x$geoid) %>%
          lapply(htmltools::HTML)
      })



#Make map
m <- leaflet() %>%
  setView(-99.7274808,39.9119613,3.79) %>%
  addMapPane("background_map", zIndex = 410) %>%  # Level 1: bottom
  addMapPane("polygons", zIndex = 420) %>%        # Level 2: middle
  addMapPane("labels", zIndex = 430) %>%          # Level 3: top
  addProviderTiles(providers$CartoDB.PositronNoLabels,options = pathOptions(pane="background_map")) %>%
  addProviderTiles(providers$CartoDB.PositronOnlyLabels,options = pathOptions(pane="labels")) %>% 
  #addProviderTiles(providers$CartoDB.Positron,options = pathOptions(pane="background_map")) %>%
  #addProviderTiles(providers$CartoDB.DarkMatter,options = pathOptions(pane="background_map")) %>%
  addPolygons(data = map.data[[1]],
              fillColor = ~pal_factor[[1]](epi_effect),
              group = map.data[[1]]$group_name[1],
              weight = .8,
              opacity = 1,
              color = "white",
              dashArray = "3",
              #stroke = FALSE,
              smoothFactor = .3,
              fillOpacity = 0.7,
              highlight = highlightOptions(
                weight = 5,
                color = "#666",
                dashArray = "",
                fillOpacity = 0.7,
                bringToFront = TRUE),
              label = labels_hover[[1]],
              labelOptions = labelOptions(
                style = list("font-weight" = "normal", padding = "3px 8px"),
                textsize = "15px",
                direction = "auto"),
              options = pathOptions(pane="polygons")) %>%
  addPolygons(data = map.data[[2]],
              fillColor = ~pal_factor[[2]](epi_effect),
              group = map.data[[2]]$group_name[1],
              weight = .8,
              opacity = 1,
              color = "white",
              dashArray = "3",
              #stroke = FALSE,
              smoothFactor = .3,
              fillOpacity = 0.7,
              highlight = highlightOptions(
                weight = 5,
                color = "#666",
                dashArray = "",
                fillOpacity = 0.7,
                bringToFront = TRUE),
              label = labels_hover[[2]],
              labelOptions = labelOptions(
                style = list("font-weight" = "normal", padding = "3px 8px"),
                #opacity = .8,
                textsize = "15px",
                direction = "auto"),
              options = pathOptions(pane="polygons")) %>%
  addPolygons(data = map.data[[3]],
              fillColor = ~pal_factor[[3]](epi_effect),
              group = map.data[[3]]$group_name[1],
              weight = .8,
              opacity = 1,
              color = "white",
              dashArray = "3",
              #stroke = FALSE,
              smoothFactor = .3,
              fillOpacity = 0.7,
              highlight = highlightOptions(
                weight = 5,
                color = "#666",
                dashArray = "",
                fillOpacity = 0.7,
                bringToFront = TRUE),
              label = labels_hover[[3]],
              labelOptions = labelOptions(
                style = list("font-weight" = "normal", padding = "3px 8px"),
                #opacity = .8,
                textsize = "15px",
                direction = "auto"),
              options = pathOptions(pane="polygons")) %>%
  addPolygons(data = map.data[[4]],
              fillColor = ~pal_factor[[4]](epi_effect),
              group = map.data[[4]]$group_name[1],
              weight = .8,
              opacity = 1,
              color = "white",
              dashArray = "3",
              #stroke = FALSE,
              smoothFactor = .3,
              fillOpacity = 0.7,
              highlight = highlightOptions(
                weight = 5,
                color = "#666",
                dashArray = "",
                fillOpacity = 0.7,
                bringToFront = TRUE),
              label = labels_hover[[4]],
              labelOptions = labelOptions(
                style = list("font-weight" = "normal", padding = "3px 8px"),
                #opacity = .8,
                textsize = "15px",
                direction = "auto"),
              options = pathOptions(pane="polygons")) %>%
  addPolygons(map=.,
              data=us_st,
              fill=F,
              weight = .5,
              opacity = 1,
              color = "gray",
              options = pathOptions(pane="polygons")) %>%
  addLayersControl(baseGroups = c("County Start, Away Time","County Start, Home Time","State Start, Away Time","State Start, Home Time"), 
                   options = layersControlOptions(collapsed = FALSE)) %>%
  addLegend("bottomright",
            pal = pal_factor[[1]],
            values = map.data[[1]]$epi_effect,
            title = "Status",
            #labFormat = labelFormat(prefix = "$"),
            opacity = 1
  )
  


#Write leaflet map to html
m %>% saveWidget(file="distancing.html",title="Risk Map")



file.copy("distancing.html",
          "maps/distancing/distancing.html",
          overwrite = TRUE)
file.remove("distancing.html")
##############################
