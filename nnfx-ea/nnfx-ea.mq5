//+------------------------------------------------------------------+
//|                                                      nnfx-ea.mq5 |
//|                                    Copyright 2019, Stefan Lendl. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Stefan Lendl."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Expert\Expert.mqh>
//--- available signals
#include <Expert\Signal\CustomSignal\SignalFactory.mqh>
//--- available trailing
#include <Expert\Trailing\TrailingNone.mqh>
//--- available money management
#include <Expert\Money\MoneyFixedLot.mqh>
#include <NewBar\CisNewBar.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_BACKTEST_MODE
  {
   //  bit flags: BL | VL | EX | CN2 | CN
   BACKTEST_NONE       =0x00,
   BACKTEST_CONFIRM    =0x01,
   BACKTEST_CONFIRM2   =0x02,
   BACKTEST_EXIT       =0x04,
   BACKTEST_VOLUME     =0x08,
   BACKTEST_BASELINE   =0x10,
  };

#define CONFIRM_FLAG  = 0x01
#define CONFIRM2_FLAG = 0x02
#define EXIT_FLAG     = 0x04
#define VOLUME_FLAG   = 0x08
#define BASELINE_FLAG = 0x10

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
//--- inputs for expert
input string             Expert_Title         ="bt_ama";    // Document name
ulong                    Expert_MagicNumber   =13876;       // 
bool                     Expert_EveryTick     =false;       // 
input int                Expert_ProcessOnTimeLeft=10*60;    // Time in seconds to run before the candle closes
                                                            //input bool               Expert_RunOnOpenPrice=false;       // The EA is running only on open prices in ST

//--- inputs for main signal
input int                Signal_ThresholdOpen=100;         // Signal threshold value to open
input int                Signal_ThresholdClose=10;          // Signal threshold value to close
input double             Signal_PriceLevel    =0.0;         // Price level to execute a deal
input double             Signal_StopLevel     =1.5;         // Stop Loss level ATR multiplier
input double             Signal_TakeLevel     =1.0;         // Take Profit level ATR multiplier
input int                Signal_Expiration    =1;           // Expiration of pending orders (in bars)

input ENUM_BACKTEST_MODE Backtest_Mode=0x01;       // ENUM_BACKTEST_MODE  || Bit Flags

//--- inputs for Confirmation Indicator
input string Confirm_Indicator="";  // Name of Confirmation Indicator to use
input uint   Confirm_Shift=0;                       // Shift in Bars
input int Confirm_int0 = 0;   // Confirm int input 0
input int Confirm_int1 = 0;   // Confirm int input 1
input int Confirm_int2 = 0;   // Confirm int input 2
input int Confirm_int3 = 0;   // Confirm int input 3
input int Confirm_int4 = 0;   // Confirm int input 4
input int Confirm_int5 = 0;   // Confirm int input 5
input int Confirm_int6 = 0;   // Confirm int input 6
input int Confirm_int7 = 0;   // Confirm int input 7
input int Confirm_int8 = 0;   // Confirm int input 8
input int Confirm_int9 = 0;   // Confirm int input 9
input int Confirm_int10 = 0;   // Confirm int input 10
input int Confirm_int11 = 0;   // Confirm int input 11
input int Confirm_int12 = 0;   // Confirm int input 12
input int Confirm_int13 = 0;   // Confirm int input 13
input int Confirm_int14 = 0;   // Confirm int input 14
input int Confirm_int15 = 0;   // Confirm int input 15
input int Confirm_int16 = 0;   // Confirm int input 16
input int Confirm_int17 = 0;   // Confirm int input 17
input int Confirm_int18 = 0;   // Confirm int input 18
input int Confirm_int19 = 0;   // Confirm int input 19
int Confirm_int[20];

input double Confirm_double0 = 0.;   // Confirm double input 0
input double Confirm_double1 = 0.;   // Confirm double input 1
input double Confirm_double2 = 0.;   // Confirm double input 2
input double Confirm_double3 = 0.;   // Confirm double input 3
input double Confirm_double4 = 0.;   // Confirm double input 4
input double Confirm_double5 = 0.;   // Confirm double input 5
input double Confirm_double6 = 0.;   // Confirm double input 6
input double Confirm_double7 = 0.;   // Confirm double input 7
input double Confirm_double8 = 0.;   // Confirm double input 8
input double Confirm_double9 = 0.;   // Confirm double input 9
double Confirm_double[10];


