//+------------------------------------------------------------------+
//|                                                      nnfx-ea.mq5 |
//|                                    Copyright 2019, Stefan Lendl. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Stefan Lendl."
#property version   "2.0"
//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Expert\Expert.mqh>
#include <Generic\HashMap.mqh>
#include <Generic\ArrayList.mqh>
#include <Arrays\ArrayString.mqh>
#include <Arrays\ArrayObj.mqh>
//--- available signals
#include "..\Signal\SignalFactory.mqh"
//--- available trailing
#include <Expert\Trailing\TrailingNone.mqh>
//--- available money management
#include <backtestd\Money\MoneyFixedRiskFixedBalance.mqh>
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
input string             Expert_Title         ="backtest_ea";    // Document name
ulong                    Expert_MagicNumber   =13876;       //
bool                     Expert_EveryTick     =false;       //
input int                Expert_ProcessOnTimeLeft=10*60;    // Time in seconds to run before the candle closes

//--- inputs for main signal
input int                Signal_ThresholdOpen=100;         // Signal threshold value to open
input int                Signal_ThresholdClose=10;          // Signal threshold value to close
input double             Signal_PriceLevel    =0.0;         // Price level to execute a deal
input double             Signal_StopLevel     =1.5;         // Stop Loss level ATR multiplier
input double             Signal_TakeLevel     =1.0;         // Take Profit level ATR multiplier
input int                Signal_Expiration    =1;           // Expiration of pending orders (in bars)
input int                Signal_Baseline_Wait = 7;          // candles for the baseline to wait for other indicators to catch up

datetime start_time = TimeCurrent();

/* input ENUM_BACKTEST_MODE Backtest_Mode=0x01;       // ENUM_BACKTEST_MODE  || Bit Flags */

//--- inputs for Confirmation Indicator
input string Confirm_Indicator="";  // Name of Confirmation Indicator to use
input ENUM_SIGNAL_CLASS Confirm_SignalClass=Unknown; // Type|Class of Indicator
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
input double Confirm_double10 = 0.;   // Confirm double input 10
input double Confirm_double11 = 0.;   // Confirm double input 11
input double Confirm_double12 = 0.;   // Confirm double input 12
input double Confirm_double13 = 0.;   // Confirm double input 13
input double Confirm_double14 = 0.;   // Confirm double input 14
double Confirm_double[15];
input uint Confirm_buffer0=0;
input uint Confirm_buffer1=0;
input uint Confirm_buffer2=0;
input uint Confirm_buffer3=0;
input uint Confirm_buffer4=0;
uint Confirm_buffer[5];
input double Confirm_param0=0.;
input double Confirm_param1=0.;
input double Confirm_param2=0.;
input double Confirm_param3=0.;
input double Confirm_param4=0.;
double Confirm_param[5];

input string Confirm2_Indicator="";  // Name of 2nd Confirmation Indicator to use
input ENUM_SIGNAL_CLASS Confirm2_SignalClass=Unknown; // Type|Class of Indicator
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
input double Confirm2_double10 = 0.;   // Confirm2 double input 10
input double Confirm2_double11 = 0.;   // Confirm2 double input 11
input double Confirm2_double12 = 0.;   // Confirm2 double input 12
input double Confirm2_double13 = 0.;   // Confirm2 double input 13
input double Confirm2_double14 = 0.;   // Confirm2 double input 14
double Confirm2_double[15];

input string Exit_Indicator="";  // Name of Exit Indicator to use
input ENUM_SIGNAL_CLASS Exit_SignalClass=Unknown; // Type|Class of Indicator
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
input double Exit_double10 = 0.;   // Exit double input 10
input double Exit_double11 = 0.;   // Exit double input 11
input double Exit_double12 = 0.;   // Exit double input 12
input double Exit_double13 = 0.;   // Exit double input 13
input double Exit_double14 = 0.;   // Exit double input 14
double Exit_double[15];

input string Baseline_Indicator="";  // Name of Baseline Indicator to use
input ENUM_SIGNAL_CLASS Baseline_SignalClass=Unknown; // Type|Class of Indicator
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
input double Baseline_double10 = 0.;   // Baseline double input 10
input double Baseline_double11 = 0.;   // Baseline double input 11
input double Baseline_double12 = 0.;   // Baseline double input 12
input double Baseline_double13 = 0.;   // Baseline double input 13
input double Baseline_double14 = 0.;   // Baseline double input 14
double Baseline_double[15];

