globals [
  current-market-price ;;current market price of Bitcoin
  current-era-reward ;;amount of bitcoins rewarded for successfully mining a block, as per the current reward era
  year-counter ;;year counter to keep track of reward era
  dead-miner-counter ;;counter of dead miners
  centralisation ;;haspower distribution - This is analogous to market share and thereby a good indicator of centralisation
  previous-market-price ;;market price of Bitcoin from last tick
  price-change ;;price change percentage between previous BTC market price and current BTC market price
  mining-cost ;;cost of mining
]

breed [ risk-taking-miners a-risk-taking-miner ] ;;miners who will take risks and speculate on the price
breed [ risk-averse-miners a-risk-averse-miner ] ;;miners who will not take risks and rather sell bitcoin as soon as they receive



;;Properties of all bitcoin miners
turtles-own [
  hashpower-count ;; hash power they control as a percentage of total hash power on network.
  current-fiat-account-balance
  current-bitcoin-balance
  total-reward ;; the total amount of bitcoins that each miner has been rewarded
  current-reward ;; the most recent amount of bitcoins that each miner has been rewarded
]

;;SETUP PROCEDURES

;; this procedure sets up the model
to setup
  clear-all
  set current-era-reward BTC-reward-per-block
  set current-market-price initial-BTC-price
  set previous-market-price initial-BTC-price
  set price-change 0
  set year-counter 0
  set dead-miner-counter 0
  ask n-of number-of-risk-averse-miners patches [sprout-risk-averse-miners 1]
  ask risk-averse-miners [
    set shape "computer server"
    set size 1
    set hashpower-count 100 / (number-of-risk-averse-miners + number-of-risk-taking-miners)
    set current-fiat-account-balance (number-of-risk-averse-miners + number-of-risk-taking-miners) * cost-to-mine
    set current-bitcoin-balance 0
    set total-reward 0
    set current-reward 0
    set color green ;;risk-averse-miners represented by the colour green
  ]
  ask n-of number-of-risk-taking-miners patches [sprout-risk-taking-miners 1]
  ask risk-taking-miners [
    set shape "computer server"
    set size 1
    set hashpower-count 100 / (number-of-risk-averse-miners + number-of-risk-taking-miners)
    set current-fiat-account-balance (number-of-risk-averse-miners + number-of-risk-taking-miners) * cost-to-mine
    set current-bitcoin-balance 0
    set total-reward 0
    set current-reward 0
    set color red ;;risk-taking miners represented by the colour red
  ]
  set centralisation 100 / (count turtles) ;;calculate market share per miner
  set mining-cost cost-to-mine
  reset-ticks
end

;;RUNTIME PROCEDURES

to go
  if dead-miner-counter = ((number-of-risk-averse-miners + number-of-risk-taking-miners) - 1) [ user-message "1 mining pool controls 100% of hashpower and thus Bitcoin is completely centralised" stop ]
  set year-counter year-counter + 1
  calibrate-current-era-reward ;;calibrate the current era reward per block
  ask turtles [
    calculate-market-dominance ;;miner calculates their market dominance
    claim-reward ;;claim reward in BTC and add to current bitcoin balance
    sell-bitcoin ;;sell bitcoin received through mining rewards to pay for electricity
    check-if-dead ;;check to see if miner has already ceased operations or will cease operations due to no sufficient fiat for mining
    mine-bitcoin ;;this costs fiat
  ]
  if not any? turtles [ user-message "All miners have ceased operations as mining is no longer sustainable from a cost perspective" stop ]
  determine-who-mines-block ;;determine which operating miner was successful in mining current block
  set previous-market-price current-market-price
  set current-market-price random (max-long-term-price-prediction - min-long-term-price-prediction + 1) + min-long-term-price-prediction ;;random price between the min and max prices entered
  determine-price-change ;;determine price change % between previous and current market BTC price
  calibrate-new-cost-to-mine
  set centralisation 100 / (count turtles) ;;calculate revised market share per miner
  tick
end

;;mining procedure
to mine-bitcoin
  if current-fiat-account-balance >= mining-cost [
    set current-fiat-account-balance current-fiat-account-balance - mining-cost ;;reduce the fiat balance by the cost to mine
  ]
end

;;selling bitcoin procedure
to sell-bitcoin
  if current-bitcoin-balance > 0 [
    set current-fiat-account-balance current-bitcoin-balance * current-market-price ;;deposit fiat balance with earnings from bitcoin sale
    set current-bitcoin-balance 0 ;;bitcoins have been sold thus clear bitcoin balance
  ]