input string Confirm2_Indicator="";  // Name of 2nd Confirmation Indicator to use
input uint   Confirm2_Shift=0;    // Confirm2 Shift in Bars
input int Confirm2_int0 = 0;   // Confirm2 int input 0
input int Confirm2_int1 = 0;   // Confirm2 int input 1
input int Confirm2_int2 = 0;   // Confirm2 int input 2
input int Confirm2_int3 = 0;   // Confirm2 int input 3
input int Confirm2_int4 = 0;   // Confirm2 int input 4
input int Confirm2_int5 = 0;   // Confirm2 int input 5
input int Confirm2_int6 = 0;   // Confirm2 int input 6
input int Confirm2_int7 = 0;   // Confirm2 int input 7
input int Confirm2_int8 = 0;   // Confirm2 int input 8
input int Confirm2_int9 = 0;   // Confirm2 int input 9
input int Confirm2_int10 = 0;   // Confirm2 int input 10
input int Confirm2_int11 = 0;   // Confirm2 int input 11
input int Confirm2_int12 = 0;   // Confirm2 int input 12
input int Confirm2_int13 = 0;   // Confirm2 int input 13
input int Confirm2_int14 = 0;   // Confirm2 int input 14
input int Confirm2_int15 = 0;   // Confirm2 int input 15
input int Confirm2_int16 = 0;   // Confirm2 int input 16
input int Confirm2_int17 = 0;   // Confirm2 int input 17
input int Confirm2_int18 = 0;   // Confirm2 int input 18
input int Confirm2_int19 = 0;   // Confirm2 int input 19
int Confirm2_int[20];
input double Confirm2_double0 = 0.;   // Confirm2 double input 0
input double Confirm2_double1 = 0.;   // Confirm2 double input 1
input double Confirm2_double2 = 0.;   // Confirm2 double input 2
input double Confirm2_double3 = 0.;   // Confirm2 double input 3
input double Confirm2_double4 = 0.;   // Confirm2 double input 4
input double Confirm2_double5 = 0.;   // Confirm2 double input 5
input double Confirm2_double6 = 0.;   // Confirm2 double input 6
input double Confirm2_double7 = 0.;   // Confirm2 double input 7
input double Confirm2_double8 = 0.;   // Confirm2 double input 8
input double Confirm2_double9 = 0.;   // Confirm2 double input 9
double Confirm2_double[10];

input string Exit_Indicator="";  // Name of Exit Indicator to use
input uint   Exit_Shift=0;    // Exit Shift in Bars
input int Exit_int0 = 0;   // Exit int input 0
input int Exit_int1 = 0;   // Exit int input 1
input int Exit_int2 = 0;   // Exit int input 2
input int Exit_int3 = 0;   // Exit int input 3
input int Exit_int4 = 0;   // Exit int input 4
input int Exit_int5 = 0;   // Exit int input 5
input int Exit_int6 = 0;   // Exit int input 6
input int Exit_int7 = 0;   // Exit int input 7
input int Exit_int8 = 0;   // Exit int input 8
input int Exit_int9 = 0;   // Exit int input 9
input int Exit_int10 = 0;   // Exit int input 10
input int Exit_int11 = 0;   // Exit int input 11
input int Exit_int12 = 0;   // Exit int input 12
input int Exit_int13 = 0;   // Exit int input 13
input int Exit_int14 = 0;   // Exit int input 14
input int Exit_int15 = 0;   // Exit int input 15
input int Exit_int16 = 0;   // Exit int input 16
input int Exit_int17 = 0;   // Exit int input 17
input int Exit_int18 = 0;   // Exit int input 18
input int Exit_int19 = 0;   // Exit int input 19
int Exit_int[20];
input double Exit_double0 = 0.;   // Exit double input 0
input double Exit_double1 = 0.;   // Exit double input 1
input double Exit_double2 = 0.;   // Exit double input 2
input double Exit_double3 = 0.;   // Exit double input 3
input double Exit_double4 = 0.;   // Exit double input 4
input double Exit_double5 = 0.;   // Exit double input 5
input double Exit_double6 = 0.;   // Exit double input 6
input double Exit_double7 = 0.;   // Exit double input 7
input double Exit_double8 = 0.;   // Exit double input 8
input double Exit_double9 = 0.;   // Exit double input 9
double Exit_double[10];