input string Volume_Indicator="";  // Name of Volume Indicator to use
input ENUM_SIGNAL_CLASS Volume_SignalClass=Unknown; // Type|Class of Indicator
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
input double Volume_double10 = 0.;   // Volume double input 10
input double Volume_double11 = 0.;   // Volume double input 11
input double Volume_double12 = 0.;   // Volume double input 12
input double Volume_double13 = 0.;   // Volume double input 13
input double Volume_double14 = 0.;   // Volume double input 14
double Volume_double[15];

//--- inputs for money
input double             Money_Risk        = 1.0;         // Risk per trade (a regular entry has 2 trades.. x2 is the actual risk)
input double             Money_FixLot_Lots = 0.1;         // Fixed volume

input string Expert_symbol0 = "";
input string Expert_symbol1 = "";
input string Expert_symbol2 = "";
input string Expert_symbol3 = "";
input string Expert_symbol4 = "";
input string Expert_symbol5 = "";
input string Expert_symbol6 = "";
input string Expert_symbol7 = "";
input string Expert_symbol8 = "";
input string Expert_symbol9 = "";
input string Expert_symbol10 = "";
input string Expert_symbol11 = "";
input string Expert_symbol12 = "";
input string Expert_symbol13 = "";
input string Expert_symbol14 = "";
input string Expert_symbol15 = "";
input string Expert_symbol16 = "";
input string Expert_symbol17 = "";
input string Expert_symbol18 = "";
input string Expert_symbol19 = "";
input string Expert_symbol20 = "";
input string Expert_symbol21 = "";
input string Expert_symbol22 = "";
input string Expert_symbol23 = "";
input string Expert_symbol24 = "";
input string Expert_symbol25 = "";
input string Expert_symbol26 = "";
input string Expert_symbol27 = "";
input string Expert_symbol28 = "";
input string Expert_symbol29 = "";
input string Expert_symbol30 = "";
input string Expert_symbol31 = "";
input string Expert_symbol32 = "";
input string Expert_symbol33 = "";
input string Expert_symbol34 = "";
input string Expert_symbol35 = "";
input string Expert_symbol36 = "";
input string Expert_symbol37 = "";
input string Expert_symbol38 = "";
input string Expert_symbol39 = "";
input string Expert_symbol40 = "";
input string Expert_symbol41 = "";
input string Expert_symbol42 = "";
input string Expert_symbol43 = "";
input string Expert_symbol44 = "";
input string Expert_symbol45 = "";
input string Expert_symbol46 = "";
input string Expert_symbol47 = "";
input string Expert_symbol48 = "";
input string Expert_symbol49 = "";
string Expert_symbols[50];

//+------------------------------------------------------------------+
//| Global expert object                                             |
//+------------------------------------------------------------------+
CHashMap<string, int> ExpertsMap;
CArrayObj *Experts;
CisNewBar isNewBarCurrentChart;            // instance of the CisNewBar class: current chart
CArrayString symbols;
CArrayString currencies;
bool        CandleProcessed=false;

