// Agent trader in project exercise3.mas2j

stepFactor(0.2).
minStep(0.1).

/* Initial beliefs and rules */

/* Initial goals */

//offers([],18).

empty([]).

findBestSale(Product,Best) :- 
 sales(Product,Buyers) & 
 bestSale(Product,Buyers,null,0,Best).

bestSale(Product,[],BestBuyer,BestPrice,BestBuyer).

bestSale(Product,[First|Rest],BestBuyer,BestPrice,Best) :-
 lastPrice(Product,First,LastPrice) & 
 LastPrice > BestPrice & 
 bestSale(Product,Rest,First,LastPrice,Best).
 
bestSale(Product,[First|Rest],BestBuyer,BestPrice,Best) :-
 lastPrice(Product,First,LastPrice) & 
 LastPrice <= BestPrice & 
 bestSale(Product,Rest,BestBuyer,BestPrice,Best).
 
findBestNegotiation(Product,Best) :- 
 negotiations(Product,Sellers) & 
 bestNegotiation(Product,Sellers,null,1000000,Best).

bestNegotiation(Product,[],BestSeller,BestPrice,BestSeller).

bestNegotiation(Product,[First|Rest],BestSeller,BestPrice,Best) :-
 lastPrice(Product,First,LastPrice) & 
 LastPrice < BestPrice & 
 bestNegotiation(Product,Rest,First,LastPrice,Best).
 
bestNegotiation(Product,[First|Rest],BestSeller,BestPrice,Best) :-
 lastPrice(Product,First,LastPrice) & 
 LastPrice >= BestPrice & 
 bestNegotiation(Product,Rest,BestSeller,BestPrice,Best).

removeFromList([],_,[]).
 
removeFromList([Partner|Rest],Partner,Result) :-
 removeFromList(Rest,Partner,Result).
 
removeFromList([Someone|Rest],Partner,[Someone|Result]) :-
 removeFromList(Rest,Partner,Result).

 
/* Common plans */
@addRespondToNew[atomic]
+!addRespondTo(Product,Partner)  : not respondTo(Product,Anyone) <-
 .print("added RespondTo",Product,Partner);
 +respondTo(Product,[Partner]).
 
@addRespondToExisting[atomic]
+!addRespondTo(Product,Partner)  : respondTo(Product,Current) <-
 .print("added RespondTo",Product,Partner);
 -respondTo(Product,Current);
 +respondTo(Product,[Partner|Current]).
 
@removeRespondToEmpty[atomic]
+!removeRespondTo(Product,Partner)  : not respondTo(Product,_) <-
 +respondTo(Product,[]).

@removeRespondToNonEmpty[atomic]
+!removeRespondTo(Product,Partner)  : respondTo(Product,List) <-
 ?removeFromList(List,Partner,NewList);
 -respondTo(Product,List);
 +respondTo(Product,NewList).

/* Plans for Seller */

@offers[atomic]
+offers(Product,Price)  : true <- 
 .my_name(Me);
 +waitingFor(Product,null);
 .send(matchmaker,achieve,registerOffer(Product,Me));
 .send(matchmaker,achieve,getBuyers(Product,Me)).

@setBuyersEmpty[atomic]
+!setBuyers(Product,Buyers)  : empty(Buyers) <- .print("No Buyers for now for ",Product).

@setBuyersNonEmpty[atomic]
+!setBuyers(Product,Buyers)  : not empty(Buyers) <- 
 .print("Got buyers for ",Product);
 +sales(Product,Buyers);
 !setupSales(Product,Buyers).

@setupSalesNonEmpty[atomic]
+!setupSales(Product,[First|Rest])  : true <-
 ?offers(Product,Price);
 +lastPrice(Product,First,Price * 2);
 !setupSales(Product,Rest).

@setupSalesEmpty[atomic]
+!setupSales(Product,[])  : true <-
 ?sales(Product,TestBuyers);
 //.print("in setupSales: ",TestBuyers);
 ?findBestSale(Product,Best);
 //.print("in setupSales 3: ",Best);
 !makeSaleOffer(Product,Best,true).			

