
# Mobile Device COVID-19 Simulations by US Counties

<iframe id="test"  style=" height:700px; width:100%;" scrolling="no"  frameborder="0" src="https://jbayham.github.io/maps/distancing/distancing.html"></iframe>

This interactive map is based on the smart device driven epi-economic model in Fenichel et al. 
https://www.medrxiv.org/content/10.1101/2020.04.20.20073098v1

We plan to update the map regularly.  Text last updated May 15, 2020.  [Full screen map](https://jbayham.github.io/maps/distancing/distancing.html) 

-----------

The map classifies counties into three epidemiological conditions base on behavior shifts measured by SafeGraph home and non_home dwell time patterns. Baseline behavior is mean behavior between January 15 and February 15. 

1.	“Still Rising” – those counties where behavior may have slowed infection rates, but active cases are still rising.

2.	“Risk of Resurgence” – those counties where changes in behavior relative to the baseline period have reduced active cases, but where reverting back to the baseline behavior may lead to a risk of resurgence.

3.	“Past Peak” – those counties where active cases are declining.  This may be due to changes in behavior or because the epidemic has progressed enough that there are too few susceptibles left in the population. 

### Hover over for trajectories

This section describes the figures in the popup windows that appear when you hover over a county.  There are three curves displayed in each figure:

1.  "Blue" - simulation based on pre-epidemic behavior (Jan 15 - Feb 15)

2.  "Green" - simulation based on daily mobile device data (median home time or median away from home time) and continuing

3.  "Yellow" - simulation based on daily mobile device data (green curve) but then reverting to baseline behavior 

4. The vertical dashed line represents the last day of mobile device data.

  
### User Options

The map allows the user to explore a two-by-two assumption space. We suggest users focus on whether different modeling assumptions lead to the same conclusion about these questions: 

1.	Is the representative behavior in a county believed to have bent or flattened the curve?

2.	How big is the divergence between the current trajectory and reverting to baseline behavior?


All behavior is based on SafeGraph dwell time data. The use can use choose a model that focus on contact risk based on:

1.	Dwell time in public places (Away)

2.	Dwell time at home (Home)


Epidemiological models are also highly sensitive to initial conditions. Every county is simulated independently.  The user can determine whether to assume the epidemic starts 


1.	10 days prior to the first reported case in the state


2.	10 days prior to the first reported case in the county for counties that have reported a case. If a county has not reported a case, then the epidemic starts on the last day a county in the state reported a case. 


### Recommendations 

We believe:


1.	That in rural counties dwell time in public generally works better than dwell time at home.


2.	Smart device data is must robust in suburban counties, followed by urban counties, followed by rural counties. 


3.	Epidemiological models should not be used to predict the exact number of cases. There is no credible data source to calibrate epidemiological case and modeling hospitalizations and deaths require substantially greater assumptions. Rather the models here are useful for gauging the effect of behavioral shifts. 


4.	We suggest complementary research on the nature of behavior changes in Yan et al. https://www.medrxiv.org/content/10.1101/2020.05.01.20087874v1
