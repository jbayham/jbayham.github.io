#This script is a stop gap to port figures and results from Eli (on google
#drive) over to my github site


#Copy files over
file.copy("L:/My Drive/COVID-19/targeting distancing/bender_results/bender_current_summary.csv.gz",
          "E:/git_site/maps/distancing/bender_current_summary.csv.gz",
          overwrite = T)

file.copy("L:/My Drive/COVID-19/targeting distancing/bender_results/png_current.zip",
          "E:/git_site/maps/distancing/png_current.zip",
          overwrite = T)

file.copy("L:/My Drive/COVID-19/targeting distancing/bender_results/time_png.zip",
          "E:/git_site/maps/distancing/time_png.zip",
          overwrite = T)

###################
#Unzip files
unlink("E:/git_site/maps/distancing/png", recursive = TRUE)


unzip("E:/git_site/maps/distancing/png_current.zip",
      exdir = "E:/git_site/maps/distancing",
      overwrite = T)

unlink("E:/git_site/maps/distancing/time_png", recursive = TRUE)
unzip("E:/git_site/maps/distancing/time_png.zip",
      exdir = "E:/git_site/maps/distancing",
      overwrite = T)