//+------------------------------------------------------------------+
//| Initialization function of the expert                            |
//+------------------------------------------------------------------+
int OnInit()
  {
   if (!SetupInputArrays())
      return(INIT_FAILED);

   Experts = new CArrayObj;
   for(int i=0; i<symbols.Total(); i++) {
      CBacktestExpert * expert = new CBacktestExpert;
      int ret;
      ret = InitExpert(GetPointer(expert) ,symbols.At(i));
      if (ret == INIT_SUCCEEDED)
         Experts.Add(expert);
      else
         return ret;  // break fail
   }

   return INIT_SUCCEEDED;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int InitExpert(CBacktestExpert *ExtExpert, string symbol)
  {
//--- Initializing expert
   if(!ExtExpert.Init(symbol,Period(),Expert_EveryTick,Expert_MagicNumber))
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
   if(!signal.AddAtr())
     {
      //--- failed
      printf(__FUNCTION__+": error creating ATR");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }


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
                                     Confirm_buffer,
                                     Confirm_param,
                                                            Confirm_SignalClass,
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
                                     Confirm_buffer,
                                     Confirm_param,
                                                                Confirm2_SignalClass,
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
                                     Confirm_buffer,
                                     Confirm_param,
                                                            Exit_SignalClass,
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
                                     Confirm_buffer,
                                     Confirm_param,
                                                                Baseline_SignalClass,
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
                                     Confirm_buffer,
                                     Confirm_param,
                                                              Volume_SignalClass,
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
   CMoneyFixedRiskFixedBalance *money=new CMoneyFixedRiskFixedBalance;
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
   money.Percent(Money_Risk);
   money.InitialBalance(TesterStatistics(STAT_INITIAL_DEPOSIT));
   // money.Lots(Money_FixLot_Lots);
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

   datetime stop_time = TimeCurrent();
   uint passed_bars = (stop_time - start_time) / PeriodSeconds();
   if ((TesterStatistics(STAT_TRADES) / Experts.Total()) < (passed_bars / 40)) {
      // we want a signal at least every 40 candles -> 6.5/year (5 days a week)
     return 0.0;
   }

   int tp_cnt = 0;
   int sl_cnt = 0;
    for(int i=0; i<Experts.Total(); i++) {
      CBacktestExpert *expert = Experts.At(i);
      tp_cnt += expert.TakeProfitCnt();
      sl_cnt += expert.StopLossCnt();
    }
   if(!MQL5InfoInteger(MQL5_OPTIMIZATION))
     {
      Print("Trades: ",TesterStatistics(STAT_TRADES));
      Print("SL hit: ",sl_cnt);
      Print("TP hit: ",tp_cnt);
      Print("profitable: ",TesterStatistics(STAT_PROFIT_TRADES));
      Print("%profitable: ",TesterStatistics(STAT_TRADES) == 0. ? 0.
            : TesterStatistics(STAT_PROFIT_TRADES)/TesterStatistics(STAT_TRADES));
      Print("Profit: ",TesterStatistics(STAT_PROFIT));
     }

   return(TesterStatistics(STAT_TRADES) == 0. ? 0.
          : tp_cnt/(TesterStatistics(STAT_TRADES)/2));
//return(TesterStatistics(STAT_TRADES) == 0. ? 0.
//       : TesterStatistics(STAT_PROFIT_TRADES)/TesterStatistics(STAT_TRADES));
  }
//+------------------------------------------------------------------+
//| Deinitialization function of the expert                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
    for(int i=0; i<Experts.Total(); i++) {
      CBacktestExpert *expert = Experts.At(i);
      expert.Deinit();
    }
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
    for(int i=0; i<Experts.Total(); i++) {
      CBacktestExpert *expert = Experts.At(i);
      expert.OnTick();
    }
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
    for(int i=0; i<Experts.Total(); i++) {
      CBacktestExpert *expert = Experts.At(i);
      expert.OnTrade();
    }
  }
