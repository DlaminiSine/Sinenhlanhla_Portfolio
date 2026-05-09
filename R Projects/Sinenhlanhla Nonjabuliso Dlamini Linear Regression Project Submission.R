#Sinenhlanhla Nonjabuliso Dlamini
#Econometrics 1 Linear regression project

library(dplyr)
hotel <- data.frame(
  Month=rep(month.name[1:12], each = 3),
  City=rep(c("Davos", "Polenca","Basel"), times = 12),
  Temperature = c(-6, 10, 1, -5, 10, 0, 2, 14, 5, 4, 17, 9, 7, 22, 14,
                  15, 24, 20, 17, 26, 23, 19, 27, 24, 13, 22, 21, 9, 19,
                  14, 4, 14, 9, 0, 12, 4 ),
  hotel_Occupation= c(91, 13, 23, 89, 21, 82, 76, 42, 40, 52, 64, 45, 42, 79, 39,
                      36, 81, 43, 37, 86, 50, 39, 92, 95, 26, 36, 64, 27, 23,
                      78, 68, 13, 9, 92, 41, 12)
)

#Solution to a

a <- lm(hotel_Occupation~Temperature, data=hotel)
as <- summary(a) 
options(scipen=999)
as
as$coefficients


#solution to b
b <- lm(hotel_Occupation~City, data=hotel)
bs <- summary(b)
bs
bs$coefficients


#solution to c
c <- aov(hotel_Occupation~City, data=hotel)
cs <- summary(c)
cs
cs$coefficients

#Sloution to d
d <- lm(hotel_Occupation~Temperature+City, data=hotel)
d
ds <- summary(d)
ds
ds$coefficients

#Solution to e
#Davos
Davos_m <- lm(hotel_Occupation~Temperature, data=filter(hotel, City=="Davos"))
Davos_m
D_m <- summary(Davos_m)
D_m$coefficients

#Polenca
Polenca_m <- lm(hotel_Occupation~Temperature, data=filter(hotel, City=="Polenca"))
P_m <- summary(Polenca_m)
P_m$coefficients


#Basel
Basel_m <- lm(hotel_Occupation~Temperature, data=filter(hotel, City=="Basel"))
B_s <- summary(Basel_m)
B_s$coefficients

#Solution to f

city = rep(c("Davos", "Polenca","Basel"), times = 12)
temperature = c(-6, 10, 1, -5, 10, 0, 2, 14, 5, 4, 17, 9, 7, 22, 14,
                15, 24, 20, 17, 26, 23, 19, 27, 24, 13, 22, 21, 9, 19,
                14, 4, 14, 9, 0, 12, 4 )
davos_d <- ifelse(city == "Davos", 1,0)
polenca_d <- ifelse(city == "Polenca", 1,0)

interaction_davos <- temperature*davos_d
interaction_polenca <- temperature*polenca_d

design_data <-data.frame(
  Intercept = rep(1,36),
  Temperature = temperature,
  Davos = davos_d,
  Polenca = polenca_d,
  Temperature_Davos = interaction_davos,
  Temperature_Polenca = interaction_polenca
)

head(design_data)

#Solution to g

Hotel_occupation = c(91, 13, 23, 89, 21, 82, 76, 42, 40, 52, 64, 45, 42, 79, 39,
                     36, 81, 43, 37, 86, 50, 39, 92, 95, 26, 36, 64, 27, 23,
                     78, 68, 13, 9, 92, 41, 12)
design_matrix <-data.frame(
  Intercept = rep(1,36),
  Temperature = temperature,
  Davos = davos_d,
  Polenca = polenca_d,
  Temperature_Davos = interaction_davos,
  Temperature_Polenca = interaction_polenca,
  Hotel_occupation = Hotel_occupation
)

design_matrix

g <- lm(Hotel_occupation~Temperature*City, data=hotel)
summary(g)

g1 <- lm(Hotel_occupation~Temperature+Davos+Polenca+Temperature_Davos+Temperature_Polenca, data=design_matrix)
summary(g1)

#Solution to h

confint(g, level = 0.99)
cov_matrix <- vcov(g)

# Coefficient estimates
coeff <- 1.3133
coeff_davos <- -4.0003
coeff_polenca <- 2.6626

# Variance and covariance values from the covariance matrix
var <- 0.478
var_davos <- 0.997
var_polenca <- 1.43

cov_temp_davos <- -0.48
cov_temp_polenca <- -0.48

# Calculate the standard errors for the combined coefficients
se_basel <- sqrt(var)
se_davos <- sqrt(var + var_davos+ 2 * cov_temp_davos)
se_polenca <- sqrt(var + var_polenca + 2 * cov_temp_polenca)

# Calculate the 95% confidence intervals
t_value <- qt(0.975, df = 30)
t_value

# Basel
point_est_basel <- coeff
lowb_basel <- point_est_basel - t_value * se_basel
uppb_basel <- point_est_basel + t_value * se_basel

# Davos
point_est_davos <- coeff + coeff_davos
lowb_davos <- point_est_davos - t_value * se_davos
uppb_davos <- point_est_davos + t_value * se_davos

# Polenca
point_est_polenca <- coeff + coeff_polenca
lowb_polenca <- point_est_polenca - t_value * se_polenca
uppb_polenca <- point_est_polenca + t_value * se_polenca

# Create a data frame for the results
results <- data.frame(
  City = c("Basel", "Davos", "Polenca"),
  Point_Estimate = c(point_est_basel, point_est_davos, point_est_polenca),
  Lower_CI = c(lowb_basel, lowb_davos, lowb_polenca),
  Upper_CI = c(uppb_basel, uppb_davos, uppb_polenca)
)

results