@makeSaleOfferInitialNotSent[atomic]
+!makeSaleOffer(Product,Buyer,true)  : lastPrice(Product,Buyer,_) & not initialSent(Product,Buyer) <-
 ?waitingFor(Product,Current);
 -waitingFor(Product,Current);
 +waitingFor(Product,Buyer);
 .my_name(Me);
 ?lastPrice(Product,Buyer,OldPrice);
 ?offers(Product,MinPrice);
 +initialSent(Product,Buyer);
 .print("sends initial offer for ",Product,Buyer,OldPrice);
 !removeRespondTo(Product,Buyer);
 .send(Buyer,achieve,reactToBuyOffer(Product,Me,OldPrice,true)).
 
@makeSaleOfferInitialSent[atomic]
+!makeSaleOffer(Product,Buyer,true)  : lastPrice(Product,Buyer,_) & initialSent(Product,Buyer) <-
 .print("wanted to send initial offer, but did not because already sent reply.",Product).
 
@makeSaleOfferWaitingForOther[atomic]
+!makeSaleOffer(Product,Buyer,false)  : not (waitingFor(Product,Buyer) | waitingFor(Product,null)) <-
 !addRespondTo(Product,Buyer).
 
@makeSaleOfferStandard[atomic]
+!makeSaleOffer(Product,Buyer,false)  : true <-
 ?waitingFor(Product,Current);
 -waitingFor(Product,Current);
 +waitingFor(Product,Buyer);
 .my_name(Me);
 ?lastPrice(Product,Buyer,OldPrice);
 ?offers(Product,MinPrice);
 +initialSent(Product,Buyer);
 ?stepFactor(StepFactor);
 -lastPrice(Product,Buyer,OldPrice);
 +lastPrice(Product,Buyer,OldPrice - ((OldPrice-MinPrice)*StepFactor));
 .print("sends noninitial offer for ",Product,Buyer);
 !removeRespondTo(Product,Buyer);
 .send(Buyer,achieve,reactToBuyOffer(Product,Me,OldPrice - ((OldPrice-MinPrice)*StepFactor),false)).
 
@reactSaleUnknownPartner[atomic]
+!reactToSaleOffer(Product,Buyer,Price,true)  : not lastPrice(Product,Buyer,LastPrice) <-
 ?offers(Product,MinPrice);
 +lastPrice(Product,Buyer,2 * MinPrice);
 !addSale(Product,Buyer);
 !reactToSaleOffer(Product,Buyer,Price,false). // FIXME Initial is not actually false 
 
@reactSaleWaitingForOther[atomic]
+!reactToSaleOffer(Product,Buyer,Price,Initial)  : not (waitingFor(Product,Buyer) | waitingFor(Product,null)) <-
 !addRespondTo(Product,Buyer).

@reactSaleStandard[atomic]
+!reactToSaleOffer(Product,Buyer,Price,Initial)  : lastPrice(Product,Buyer,_) <-
 !respondToSaleOffer(Product,Buyer,Price).
 
@respondSaleWaitingForOther[atomic]
+!respondToSaleOffer(Product,Buyer,Price)  : not ( waitingFor(Product,Buyer) | waitingFor(Product,null)) <-
 !addRespondTo(Product,Buyer).

@respondSaleCounter[atomic]
+!respondToSaleOffer(Product,Buyer,Price)  : findBestSale(Product,Best)
                                          & lastPrice(Product,Best,LastPrice)
										  & offers(Product,MinPrice)
										  & stepFactor(StepFactor)
										  & minStep(MinStep)
										  & ((LastPrice - MinPrice)*StepFactor) >= MinStep
										  & (LastPrice - ((LastPrice - MinPrice)*StepFactor)) > Price <-
 //.print("sale counterproposal for ",Product,Price," ",LastPrice," ",MinPrice," ",LastPrice - ((LastPrice - MinPrice)*StepFactor));
 !makeSaleOffer(Product,Buyer,false).

@respondSaleAccept[atomic]
+!respondToSaleOffer(Product,Buyer,Price)  : findBestSale(Product,Best)
                                          & lastPrice(Product,Best,LastPrice)
										  & offers(Product,MinPrice)
										  & stepFactor(StepFactor)
										  & minStep(MinStep)
										  & not (((LastPrice - MinPrice)*StepFactor) >= MinStep
										  & LastPrice - ((LastPrice - MinPrice)*StepFactor) > Price) 
										  & Price >= MinPrice <-
 .print("sale accept for ",Product,Price," ",LastPrice," ",MinPrice," ",LastPrice - ((LastPrice - MinPrice)*StepFactor)).
 
