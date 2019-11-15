//+------------------------------------------------------------------+
//|                                                      nnfx-ea.mq5 |
//|                                    Copyright 2019, Stefan Lendl. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Stefan Lendl."
#property version   "1.0"
//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Expert\Expert.mqh>
//--- available signals
#include "..\Signal\SignalFactory.mqh"
//--- available trailing
#include <Expert\Trailing\TrailingNone.mqh>
//--- available money management
#include <Expert\Money\MoneyFixedLot.mqh>
#include "..\NewBar\CisNewBar.mqh"
#include "..\Signal\AggSignal.mqh"
#include "..\Expert\BacktestExpert.mqh"

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
CBacktestExpert ExtExpert;
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
   CAggSignal *signal=new CAggSignal;
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
   CCustomSignal *confirm_signal=CSignalFactory::MakeSignal(Confirm_Indicator,
                                                            Confirm_double,
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
      CCustomSignal *confirm2_signal=CSignalFactory::MakeSignal(Confirm2_Indicator,
                                                                Confirm2_double,
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
      CCustomSignal *exit_signal=CSignalFactory::MakeSignal(Exit_Indicator,
                                                            Exit_double,
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
      CCustomSignal *baseline_signal=CSignalFactory::MakeSignal(Baseline_Indicator,
                                                                Baseline_double,
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
      CCustomSignal *volume_signal=CSignalFactory::MakeSignal(Volume_Indicator,
                                                              Volume_double,
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