end

;;miner procedure, if no fiat left, operations are ceased
to check-if-dead
  if current-fiat-account-balance < mining-cost [
    set dead-miner-counter dead-miner-counter + 1
    set mining-cost mining-cost * (1 - (1 / (count turtles))) ;;cost to mine reduces by the % drop in active miners
    die
  ]
end

;;calibrate the current era reward per block
to calibrate-current-era-reward
  if year-counter mod 48 = 0 [ ;;halvening event occurs every 4 years within the bitcoin network. Therefore the value after mod determines the period of time every tick represents
    set current-era-reward current-era-reward / 2 ;;current era-reward halves
    if current-era-reward < 0.00000002 [
      set current-era-reward 0.00000001 ;;this number represents transaction fees
  ]]
end

;;procedure to claim reward in BTC and add to current bitcoin balance
to claim-reward
  ask risk-averse-miners [
    if current-reward > 0 [ ;;risk-averse miners will claim rewards instantly in order to fund their mining operation
    set current-bitcoin-balance current-reward
    set current-reward 0 ;;clear reward balance that has just been transferred to bitcoin balance
  ]]
  ask risk-taking-miners [
    if current-reward > 0 and current-market-price < previous-market-price [ ;;risk-taking miners will only claim reward if price has gone down since last tick. Otherwise they will hold in the hopes it will continue to rise
    set current-bitcoin-balance current-reward
    set current-reward 0 ;;clear reward balance that has just been transferred to bitcoin balance
  ]]
end

;;procedure for determining which operating miner was successful in mining current block
to determine-who-mines-block
  ask one-of turtles [
    set current-reward current-reward + current-era-reward
    set total-reward total-reward + current-era-reward
  ]
end

;;procedure for calibrating cost to mine
to calibrate-new-cost-to-mine
  if mining-cost > current-market-price * current-era-reward [ ;;this will only kick in once the mining reward approaches transaction fee only level
   set mining-cost current-market-price * current-era-reward * 0.90 ;;mining cost should not be lower than the reward as this would remove incentive to mine
  ]
end

;;procedure for calculating market dominance
to calculate-market-dominance
  set hashpower-count 100 / (count turtles)
end