//+------------------------------------------------------------------+
//| "Timer" event handler function                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
    for(int i=0; i<Experts.Total(); i++) {
      CBacktestExpert *expert = Experts.At(i);
      expert.OnTimer();
    }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SetupInputArrays()
  {
   // init Confirm2 indicator inputs and params
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
   Confirm_double[10] = Confirm_double10;
   Confirm_double[11] = Confirm_double11;
   Confirm_double[12] = Confirm_double12;
   Confirm_double[13] = Confirm_double13;
   Confirm_double[14] = Confirm_double14;

   Confirm_buffer[0] = Confirm_buffer0;
   Confirm_buffer[1] = Confirm_buffer1;
   Confirm_buffer[2] = Confirm_buffer2;
   Confirm_buffer[3] = Confirm_buffer3;
   Confirm_buffer[4] = Confirm_buffer4;

   Confirm_param[0] = Confirm_param0;
   Confirm_param[1] = Confirm_param1;
   Confirm_param[2] = Confirm_param2;
   Confirm_param[3] = Confirm_param3;
   Confirm_param[4] = Confirm_param4;

   // init Confirm2 indicator params
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
   Confirm2_double[10] = Confirm2_double10;
   Confirm2_double[11] = Confirm2_double11;
   Confirm2_double[12] = Confirm2_double12;
   Confirm2_double[13] = Confirm2_double13;
   Confirm2_double[14] = Confirm2_double14;

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
   Exit_double[10] = Exit_double10;
   Exit_double[11] = Exit_double11;
   Exit_double[12] = Exit_double12;
   Exit_double[13] = Exit_double13;
   Exit_double[14] = Exit_double14;

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
   Baseline_double[10] = Baseline_double10;
   Baseline_double[11] = Baseline_double11;
   Baseline_double[12] = Baseline_double12;
   Baseline_double[13] = Baseline_double13;
   Baseline_double[14] = Baseline_double14;

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
   Volume_double[10] = Volume_double10;
   Volume_double[11] = Volume_double11;
   Volume_double[12] = Volume_double12;
   Volume_double[13] = Volume_double13;
   Volume_double[14] = Volume_double14;

   Expert_symbols[0]  = Expert_symbol0;
   Expert_symbols[1]  = Expert_symbol1;
   Expert_symbols[2]  = Expert_symbol2;
   Expert_symbols[3]  = Expert_symbol3;
   Expert_symbols[4]  = Expert_symbol4;
   Expert_symbols[5]  = Expert_symbol5;
   Expert_symbols[6]  = Expert_symbol6;
   Expert_symbols[7]  = Expert_symbol7;
   Expert_symbols[8]  = Expert_symbol8;
   Expert_symbols[9]  = Expert_symbol9;
   Expert_symbols[10] = Expert_symbol10;
   Expert_symbols[11] = Expert_symbol11;
   Expert_symbols[12] = Expert_symbol12;
   Expert_symbols[13] = Expert_symbol13;
   Expert_symbols[14] = Expert_symbol14;
   Expert_symbols[15] = Expert_symbol15;
   Expert_symbols[16] = Expert_symbol16;
   Expert_symbols[17] = Expert_symbol17;
   Expert_symbols[18] = Expert_symbol18;
   Expert_symbols[19] = Expert_symbol19;
   Expert_symbols[20] = Expert_symbol20;
   Expert_symbols[21] = Expert_symbol21;
   Expert_symbols[22] = Expert_symbol22;
   Expert_symbols[23] = Expert_symbol23;
   Expert_symbols[24] = Expert_symbol24;
   Expert_symbols[25] = Expert_symbol25;
   Expert_symbols[26] = Expert_symbol26;
   Expert_symbols[27] = Expert_symbol27;
   Expert_symbols[28] = Expert_symbol28;
   Expert_symbols[29] = Expert_symbol29;
   Expert_symbols[30] = Expert_symbol30;
   Expert_symbols[31] = Expert_symbol31;
   Expert_symbols[32] = Expert_symbol32;
   Expert_symbols[33] = Expert_symbol33;
   Expert_symbols[34] = Expert_symbol34;
   Expert_symbols[35] = Expert_symbol35;
   Expert_symbols[36] = Expert_symbol36;
   Expert_symbols[37] = Expert_symbol37;
   Expert_symbols[38] = Expert_symbol38;
   Expert_symbols[39] = Expert_symbol39;
   Expert_symbols[40] = Expert_symbol40;
   Expert_symbols[41] = Expert_symbol41;
   Expert_symbols[42] = Expert_symbol42;
   Expert_symbols[43] = Expert_symbol43;
   Expert_symbols[44] = Expert_symbol44;
   Expert_symbols[45] = Expert_symbol45;
   Expert_symbols[46] = Expert_symbol46;
   Expert_symbols[47] = Expert_symbol47;
   Expert_symbols[48] = Expert_symbol48;
   Expert_symbols[49] = Expert_symbol49;

   // pre-sort to allow InsertSort
   symbols.Sort();
   currencies.Sort();
   if (StringLen(Expert_symbols[0]) == 0)
     // no symbols configured .. only set currenty Symbol()
     Expert_symbols[0] = Symbol();

   for (int i=0; i<ArraySize(Expert_symbols); i++) {
      if (StringLen(Expert_symbols[i]) == 0)
         break;

      if(!symbols.InsertSort(Expert_symbols[i])) {
         Print("insert Symbol failed");
         return(false);
      }

      // this asserts that currencies have 3 letters!!
      string cur[2];
      cur[0] = StringSubstr(Expert_symbols[i], 0, 3);
      cur[1] = StringSubstr(Expert_symbols[i], 3, -1);

      for(int j=0; j<2; j++) {
         if(currencies.Search(cur[j])==-1) {
            if (!currencies.InsertSort(cur[j])) {
              Print("insert currency failed");
              return(false);
            }
         }
      }
   }

#ifdef _DEBUG
   if( !MQL5InfoInteger(MQL5_OPTIMIZATION)) {
      for(int n=0; n<symbols.Total(); n++) {
         PrintFormat("symbols[%d]=\"%s\"",n,symbols.At(n));
      }
      for(int n=0; n<currencies.Total(); n++) {
         PrintFormat("currencies[%d]=\"%s\"",n,currencies.At(n));
      }
   }
#endif

  return true;
  }
//+------------------------------------------------------------------+
