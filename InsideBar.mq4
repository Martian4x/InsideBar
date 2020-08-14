//+------------------------------------------------------------------+
//|                                                      Stolper.mq4 |
//|                                       Copyright 2020, Martian4x. |
//|                                        https://www.martian4x.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Martian4x."
#property link      "https://www.martian4x.com"
#property version   "2.00"
#property strict
// Preprocessor 
#include <TradingFunctions.mqh>

// External Variables 
extern bool DynamicLotSize = true; 
extern double EquityPercent = 1; 
extern double FixedLotSize = 0.01;
extern int Kperiod = 14; 
extern int Dperiod = 5; 
extern int Slowing = 3; 
extern int PriceField = 0; 
extern int UpperLevel = 70; 
extern int LowerLevel = 30; 

extern int Slippage = 2; 
extern int AdjustPips = 2;
extern int MagicNumber = 2112;

// Global Variables 
double StopLoss; 
double TakeProfit;
double BuyStopLoss; 
double BuyTakeProfit;
double SellStopLoss; 
double SellTakeProfit; 
int BuyTicket; 
int SellTicket; 
double UsePoint; 
int UseSlippage;
string StatusComment = "";
string AccountType;
string TicketNumber;
string InsideBar;
string InsideBarStatus;
double BuyPendingPrice;
double SellPendingPrice;
double PendingPrice;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- 
    // Check if the live trading is allowed
    if(IsTradeAllowed() == false) 
      Alert("Enable the setting \'Allow live trading\' in the Expert Properties!");
    if(IsDemo()) 
      AccountType = "Demo Account"; else AccountType =  "Real Account"; 

    UsePoint = PipPoint(Symbol()); 
    UseSlippage = GetSlippage(Symbol(),Slippage);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
    // Check to to see if there is more than 100 bars
    if(Bars<100){
      Print("bars less than 100");
      StatusComment = "Stop: There must more that 100 bars"; 
    }

    // Inside Bars 
    if(Close[2] >= Close[1] && Open[2] <= Open[1]){
      InsideBar = "Buy";
      BuyPendingPrice = NormalizeDouble((High[2]+(High[2]-Low[2])*0.10), MarketInfo(Symbol(),MODE_DIGITS));
      BuyTakeProfit = High[2]+(High[2]-Low[2])*0.80;
      BuyTakeProfit = AdjustAboveStopLevel(Symbol(),BuyTakeProfit,AdjustPips); // Adjust stop level
      BuyTakeProfit = NormalizeDouble(BuyTakeProfit, MarketInfo(Symbol(),MODE_DIGITS));
      BuyStopLoss = High[2]-(High[2]-Low[2])*0.20;
      BuyStopLoss = AdjustBelowStopLevel(Symbol(),BuyStopLoss,AdjustPips); // Adjust Stop level
      BuyStopLoss = NormalizeDouble(BuyStopLoss, MarketInfo(Symbol(),MODE_DIGITS));
      PendingPrice = BuyPendingPrice;
      StopLoss = BuyStopLoss;
      TakeProfit = BuyTakeProfit;
    }
    if(Close[2] <= Close[1] && Open[2] >= Open[1]){
      InsideBar = "Sell";
      SellPendingPrice = NormalizeDouble((Low[2]-(High[2]-Low[2])*0.10), MarketInfo(Symbol(),MODE_DIGITS));
      SellStopLoss = Low[2]+(High[2]-Low[2])*0.20;
      SellStopLoss = AdjustAboveStopLevel(Symbol(),SellStopLoss,AdjustPips);
      SellStopLoss = NormalizeDouble(SellStopLoss, MarketInfo(Symbol(),MODE_DIGITS));
      SellTakeProfit = Low[2]-(High[2]-Low[2])*0.80;
      SellTakeProfit = AdjustBelowStopLevel(Symbol(),SellTakeProfit,AdjustPips);
      SellTakeProfit = NormalizeDouble(SellTakeProfit, MarketInfo(Symbol(),MODE_DIGITS));
      PendingPrice = SellPendingPrice;
      StopLoss = SellStopLoss;
      TakeProfit = SellTakeProfit;
    }

    // Trading Operations
    if(InsideBar!=""){
  //--- Defining Stochastic Values
      double K1 = iStochastic(NULL,0,Kperiod,Dperiod,Slowing,MODE_SMA,0,MODE_MAIN,1);
      double D1 = iStochastic(NULL,0,Kperiod,Dperiod,Slowing,MODE_SMA,0,MODE_SIGNAL,1);
      double K2 = iStochastic(NULL,0,Kperiod,Dperiod,Slowing,MODE_SMA,0,MODE_MAIN,2);
      double D2 = iStochastic(NULL,0,Kperiod,Dperiod,Slowing,MODE_SMA,0,MODE_SIGNAL,2);

      // Lot size calculation 
      double LotSize;
      LotSize = CalcLotSize(DynamicLotSize,EquityPercent,StopLoss,FixedLotSize);

      // Lot size verification
      LotSize = VerifyLotSize(LotSize);

      // Buy Signal
      if((K1 < LowerLevel) && InsideBar=="Buy"){
        if((D1 < K1) && (D2 > K2) && BuyMarketCount(Symbol(),MagicNumber) == 0 && BuyStopCount(Symbol(),MagicNumber) == 0){
          // Close EA sell orders 
          if(SellMarketCount(Symbol(),MagicNumber) > 0) { 
            CloseAllSellOrders(Symbol(),MagicNumber,Slippage); 
          }
          // Close all other pending orders
          if(BuyStopCount(Symbol(), MagicNumber)||SellStopCount(Symbol(), MagicNumber)){
            CloseAllBuyStopOrders(Symbol(), MagicNumber);
            CloseAllSellStopOrders(Symbol(), MagicNumber);
          }
          // Buy Order Open
          BuyTicket = OpenBuyStopOrder(Symbol(), LotSize, BuyPendingPrice, BuyStopLoss, BuyTakeProfit, Slippage, MagicNumber);
          StatusComment = "BuyStop order :"+BuyTicket+" placed";
        }
      }
      // Sell Signal
      if((K1 > UpperLevel) && InsideBar=="Sell"){
        if((D1 > K1) && (D2 < K2) && SellMarketCount(Symbol(),MagicNumber) == 0 && SellStopCount(Symbol(),MagicNumber) == 0){
          // Close all EA opened Buy Orders
          if(BuyMarketCount(Symbol(),MagicNumber) > 0) { 
            CloseAllBuyOrders(Symbol(),MagicNumber,Slippage); 
          }
          // Close Pending Sell orders
          if(BuyStopCount(Symbol(), MagicNumber)||SellStopCount(Symbol(), MagicNumber)){
            CloseAllBuyStopOrders(Symbol(), MagicNumber);
            CloseAllSellStopOrders(Symbol(), MagicNumber);
          }
          // Sell Order Open
          SellTicket = OpenSellStopOrder(Symbol(), LotSize, SellPendingPrice, SellStopLoss, SellTakeProfit, Slippage, MagicNumber);
          StatusComment = "SellStop order :"+SellTicket+" placed";
        }
      }
      // Close Sell Order
      InsideBarStatus=InsideBar;
      InsideBar="";
    }
    
    // Chart Comment
    string AccountInfo = "Type: "+AccountType+", Leverage: "+AccountLeverage()+", Broker: "+AccountInfoString(ACCOUNT_COMPANY)+", Server: "+AccountInfoString(ACCOUNT_SERVER)+", AccountName: "+AccountName(); 
    string SettingsComment = "DynamicLotSize: "+DynamicLotSize+", EquityPercent: "+EquityPercent+", FixedLotSize: "+FixedLotSize+", StopLoss: "+StopLoss+", TakeProfit: "+TakeProfit; 
    string Settings2Comment = "Slippage: "+Slippage+", AdjustPips: "+AdjustPips+", MagicNumber: "+MagicNumber; 
    string IndicatorsComment = "Kperiod: "+Kperiod+", Dperiod: "+Dperiod+" Slowing: "+Slowing+", PriceField: "+PriceField+", UpperLevel: "+UpperLevel+", LowerLevel: "+LowerLevel; 
    string OrderComment = "InsideBar: "+InsideBarStatus+", PendingPrice: "+PendingPrice+", TakeProfit: "+TakeProfit+", StopLoss: "+StopLoss; 
    Comment(AccountInfo+"\n"+SettingsComment+"\n"+Settings2Comment+"\n"+IndicatorsComment+"\n"+StatusComment+"\n"+OrderComment);
   
  }
//+------------------------------------------------------------------+
