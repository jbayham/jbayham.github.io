# AREC 570 Reproducibility Exercise

Reproducibility is a foundation of science.  This exercise is designed to demonstrate the benefits of organizing an empirical project for reproducibility.  Adopting these practices may save you from embarrassment and will likely save you time and headache later in your career.  This exercise is adapted from Data Carpentry's Introduction to Reproducibility (https://github.com/datacarpentry/rr-intro).

Your goal is to produce something like the document here: [report](report.pdf).  This document was produced using R and Latex.  If you use Stata, your figures and table will look different.  I'm less concerned with the look of the document and more concerned with the reproducibility of the document.

I will provide you some guidance but there are many ways to organize your project.  The project should be reproducible and well-documented.  Try to automate as much as you can

## Instructions

1. Download the data from https://jbayham.github.io/AREC570/reproducibility/data/data.zip.  The zipped file contains data and text that you will use to generate a report.

2. Create an organized directory structure.  Unzip the data into an *inputs* directory. 

3. Read the 1952-1967 data into your favorite program

4. Create a single table spanning 1952-1967 with the following columns: continent, country, year, lifeExp, pop, and gdp.

5. Calculate gdp per capita and name it gdpPercap

6. Visualize life expectancy and gdp per capita over time for Canada in the 1950s and 1960s using a line plot.

7. Regress life expectancy on gdp per capita and display the regression table.  Don't worry about the ancillary stats.


## Test 

Now have someone else reproduce your code.  Think about what information you will need to give them (your documentation).

## Deliverable

Option 1: Share the github repository with username: `jbayham`

Option 2: Submit a zipped file to Canvas containing all of the files needed to recreate your project.


## Additional Resources

images
https://www.overleaf.com/learn/latex/Inserting_Images
