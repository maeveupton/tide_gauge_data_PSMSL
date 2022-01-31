# tide_gauge_data_PSMSL
 Script to read tide gauge data from the PSMSL website for annual and monthly data. 

# PSMSL Data
The data from PSMSL website requires updates. Firstly, annual data records tend to be shorter as there are strict filtering conditions in place, as such, sites where data is missing for one month in a year are removed. This maybe be too strict for your use. As a result, monthly data is prefered and means are taken by year to create an updated annual records. In addition, the data has a 7000 mm offset that needs to be removed. Another important note is that data where the value is 9999 means that it is an NA value.
 
# Reference:  
https://gist.github.com/flare9x/a13482087e322b8ba6c208194c85a182
 