input string Baseline_Indicator="";  // Name of Baseline Indicator to use
input uint   Baseline_Shift=0;    // Baseline Shift in Bars
input int Baseline_int0 = 0;   // Baseline int input 0
input int Baseline_int1 = 0;   // Baseline int input 1
input int Baseline_int2 = 0;   // Baseline int input 2
input int Baseline_int3 = 0;   // Baseline int input 3
input int Baseline_int4 = 0;   // Baseline int input 4
input int Baseline_int5 = 0;   // Baseline int input 5
input int Baseline_int6 = 0;   // Baseline int input 6
input int Baseline_int7 = 0;   // Baseline int input 7
input int Baseline_int8 = 0;   // Baseline int input 8
input int Baseline_int9 = 0;   // Baseline int input 9
input int Baseline_int10 = 0;   // Baseline int input 10
input int Baseline_int11 = 0;   // Baseline int input 11
input int Baseline_int12 = 0;   // Baseline int input 12
input int Baseline_int13 = 0;   // Baseline int input 13
input int Baseline_int14 = 0;   // Baseline int input 14
input int Baseline_int15 = 0;   // Baseline int input 15
input int Baseline_int16 = 0;   // Baseline int input 16
input int Baseline_int17 = 0;   // Baseline int input 17
input int Baseline_int18 = 0;   // Baseline int input 18
input int Baseline_int19 = 0;   // Baseline int input 19
int Baseline_int[20];
input double Baseline_double0 = 0.;   // Baseline double input 0
input double Baseline_double1 = 0.;   // Baseline double input 1
input double Baseline_double2 = 0.;   // Baseline double input 2
input double Baseline_double3 = 0.;   // Baseline double input 3
input double Baseline_double4 = 0.;   // Baseline double input 4
input double Baseline_double5 = 0.;   // Baseline double input 5
input double Baseline_double6 = 0.;   // Baseline double input 6
input double Baseline_double7 = 0.;   // Baseline double input 7
input double Baseline_double8 = 0.;   // Baseline double input 8
input double Baseline_double9 = 0.;   // Baseline double input 9
double Baseline_double[10];

input string Volume_Indicator="";  // Name of Volume Indicator to use
input uint   Volume_Shift=0;    // Volume Shift in Bars
input int Volume_int0 = 0;   // Volume int input 0
input int Volume_int1 = 0;   // Volume int input 1
input int Volume_int2 = 0;   // Volume int input 2
input int Volume_int3 = 0;   // Volume int input 3
input int Volume_int4 = 0;   // Volume int input 4
input int Volume_int5 = 0;   // Volume int input 5
input int Volume_int6 = 0;   // Volume int input 6
input int Volume_int7 = 0;   // Volume int input 7
input int Volume_int8 = 0;   // Volume int input 8
input int Volume_int9 = 0;   // Volume int input 9
input int Volume_int10 = 0;   // Volume int input 10
input int Volume_int11 = 0;   // Volume int input 11
input int Volume_int12 = 0;   // Volume int input 12
input int Volume_int13 = 0;   // Volume int input 13
input int Volume_int14 = 0;   // Volume int input 14
input int Volume_int15 = 0;   // Volume int input 15
input int Volume_int16 = 0;   // Volume int input 16
input int Volume_int17 = 0;   // Volume int input 17
input int Volume_int18 = 0;   // Volume int input 18
input int Volume_int19 = 0;   // Volume int input 19
int Volume_int[20];
input double Volume_double0 = 0.;   // Volume double input 0
input double Volume_double1 = 0.;   // Volume double input 1
input double Volume_double2 = 0.;   // Volume double input 2
input double Volume_double3 = 0.;   // Volume double input 3
input double Volume_double4 = 0.;   // Volume double input 4
input double Volume_double5 = 0.;   // Volume double input 5
input double Volume_double6 = 0.;   // Volume double input 6
input double Volume_double7 = 0.;   // Volume double input 7
input double Volume_double8 = 0.;   // Volume double input 8
input double Volume_double9 = 0.;   // Volume double input 9
double Volume_double[10];