@respondSaleReject[atomic]
+!respondToSaleOffer(Product,Buyer,Price)  : findBestSale(Product,Best)
                                          & lastPrice(Product,Best,LastPrice)
										  & offers(Product,MinPrice)
										  & stepFactor(StepFactor)
										  & minStep(MinStep)
										  & not (((LastPrice - MinPrice)*StepFactor) >= MinStep
										  & LastPrice - ((LastPrice - MinPrice)*StepFactor) > Price) 
										  & Price < MinPrice <-
 .print("sale reject for ",Product,Price," ",LastPrice," ",MinPrice," ",LastPrice - ((LastPrice - MinPrice)*StepFactor)).
 
@respondSaleError[atomic]
+!respondToSaleOffer(Product,Buyer,Price)  : true <- 
 ?findBestSale(Product,Best);
 ?lastPrice(Product,Best,LastPrice);
 ?offers(Product,MinPrice);
 .print("sale error for ",Product,Price," ",LastPrice," ",MinPrice," ",LastPrice - ((LastPrice - MinPrice)*StepFactor)).
 
@addSaleEmpty[atomic]
+!addSale(Product,Buyer)  : not sales(Product,Anything) <-
 +sales(Product,[Buyer]).
 
@addSaleNonEmpty[atomic]
+!addSale(Product,Buyer)  : sales(Product,OldSales) <-
 -sales(Product,OldSales);
 +sales(Product,[Buyer|OldSales]).
 
/* Plans for Buyer */

@requests[atomic]
+requests(Product,Price)  : true <- 
 .my_name(Me);
 +waitingFor(Product,null);
 .send(matchmaker,achieve,registerRequest(Product,Me));
 .send(matchmaker,achieve,getSellers(Product,Me)).

@setSellersEmpty[atomic]
+!setSellers(Product,Sellers)  : empty(Sellers) <- .print("No Sellers for now for ",Product).

@setSellersNonEmpty[atomic]
+!setSellers(Product,Sellers)  : not empty(Sellers) <- 
 +negotiations(Product,Sellers);
 !setupNegotiations(Product,Sellers).

@setupNegosEmpty[atomic]
+!setupNegotiations(Product,[])  : findBestNegotiation(Product,Best) & not (Best = null) <-
 !makeBuyOffer(Product,Best,true).
 
@setupNegosNonEmpty[atomic]
+!setupNegotiations(Product,[First|Rest])  : true <-
 ?requests(Product,Price);
 +lastPrice(Product,First,Price / 2);
 !setupNegotiations(Product,Rest).				

@makeBuyOfferInitialNotSent[atomic]
+!makeBuyOffer(Product,Seller,true)  : lastPrice(Product,Seller,_) & not initialSent(Product,Seller) <-
 +initialSent(Product,Seller);
 ?waitingFor(Product,Current);
 -waitingFor(Product,Current);
 +waitingFor(Product,Seller);
 .my_name(Me);
 ?lastPrice(Product,Seller,OldPrice);
 ?requests(Product,MaxPrice);
 .print("sends initial offer for ",Product,Seller);
 !removeRespondTo(Product,Seller);
 .send(Seller,achieve,reactToSaleOffer(Product,Me,OldPrice,true)).
 
@makeBuyOfferInitialSent[atomic]
+!makeBuyOffer(Product,Seller,true)  : initialSent(Product,Seller) <-
 .print("wanted to send initial offer, but did not because already sent reply.",Product).
 
@reactBuySkip[atomic]
+!reactToBuyOffer(Product,Seller,Price,true)  :  initialSent(Product,Seller) <-// FIXME Whatever
 .print("One message skipped for ",Product). 

@reactBuyUnknownPartner[atomic]
+!reactToBuyOffer(Product,Seller,Price,true)  : not initialSent(Product,Seller) & not lastPrice(Product,Seller,LastPrice) <-
 ?requests(Product,MaxPrice);
 +lastPrice(Product,Seller,MaxPrice / 2.0);
 !addNegotiation(Product,Seller);
 !reactToBuyOffer(Product,Seller,Price,true). // FIXME Initial is not actually false 
 
@reactBuyWaitingForOther[atomic]
+!reactToBuyOffer(Product,Seller,Price,Initial)  : not (waitingFor(Product,Seller) | waitingFor(Product,null)) <-
 !addRespondTo(Product,Seller).
 
