# Parameters
settings = list(K = 2, # number of pack sizes
              n = c(2, 6, 0), # number of units in size k
              I = 20, # maximum inventory
              T = 200000, # periods of simulations
              T0 = 200, # burn-in period
              tol = 1e-8, # convergence tolerance
              iter_max = 800000 # maximum number of iterations
              )

param = list(beta = 0.99, # discount factor
           alpha = 4, # price sensitivity
           delta = 10, # consumption utility
           c = 0.05 # inventory holding cost
           ) 

price = list(price.norm = c(2, 5), # normal price
           price.prom = c(1.2, 3), # promotion price
           prob = c(0.84, 0.16), # probability of normal and promotion price, respectively
           L = 2 # number of price levels
           )


ValueFunctionIteration <- function (settings, param, price){
  # value function iteration
  # initialize the values under each state
  value_0 = matrix(0, nrow=settings$I+1, ncol = price$L)
  current_iteration = vector()
  current_diff = vector()
  # stoping rules
  norm = settings$tol + 1
  iteration = 1
  start.time = Sys.time()
  while(norm >= settings$tol && iteration <= settings$iter_max){
    current_iteration[iteration] = iteration
    # Bellman operator
    value = BellmanOperator(value_0, settings, param, price)$value
    # Whether the values for iteration n and iteration (n+1) are close enough
    norm = max(abs(value - value_0))
    current_diff[iteration] = norm
    # set the current values as initial values
    value_0 = value
    iteration = iteration + 1
  }
  end.time = Sys.time()
  time.elapsed = end.time - start.time
  print(time.elapsed)
  plot(current_iteration,current_diff, type = "l")
  output = BellmanOperator(value_0, settings, param, price)
  return(output)
}

# generate a function of Bellman operator
BellmanOperator <- function(value_0, settings, param, price){
  v_choice = array(0, dim = c(settings$I + 1, price$L, settings$K + 1)) #choice specific value
  value = matrix(0, nrow = settings$I + 1, ncol = price$L) #storing value under each state
  choice = matrix(0,nrow = settings$I + 1, ncol = price$L) #storing choice under each state
  inventory = c(0 : settings$I) #inventory levels
  
  #Replicating step 2 of Slide 20
  #Calculate the expected value 
  Ev=value_0 %*% price$prob
  
  #Obtaining the choice specific values
  for(k in 1:(settings$K + 1)) {
    
    #Updating inventory levels
    i_plus_n = inventory + settings$n[k] #inventory plus units in pack k
    
    #i_prime is inventory at the end of t or beginning of t+1
    i_prime = i_plus_n - 1 
    for(j in 1:length(i_prime)){
      if (i_prime[j] < 0) i_prime[j] = 0
      if (i_prime[j] > settings$I) i_prime[j] = settings$I
    }
    
    #Consumption utility minus holding cost
    u = param$delta * (i_plus_n > 0) - param$c * i_prime 
    
    #Normal price
    #Choice specific price levels
    price_l = cbind(t(price$price.norm), 0)[k]
    #updating choice specific values
    v_choice[,1,k] = u - param$alpha * price_l + param$beta * Ev[i_prime + 1]  
    
    #Promotion price
    #Choice specific price levels
    price_l = cbind(t(price$price.prom), 0)[k]
    #updating choice specific values
    v_choice[,2,k] = u - param$alpha * price_l + param$beta * Ev[i_prime + 1]  
  }
  
  #determine consumer's choice according to choice specific values
  for(j in 1:(settings$I + 1)){
    value[j,1] = max(v_choice[j, 1,])
    value[j,2] = max(v_choice[j, 2,])
    choice[j,1] = which.max(v_choice[j, 1,])
    choice[j,2] = which.max(v_choice[j, 2,])
  }
  
  #output
  output = list(value = value,
              choice = choice)
  return(output)
}



results = ValueFunctionIteration(settings, param, price)

results$choice