//--- inputs for money
input double             Money_FixLot_Percent =10.0;        // Percent
input double             Money_FixLot_Lots    =0.1;         // Fixed volume
//+------------------------------------------------------------------+
//| Global expert object                                             |
//+------------------------------------------------------------------+
CExpert ExtExpert;
CisNewBar isNewBarCurrentChart;            // instance of the CisNewBar class: current chart

bool        CandleProcessed=false;
//+------------------------------------------------------------------+
//| Initialization function of the expert                            |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Initializing expert
   if(!ExtExpert.Init(Symbol(),Period(),Expert_EveryTick,Expert_MagicNumber))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing expert");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
     
    ExtExpert.OnTradeProcess(true);
    ExtExpert.StopAtrMultiplier(Signal_StopLevel);
    ExtExpert.TakeAtrMultiplier(Signal_TakeLevel);
     
//--- Creating signal
   CExpertSignal *signal=new CExpertSignal;
   if(signal==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating signal");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//---
   ExtExpert.InitSignal(signal);
   signal.ThresholdOpen(Signal_ThresholdOpen);
   signal.ThresholdClose(Signal_ThresholdClose);
   signal.PriceLevel(Signal_PriceLevel);
   signal.Expiration(Signal_Expiration);
   if (!signal.AddAtr())
        {
      //--- failed
      printf(__FUNCTION__+": error creating ATR");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }

   SetupInputArrays();

// -------------- add confirmation indicator
   if(StringCompare(Confirm_Indicator,"")==0)
     {
      //--- failed
      printf(__FUNCTION__+": No Confirmation Indicator configured");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
   CExpertSignal *confirm_signal=CSignalFactory::MakeSignal(Confirm_Indicator,
                                                            Confirm_int,Confirm_double,
                                                            PERIOD_CURRENT,Confirm_Shift);

   if(confirm_signal==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating signal "+Confirm_Indicator);
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
   signal.AddConfirmSignal(confirm_signal);
   printf("Added Confirmation Indicator "+Confirm_Indicator);

// -------------- add 2nd confirmation indicator  -----------------------------
   if(StringCompare(Confirm2_Indicator,"")!=0)
     {
      CExpertSignal *confirm2_signal=CSignalFactory::MakeSignal(Confirm2_Indicator,
                                                                Confirm2_int,Confirm2_double,
                                                                PERIOD_CURRENT,Confirm2_Shift);

      if(confirm2_signal==NULL)
        {
         //--- failed
         printf(__FUNCTION__+": error creating signal "+Confirm2_Indicator);
         ExtExpert.Deinit();
         return(INIT_FAILED);
        }
      signal.AddConfirm2Signal(confirm2_signal);
      printf("Added 2nd Confirmation Indicator "+Confirm2_Indicator);
     }

// -------------- add exit indicator --------------------------------
   if(StringCompare(Exit_Indicator,"")!=0)
     {
      CExpertSignal *exit_signal=CSignalFactory::MakeSignal(Exit_Indicator,
                                                            Exit_int,Exit_double,
                                                            PERIOD_CURRENT,Exit_Shift);

      if(exit_signal==NULL)
        {
         //--- failed
         printf(__FUNCTION__+": error creating signal "+Exit_Indicator);
         ExtExpert.Deinit();
         return(INIT_FAILED);
        }
      signal.AddExitSignal(exit_signal);
      printf("Added Exit Indicator "+Exit_Indicator);
     }

 
// -------------- add baseline indicator --------------------------------   
   if(StringCompare(Baseline_Indicator,"")!=0)
     {
      CExpertSignal *baseline_signal=CSignalFactory::MakeSignal(Baseline_Indicator,
                                                                Baseline_int,Baseline_double,
                                                                PERIOD_CURRENT,Baseline_Shift);

      if(baseline_signal==NULL)
        {
         //--- failed
         printf(__FUNCTION__+": error creating signal "+Baseline_Indicator);
         ExtExpert.Deinit();
         return(INIT_FAILED);
        }
      signal.AddBaselineSignal(baseline_signal);
      printf("Added Baseline Indicator "+Baseline_Indicator);
     }
     
// -------------- add volume indicator --------------------------------   
   if(StringCompare(Volume_Indicator,"")!=0)
     {
      CExpertSignal *volume_signal=CSignalFactory::MakeSignal(Volume_Indicator,
                                                              Volume_int,Volume_double,
                                                              PERIOD_CURRENT,Volume_Shift);

      if(volume_signal==NULL)
        {
         //--- failed
         printf(__FUNCTION__+": error creating signal "+Volume_Indicator);
         ExtExpert.Deinit();
         return(INIT_FAILED);
        }
      signal.AddVolumeSignal(volume_signal);
      printf("Added Volume Indicator "+Volume_Indicator);
     }

//--- Creation of trailing object
   CTrailingNone *trailing=new CTrailingNone;
   if(trailing==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating trailing");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Add trailing to expert (will be deleted automatically))
   if(!ExtExpert.InitTrailing(trailing))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing trailing");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Set trailing parameters
//--- Creation of money object
   CMoneyFixedLot *money=new CMoneyFixedLot;
   if(money==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating money");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Add money to expert (will be deleted automatically))
   if(!ExtExpert.InitMoney(money))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing money");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Set money parameters
   money.Percent(Money_FixLot_Percent);
   money.Lots(Money_FixLot_Lots);
//--- Check all trading objects parameters
   if(!ExtExpert.ValidationSettings())
     {
      //--- failed
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Tuning of all necessary indicators
   if(!ExtExpert.InitIndicators())
     {
      //--- failed
      printf(__FUNCTION__+": error initializing indicators");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
    
    return INIT_SUCCEEDED;
}

//---------------------------------------------------------------------
//  The handler of the event of completion of another test pass:
//---------------------------------------------------------------------
double OnTester()
  {
// custom MAX: % take profit hit of all trades
// each trade opens 2 positions, one with tp and one without
// => half of the trades are considered
   if(!MQL5InfoInteger(MQL5_OPTIMIZATION)) {
      Print("Trades: ",TesterStatistics(STAT_TRADES));
      Print("SL hit: ",ExtExpert.StopLossCnt());
      Print("TP hit: ",ExtExpert.TakeProfitCnt());
      Print("profitable: ",TesterStatistics(STAT_PROFIT_TRADES));
      Print("%profitable: ",TesterStatistics(STAT_TRADES) == 0. ? 0.
          : TesterStatistics(STAT_PROFIT_TRADES)/TesterStatistics(STAT_TRADES));
      Print("Profit: ",TesterStatistics(STAT_PROFIT));
   }

   return(TesterStatistics(STAT_TRADES) == 0. ? 0.
          : ExtExpert.TakeProfitCnt()/(TesterStatistics(STAT_TRADES)/2));
   //return(TesterStatistics(STAT_TRADES) == 0. ? 0.
   //       : TesterStatistics(STAT_PROFIT_TRADES)/TesterStatistics(STAT_TRADES));
  }
//+------------------------------------------------------------------+
//| Deinitialization function of the expert                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ExtExpert.Deinit();
  }
//+------------------------------------------------------------------+
//| "Tick" event handler function                                    |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(Expert_EveryTick && !IsCandleAlmostClosed())
      return;

   /*
   CExpertSignal *signal=ExtExpert.Signal();
   
   double atr_value=m_atr.GetData(0,Expert_EveryTick ? 0 : 1);
//printf("ATR value: %f", atr_value);
// SYMBOL_DIGITS
   signal.StopLevel(atr_value*Signal_StopLevel/ExtExpert.PriceLevelUnit());

   if(StringCompare(Exit_Indicator,"")==0) // we don't have an exit inidicator. so we set a TP
     {
      // we're not testing for an exit indicator
      signal.TakeLevel(atr_value*Signal_TakeLevel/ExtExpert.PriceLevelUnit());
     }
     */
   ExtExpert.OnTick();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsCandleAlmostClosed()
  {
//static datetime last_tick,last_tick_server;
//static MqlDateTime  last_tick_struct,last_tick_server_struct;
   if(isNewBarCurrentChart.isNewBar())
     {
/*MqlDateTime new_tick_struct;
      datetime new_tick=TimeCurrent(new_tick_struct);
      Print("new candle: ",new_tick
            ,"(",new_tick_struct.day_of_week,")"
            ," previous closed: ",last_tick
            ,"(",last_tick_struct.day_of_week,")"
            ," server: ",last_tick_server
            ,"(",last_tick_server_struct.day_of_week,")");
            */
      CandleProcessed=false;
     }
//last_tick=TimeCurrent(last_tick_struct);
//last_tick_server=TimeTradeServer(last_tick_server_struct);
//   datetime lastbar_time=SeriesInfoInteger(Symbol(),Period(),SERIES_LASTBAR_DATE);
   int leftTime=PeriodSeconds(Period())
                -(int)(TimeCurrent()-isNewBarCurrentChart.GetLastBarTime());

   if(!CandleProcessed && leftTime<=Expert_ProcessOnTimeLeft)
     {
      Print("almose closed candle");
      CandleProcessed=true;
      return true;
     }
   return false;
  }
//+------------------------------------------------------------------+
//| "Trade" event handler function                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
   ExtExpert.OnTrade();
  }
//+------------------------------------------------------------------+
//| "Timer" event handler function                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   ExtExpert.OnTimer();
  }
//+------------------------------------------------------------------+

void SetupInputArrays()
  {
   Confirm_int[0] = Confirm_int0;
   Confirm_int[1] = Confirm_int1;
   Confirm_int[2] = Confirm_int2;
   Confirm_int[3] = Confirm_int3;
   Confirm_int[4] = Confirm_int4;
   Confirm_int[5] = Confirm_int5;
   Confirm_int[6] = Confirm_int6;
   Confirm_int[7] = Confirm_int7;
   Confirm_int[8] = Confirm_int8;
   Confirm_int[9] = Confirm_int9;
   Confirm_int[10] = Confirm_int10;
   Confirm_int[11] = Confirm_int11;
   Confirm_int[12] = Confirm_int12;
   Confirm_int[13] = Confirm_int13;
   Confirm_int[14] = Confirm_int14;
   Confirm_int[15] = Confirm_int15;
   Confirm_int[16] = Confirm_int16;
   Confirm_int[17] = Confirm_int17;
   Confirm_int[18] = Confirm_int18;
   Confirm_int[19] = Confirm_int19;
   Confirm_double[0] = Confirm_double0;
   Confirm_double[1] = Confirm_double1;
   Confirm_double[2] = Confirm_double2;
   Confirm_double[3] = Confirm_double3;
   Confirm_double[4] = Confirm_double4;
   Confirm_double[5] = Confirm_double5;
   Confirm_double[6] = Confirm_double6;
   Confirm_double[7] = Confirm_double7;
   Confirm_double[8] = Confirm_double8;
   Confirm_double[9] = Confirm_double9;


   Confirm2_int[0] = Confirm2_int0;
   Confirm2_int[1] = Confirm2_int1;
   Confirm2_int[2] = Confirm2_int2;
   Confirm2_int[3] = Confirm2_int3;
   Confirm2_int[4] = Confirm2_int4;
   Confirm2_int[5] = Confirm2_int5;
   Confirm2_int[6] = Confirm2_int6;
   Confirm2_int[7] = Confirm2_int7;
   Confirm2_int[8] = Confirm2_int8;
   Confirm2_int[9] = Confirm2_int9;
   Confirm2_int[10] = Confirm2_int10;
   Confirm2_int[11] = Confirm2_int11;
   Confirm2_int[12] = Confirm2_int12;
   Confirm2_int[13] = Confirm2_int13;
   Confirm2_int[14] = Confirm2_int14;
   Confirm2_int[15] = Confirm2_int15;
   Confirm2_int[16] = Confirm2_int16;
   Confirm2_int[17] = Confirm2_int17;
   Confirm2_int[18] = Confirm2_int18;
   Confirm2_int[19] = Confirm2_int19;
   Confirm2_double[0] = Confirm2_double0;
   Confirm2_double[1] = Confirm2_double1;
   Confirm2_double[2] = Confirm2_double2;
   Confirm2_double[3] = Confirm2_double3;
   Confirm2_double[4] = Confirm2_double4;
   Confirm2_double[5] = Confirm2_double5;
   Confirm2_double[6] = Confirm2_double6;
   Confirm2_double[7] = Confirm2_double7;
   Confirm2_double[8] = Confirm2_double8;
   Confirm2_double[9] = Confirm2_double9;

   Exit_int[0] = Exit_int0;
   Exit_int[1] = Exit_int1;
   Exit_int[2] = Exit_int2;
   Exit_int[3] = Exit_int3;
   Exit_int[4] = Exit_int4;
   Exit_int[5] = Exit_int5;
   Exit_int[6] = Exit_int6;
   Exit_int[7] = Exit_int7;
   Exit_int[8] = Exit_int8;
   Exit_int[9] = Exit_int9;
   Exit_int[10] = Exit_int10;
   Exit_int[11] = Exit_int11;
   Exit_int[12] = Exit_int12;
   Exit_int[13] = Exit_int13;
   Exit_int[14] = Exit_int14;
   Exit_int[15] = Exit_int15;
   Exit_int[16] = Exit_int16;
   Exit_int[17] = Exit_int17;
   Exit_int[18] = Exit_int18;
   Exit_int[19] = Exit_int19;
   Exit_double[0] = Exit_double0;
   Exit_double[1] = Exit_double1;
   Exit_double[2] = Exit_double2;
   Exit_double[3] = Exit_double3;
   Exit_double[4] = Exit_double4;
   Exit_double[5] = Exit_double5;
   Exit_double[6] = Exit_double6;
   Exit_double[7] = Exit_double7;
   Exit_double[8] = Exit_double8;
   Exit_double[9] = Exit_double9;
   
   Baseline_int[0] = Baseline_int0;
   Baseline_int[1] = Baseline_int1;
   Baseline_int[2] = Baseline_int2;
   Baseline_int[3] = Baseline_int3;
   Baseline_int[4] = Baseline_int4;
   Baseline_int[5] = Baseline_int5;
   Baseline_int[6] = Baseline_int6;
   Baseline_int[7] = Baseline_int7;
   Baseline_int[8] = Baseline_int8;
   Baseline_int[9] = Baseline_int9;
   Baseline_int[10] = Baseline_int10;
   Baseline_int[11] = Baseline_int11;
   Baseline_int[12] = Baseline_int12;
   Baseline_int[13] = Baseline_int13;
   Baseline_int[14] = Baseline_int14;
   Baseline_int[15] = Baseline_int15;
   Baseline_int[16] = Baseline_int16;
   Baseline_int[17] = Baseline_int17;
   Baseline_int[18] = Baseline_int18;
   Baseline_int[19] = Baseline_int19;
   Baseline_double[0] = Baseline_double0;
   Baseline_double[1] = Baseline_double1;
   Baseline_double[2] = Baseline_double2;
   Baseline_double[3] = Baseline_double3;
   Baseline_double[4] = Baseline_double4;
   Baseline_double[5] = Baseline_double5;
   Baseline_double[6] = Baseline_double6;
   Baseline_double[7] = Baseline_double7;
   Baseline_double[8] = Baseline_double8;
   Baseline_double[9] = Baseline_double9;
   
   Volume_int[0] = Volume_int0;
   Volume_int[1] = Volume_int1;
   Volume_int[2] = Volume_int2;
   Volume_int[3] = Volume_int3;
   Volume_int[4] = Volume_int4;
   Volume_int[5] = Volume_int5;
   Volume_int[6] = Volume_int6;
   Volume_int[7] = Volume_int7;
   Volume_int[8] = Volume_int8;
   Volume_int[9] = Volume_int9;
   Volume_int[10] = Volume_int10;
   Volume_int[11] = Volume_int11;
   Volume_int[12] = Volume_int12;
   Volume_int[13] = Volume_int13;
   Volume_int[14] = Volume_int14;
   Volume_int[15] = Volume_int15;
   Volume_int[16] = Volume_int16;
   Volume_int[17] = Volume_int17;
   Volume_int[18] = Volume_int18;
   Volume_int[19] = Volume_int19;
   Volume_double[0] = Volume_double0;
   Volume_double[1] = Volume_double1;
   Volume_double[2] = Volume_double2;
   Volume_double[3] = Volume_double3;
   Volume_double[4] = Volume_double4;
   Volume_double[5] = Volume_double5;
   Volume_double[6] = Volume_double6;
   Volume_double[7] = Volume_double7;
   Volume_double[8] = Volume_double8;
   Volume_double[9] = Volume_double9;
  }
//+------------------------------------------------------------------+