;;procedure to determine price change
to determine-price-change
  if current-market-price > previous-market-price [
    set price-change ((current-market-price - previous-market-price) / previous-market-price) * 100
  ]
  if current-market-price < previous-market-price [
    set price-change ((previous-market-price - current-market-price) / previous-market-price) * -100
  ]
  if current-market-price = previous-market-price [
    set price-change 0
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
213
91
640
519
-1
-1
12.7
1
10
1
1
1
0
0
0
1
-16
16
-16
16
1
1
1
Months
30.0

INPUTBOX
11
10
187
70
initial-BTC-price
67.0
1
0
Number

PLOT
656
282
862
458
Miner Reward Distribution
Total Rewards (BTC)
Miners
0.0
10.0
0.0
10.0
true
false
"" "set-plot-y-range 0 (number-of-risk-averse-miners + number-of-risk-taking-miners)\nset-plot-x-range 0 (max [ total-reward ] of turtles + 1)"
PENS
"default" 1.0 1 -16777216 true "" "histogram [ total-reward ] of turtles"

BUTTON
96
384
159
417
NIL
GO
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
19
384
89
417
NIL
SETUP
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
8
305
212
338
number-of-risk-averse-miners
number-of-risk-averse-miners
9
18
14.0
1
1
NIL
HORIZONTAL

PLOT
862
283
1063
458
Number of Miners Operating
Months
Miners 
0.0
10.0
0.0
10.0
true
false
"" "set-plot-y-range 0 (number-of-risk-averse-miners + number-of-risk-taking-miners)\n"
PENS
"Number risk-averse miners" 1.0 0 -13840069 true "" "plot count risk-averse-miners\n"
"Number risk-taking-miners" 1.0 0 -2674135 true "" "plot count risk-taking-miners"

SLIDER
8
266
211
299
cost-to-mine
cost-to-mine
531
26550
6759.0
1
1
$
HORIZONTAL

PLOT
656
21
1063
283
BTC Market Price
Months 
BTC $ Price
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot current-market-price"

INPUTBOX
11
73
187
133
min-long-term-price-prediction
1.0
1
0
Number

INPUTBOX
10
137
188
197
max-long-term-price-prediction
100000.0
1
0
Number

INPUTBOX
8
201
188
261
BTC-reward-per-block
12.5
1
0
Number

MONITOR
460
521
639
566
Current Era BTC Reward
current-era-reward
8
1
11

BUTTON
95
424
158
457
GO
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
656
457
1063
699
Centralisation of Miners 
Months
Distribution of Hashpower (%)
0.0
10.0
0.0
10.0
true
false
"" "set-plot-y-range 0 100\n"
PENS
"default" 1.0 0 -16777216 true "" "plot centralisation"

MONITOR
1080
54
1218
99
Current BTC $ Price 
current-market-price
17
1
11

MONITOR
1080
108
1219
153
Previous BTC $ Price
previous-market-price
17
1
11

MONITOR
1080
163
1218
208
Price Change (%)
price-change
1
1
11

SLIDER
8
345
213
378
number-of-risk-taking-miners
number-of-risk-taking-miners
9
18
13.0
1
1
NIL
HORIZONTAL

MONITOR
211
523
384
568
Current Cost to Mine ($)
mining-cost
0
1
11

TEXTBOX
299
39
449
81
Risk Averse Miners \n\n
14
65.0
1

TEXTBOX
450
39
600
63
Risk Taking Miners
14
15.0
1

TEXTBOX
433
40
448
82
&
14
0.0
1

@#$#@#$#@
## WHAT IS IT?

This is a simplified model of mining pools operating on Bitcoin. The objective of the model is to show how centralised miners may become, due to the sustainability of mining operations as the Bitcoin block reward is reduced to only transaction fees. This model allows the user to observe the potential outcome of different miners' strategies.   

In this simplified model, Bitcoin miners, as part of mining pools, attempt to remain profitable through their mining operations. In each time step, which represents one month, miners will continue to operate if they have sufficient fiat - dollars - to pay for the cost of mining. If a miner cannot continue to operate, they will be removed from the model world. Miners who are able to continue mining will be entered into a draw where the randomly selected miner will receive the block reward. If a miner receives BTC as part of the block reward, they can sell this instantly for fiat or they can hold in the hope that the current market price of BTC will rise and thus they can sell for more during later months. 

If only one miner remains operating, the model will halt as this indicates that 1 mining pool controls 100% of the hashpower and thus Bitcoin is completely centralised.        

## HOW IT WORKS

There are two types of miners; risk-averse miners and risk-taking miners. The difference in breed determines their actions when it comes to receiving the block reward. If the miner is risk-averse, they will sell the BTC instantly, in exchange for the current BTC market price multiplied by the miner's current bitcoin balance. If the miner is risk-taking, they will hold the BTC if the current BTC market price is greater than the previous BTC market price. However, if and when the current BTC market price is less than the previous BTC market price, the risk taking miner will sell the BTC in exchange for the current BTC market price multiplied by the miner's current bitcoin balance. 

The BTC current market price is initially set by the model user. Once the model starts running, at every time step, the BTC current market price is set by a pseudorandom number generator that is limited by the upper and lower bounds decided by the model user. This is inspired by the random walk hypothesis in financial theory. 

The block reward is initially set by the model user. After 48 months, the block reward is reduced by 50%. This halfing of the block reward every 48 months will recoccur until the block reward is worth 0.00000001 BTC which represents transaction fees only. 

The cost of mining is initially set by the user. Once the model starts running, if miners are removed from the model world due to not having the sufficient amount of fiat to cover the mining cost, the mining cost will be reduced by the % drop in number of operating miners during that time step. Additionally, if the mining cost becomes greater than the current BTC market price multiplied by the current block reward, the mining cost will be set to 10% less than the current BTC market price multiplied by the current block reward.
   
## HOW TO USE IT

The model user should press SETUP before entering and setting the parameters detailed below.

The model user should insert the current BTC $ price into the input box named initial-BTC-price. This will be used as the initial market price in the model. The model-user should insert their lowest long term BTC $ price prediction into the input box named min-long-term-price-prediction. They should then insert their highest long term BTC $ price prediction into the input box named max-long-term-price-prediction. These min and max numbers will be used as the upper and lower bounds for the pseudorandom BTC market price generator. 

The model user should insert the current block reward into the input box named BTC-reward-per-block. This number can be ascertained online. This number will only get smaller due to the block reward being reduced by 50% every 48 months.

The model user should set the initial cost to mine on the cost-to-mine slider. This determines the initial fiat account balance per miner as well as the intial cost to mine. This is calculated by multiplying the cost to mine by the total number of agents; risk averse miners and risk taking miners. 

The model user should set the initial number of risk-averse miners and risk-taking miners on the two sliders; number-of-risk-averse-miners & number-of-risk-taking-miners. These numbers will determine the number of each breed of miners that will appear as green and red computer server shapes on the model world map. It should be noted that green computer server shapes represent risk-averse miners whereas red computer server shapes represent risk-taking miners. 

The model user should press GO with the two feedback loop arrows in order to let the model run continously. Alternatively, the model user can press GO to run the model through one time step. 

## THINGS TO NOTICE

The model user should notice the four plots on the right hand side of the model map. The BTC Market Price plot shows a time series of the BTC $ market price. There are also 3 monitors on the right hand side of this plot that report the current BTC $ price, the previous BTC $ price from the previous time step and the price change % between the two. The Miner Reward Distribution plot shows the distribution of rewards between the mining pools. The Number of Miners Operating plot shows two line plots. One of the total number of risk-averse miners still operating and one of the total number of risk-taking miners still operating. It should be noted that the numbers can only decrease. The Centralisation of Miners plot shows the hashpower distribution. This is analogous to market share and thereby a good indicator of centralisation. It should be noted that this number can only increase as miners are removed from the model world. There are another two monitors that report the Current Era BTC Reward and the Current Cost to Mine. It should be noted that outputs from both these monitors can only decrease as described above.    

## THINGS TO TRY

Try running the model with different numbers of the types of miners as well as different initial costs to mine. The min-long-term-price-prediction and max-long-term-price-prediction should also be adjusted with greater and smaller predictions. 

## EXTENDING THE MODEL

In this model, hashpower-count, also referred to as market dominance, has not been called upon by any procedure other than when it is determined. This property could be used to determine a miners actions with regards to changing risk-averse behaviour to risk taking by speculating on the price of BTC rising by holding their BTC rewards rather than selling instantly. Additionally, more complex rules could be implemented to dictate the behaviour of miners when it comes to selling or holding BTC from block rewards. For example, risk-taking miners could follow a more strict momentum approach to holding their BTC such as 3 consecutive price increases triggers a sell. Additionally, partial selling of BTC holdings could be enabled.    

In this model the number of miners can only decrease. However, in the real Bitcoin ecosystem, new mining pools enter the market. This would result in more hashpower being dedicated to the network and thus rising costs to mine. This could be implemented in the model in order to best reflect the real world.  

## NETLOGO FEATURES

Unfortunately there is no primitive that uses the value of a variable from a previous tick. Therefore, in order to calculate the price change between ticks, there are two price variables within the runtime procedure. First, the previous-market-price is set to the current-market-price. After that, the current-market-price is set.

## CREDITS AND REFERENCES

Nakamoto, S., (2008), "Bitcoin: A Peer-to-Peer Electronic Cash System", (https://nakamotoinstitute.org/bitcoin/)

## HOW TO CITE IT

If you mention this model in a publication, please include the below citation.

Smith, S., (2019). NetLogo Bitcoin Miner Centralisation Model. University of Strathclyde, Glasgow, Scotland. 
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

computer server
false
0
Rectangle -7500403 true true 75 30 225 270
Line -16777216 false 210 30 210 195
Line -16777216 false 90 30 90 195
Line -16777216 false 90 195 210 195
Rectangle -10899396 true false 184 34 200 40
Rectangle -10899396 true false 184 47 200 53
Rectangle -10899396 true false 184 63 200 69
Line -16777216 false 90 210 90 255
Line -16777216 false 105 210 105 255
Line -16777216 false 120 210 120 255
Line -16777216 false 135 210 135 255
Line -16777216 false 165 210 165 255
Line -16777216 false 180 210 180 255
Line -16777216 false 195 210 195 255
Line -16777216 false 210 210 210 255
Rectangle -7500403 true true 84 232 219 236
Rectangle -16777216 false false 101 172 112 184

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Centralisation over time and optimal miner strategy" repetitions="3" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count risk-averse-miners</metric>
    <metric>count risk-taking-miners</metric>
    <metric>current-era-reward</metric>
    <enumeratedValueSet variable="min-long-term-price-prediction">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-BTC-price">
      <value value="5300"/>
    </enumeratedValueSet>
    <steppedValueSet variable="number-of-risk-averse-miners" first="9" step="1" last="18"/>
    <enumeratedValueSet variable="max-long-term-price-prediction">
      <value value="20000"/>
    </enumeratedValueSet>
    <steppedValueSet variable="cost-to-mine" first="531" step="531" last="26550"/>
    <enumeratedValueSet variable="BTC-reward-per-block">
      <value value="12.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="number-of-risk-taking-miners" first="9" step="1" last="18"/>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
