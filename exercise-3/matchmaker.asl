// Agent matchmaker in project exercise3.mas2j

/* Initial beliefs and rules */

/* Initial goals */

buyers(rabbit,[buyer]).

/* Plans */
+!getBuyers(Product,Trader) : true <- ?buyers(Product,P);
                                      .send(Trader,achieve,setBuyers(Product,P)).

