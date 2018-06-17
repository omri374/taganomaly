FROM rocker/shiny:latest

RUN  echo 'install.packages(c("shiny","shinydashboard","dplyr","DT","ggplot2","gridExtra"), \
repos="http://cran.us.r-project.org", \
dependencies=TRUE)' > /tmp/packages.R \
  && Rscript /tmp/packages.R

EXPOSE 3838
CMD ["/usr/bin/shiny-server.sh"]