@reactBuyStandard[atomic]
+!reactToBuyOffer(Product,Seller,Price,Initial)  : lastPrice(Product,Seller,LastPrice) <-
 !respondToBuyOffer(Product,Seller,Price,Initial).
 
@respondBuyWaitingForOther[atomic]
+!respondToBuyOffer(Product,Seller,Price,Initial)  : not (waitingFor(Product,Seller) | waitingFor(Product,null)) <-
 !addRespondTo(Product,Seller).
 
@respondBuySkip[atomic]
+!respondToBuyOffer(Product,Seller,_,true)  : initialSent(Product,Seller) <-
 .print("One message skipped (late) for ",Product). 

@respondBuyCounter[atomic]
+!respondToBuyOffer(Product,Seller,Price,Initial)  : findBestNegotiation(Product,Best)
                                          & lastPrice(Product,Best,LastPrice)
										  & requests(Product,MaxPrice)
										  & stepFactor(StepFactor)
										  & minStep(MinStep)
										  & ((MaxPrice-LastPrice)*StepFactor) >= MinStep
										  & (LastPrice + ((MaxPrice-LastPrice)*StepFactor)) < Price <-
 +initialSent(Product,Seller);
 ?waitingFor(Product,Current);
 -waitingFor(Product,Current);
 +waitingFor(Product,Seller);
 //.print("buy counterproposal for ",Product,Price," ",LastPrice," ",MaxPrice," ",LastPrice + ((MaxPrice-LastPrice)*StepFactor));
 .my_name(Me);
 ?lastPrice(Product,Seller,OldPrice);
 ?requests(Product,MaxPrice);
 ?stepFactor(StepFactor);
 -lastPrice(Product,Seller,OldPrice);
 +lastPrice(Product,Seller,OldPrice + ((MaxPrice-OldPrice)*StepFactor));
 .print("sends counteroffer for ",Product,Seller,OldPrice + ((MaxPrice-OldPrice)*StepFactor));
 !removeRespondTo(Product,Seller);
 .send(Seller,achieve,reactToSaleOffer(Product,Me,OldPrice + ((MaxPrice-OldPrice)*StepFactor),false)).

@respondBuyAccept[atomic]
+!respondToBuyOffer(Product,Seller,Price,Initial)  : findBestNegotiation(Product,Best)
                                          & lastPrice(Product,Best,LastPrice)
										  & requests(Product,MaxPrice)
										  & stepFactor(StepFactor)
										  & minStep(MinStep)
										  & not (((MaxPrice-LastPrice)*StepFactor) >= MinStep
										  & LastPrice + ((MaxPrice-LastPrice)*StepFactor) < Price) 
										  & Price <= MaxPrice <-
 .print("buy accept for",Product,Price," ",LastPrice," ",MaxPrice," ",LastPrice + ((MaxPrice-LastPrice)*StepFactor)).
 
@respondBuyReject[atomic]
+!respondToBuyOffer(Product,Seller,Price,Initial)  : findBestNegotiation(Product,Best)
                                          & lastPrice(Product,Best,LastPrice)
										  & requests(Product,MaxPrice)
										  & stepFactor(StepFactor)
										  & minStep(MinStep)
										  & not (((MaxPrice-LastPrice)*StepFactor) >= MinStep
										  & LastPrice + ((MaxPrice-LastPrice)*StepFactor) < Price)  
										  & Price > MaxPrice <-
 .print("buy reject for ",Product,Price," ",LastPrice," ",MaxPrice," ",LastPrice + ((MaxPrice-LastPrice)*StepFactor)).
 
@respondBuyError[atomic]
+!respondToBuyOffer(Product,Seller,Price,Initial)  : true <-
 ?findBestNegotiation(Product,Best);
 ?lastPrice(Product,Best,LastPrice);
 ?requests(Product,MaxPrice);
 .print("error: ",Product,Price," ",LastPrice," ",MaxPrice," ",LastPrice + ((MaxPrice-LastPrice)*StepFactor)).
 
@addNegosEmpty[atomic]
+!addNegotiation(Product,Seller)  : not negotiations(Product,Anything) <-
 +negotiations(Product,[Seller]).
 
@addNegosNonEmpty[atomic]
+!addNegotiation(Product,Seller)  : negotiations(Product,OldNegotiations) <-
 -negotiations(Product,OldNegotiations);
 +negotiations(Product,[Seller|OldNegotiations]).
