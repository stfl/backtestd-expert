//+------------------------------------------------------------------+
//|                                                      nnfx-ea.mq5 |
//|                                    Copyright 2019, Stefan Lendl. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Stefan Lendl."
#property version "1.2"
//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Arrays\ArrayObj.mqh>
#include <Arrays\ArrayString.mqh>
#include <Expert\Expert.mqh>
#include <Generic\ArrayList.mqh>
#include <Generic\HashMap.mqh>
#include <Math\Stat\Math.mqh>
//--- available signals
#include <backtestd\SignalClass\SignalFactory.mqh>
//--- available trailing
#include <Expert\Trailing\TrailingNone.mqh>
#include <Expert\Trailing\TrailingFixedPips.mqh>
#include <backtestd\Trailing\TrailingAtr.mqh>
//--- available money management
#include <NewBar\CisNewBar.mqh>
#include <backtestd\Expert\BacktestExpert.mqh>
#include <backtestd\Money\MoneyFixedRiskFixedBalance.mqh>
#include <Expert\Money\MoneyFixedRisk.mqh>
#include <backtestd\SignalClass\AggSignal.mqh>

#include <Database\DatabaseFrames.mqh>

#ifdef MUTEX
#include <Mutex/Mutex.mqh>
#endif

#define CheckPointerOrAbort(ptr)                     \
if (ptr == NULL) {                                    \
   printf(__FUNCTION__ + ": error creating ##ptr");   \
   ExtExpert.Deinit();                                \
   return (INIT_FAILED);                              \
}

#define CallCheckedOrAbort(function)                   \
if(!function) {                                        \
   printf(__FUNCTION__ + ": error calling ##function");\
   ExtExpert.Deinit();                                 \
   return (INIT_FAILED);                               \
}

enum STORE_RESULTS {
    None = 0,
    SideChanges = 1,
    //Buffers = 2,  // Really slow
    //Results = 3   // TODO
    //Trades = 3    // TODO should be easier than SideChanges
};

enum TRAILING_MODE {
    NoTrail   = 0,
    ATRTrail  = 1,
    // ATRTrailDelay   = 2,
};

enum CUSTOM_METRIC {
    Metric_WinRate     = 0,  // TP hits/Total Trades ratio
    Metric_CVaR        = 1,  //
    Metric_VaR         = 2,  // Value at Risk
    // Metric_CalmarRatio = 3,  // Calmar Ratio
};

struct BACKTEST_MODE_CONFIG {
   bool take_profit;
   bool scale_out;
   TRAILING_MODE trailing_mode;
   CUSTOM_METRIC metric;
};

// Define the default metrics
BACKTEST_MODE_CONFIG Backtest_ModeConfigs[] = {
   // tp  ,so   ,trail        ,metric
    {false,false,NoTrail      ,Metric_CVaR},     // Full
    {true ,false,NoTrail      ,Metric_WinRate},  // TakeProfit
    {false,false,ATRTrail     ,Metric_CVaR},     // Trail
    // {false,false,ATRTrailDelay,Metric_CVaR},     // TrailDelay       = 3, // Trailing Stop after certain distance from Entry
    // {true ,true ,ATRTrailDelay,Metric_CVaR},     // ScaleOut         = 4, // Scale out -> Take off half of the trade at TP level
};

// A definition of the some backtest presets
enum BACKTEST_MODE {
    Full             = 0, // A full trade without Take Profit
    TakeProfit       = 1, // Take Profit based on ATR, Calculate Win Rate
    Trail            = 2, // Trailing Stop, no Take Profit
    // TrailDelay       = 3, // Trailing Stop after certain distance from Entry
    // ScaleOut         = 4, // Scale out -> Take off half of the trade at TP level
    Manual           = -1, // Manual configuration (No Preset)
};

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
//--- inputs for expert
input string Expert_Title = "backtestd-expert"; // Document name
ulong Expert_MagicNumber = 13876;               //
bool Expert_EveryTick = false;                  //
input int Expert_ProcessOnTimeLeft = 10 * 60; // Time in seconds to run before the candle closes

//input
STORE_RESULTS Expert_Store_Results = None;  // TODO this is probably commented out somewhere

input int Signal_Expiration = 1;     // Expiration of pending orders (in bars)

input BACKTEST_MODE Backtest_ModeSelect = Manual; // Backtest Trading Preset
input CUSTOM_METRIC Input_Backtest_Metric = Metric_CVaR;
CUSTOM_METRIC Backtest_Metric = Input_Backtest_Metric;
input double Backtest_Metric_VaR_Quantile = 0.8;  // Quantile for VaR | CVaR

//input
bool Backtest_TPOnAllTrades = false; // set a TP on both trades
//input
bool Backtest_SingleTrade = true; // use only a single trade
//input
bool Input_Money_ScaleOut = false;
bool Money_ScaleOut = Input_Money_ScaleOut;
input bool Input_Money_AddTakeProfit = false; // set a TP on the trade
bool Money_AddTakeProfit = Input_Money_AddTakeProfit; // set a TP on the trade

//--- Money Management
input double Money_Risk = 2.0;           // Risk per trade
// input double Money_FixLot_Lots = 0.1; // Fixed volume
input double Money_StopLevel = 1.5;     // Stop Loss level ATR multiplier
input double Money_TakeLevel = 1.0;     // Take Profit level ATR multiplier

input TRAILING_MODE Input_Money_TrailingMode = ATRTrail;    // Trailing Stop Mode
TRAILING_MODE Money_TrailingMode = Input_Money_TrailingMode;
input double Money_TrailingStopATRLevel = 2.5; // Distance of the trailing stop ATR multiplier
//input
int Money_TrailAtrPeriod = 14;

// Algo customizations
input int Algo_BaselineWait = 7; // candles for the baseline to wait for other indicators to catch up


//--- inputs for Confirmation Indicator
input string Confirm_Indicator = ""; // Name of Confirmation Indicator to use
input ENUM_SIGNAL_CLASS Confirm_SignalClass = Preset; // Type|Class of Indicator
input uint Confirm_Shift = 0;                         // Shift in Bars
input double Confirm_input0 = 0.;                     // Confirm input 0
input double Confirm_input1 = 0.;                     // Confirm input 1
input double Confirm_input2 = 0.;                     // Confirm input 2
input double Confirm_input3 = 0.;                     // Confirm input 3
input double Confirm_input4 = 0.;                     // Confirm input 4
input double Confirm_input5 = 0.;                     // Confirm input 5
input double Confirm_input6 = 0.;                     // Confirm input 6
input double Confirm_input7 = 0.;                     // Confirm input 7
input double Confirm_input8 = 0.;                     // Confirm input 8
input double Confirm_input9 = 0.;                     // Confirm input 9
input double Confirm_input10 = 0.;                    // Confirm input 10
input double Confirm_input11 = 0.;                    // Confirm input 11
input double Confirm_input12 = 0.;                    // Confirm input 12
input double Confirm_input13 = 0.;                    // Confirm input 13
input double Confirm_input14 = 0.;                    // Confirm input 14
double Confirm_inputs[15];
input int Confirm_buffer0 = -1;
input int Confirm_buffer1 = -1;
input int Confirm_buffer2 = -1;
input int Confirm_buffer3 = -1;
input int Confirm_buffer4 = -1;
uint Confirm_buffer[5];
input double Confirm_param0 = 0.;
input double Confirm_param1 = 0.;
input double Confirm_param2 = 0.;
input double Confirm_param3 = 0.;
input double Confirm_param4 = 0.;
double Confirm_param[5];

input string Confirm2_Indicator = ""; // Name of 2nd Confirmation Indicator to use
input ENUM_SIGNAL_CLASS Confirm2_SignalClass = Preset;   // Type|Class of Indicator
input uint Confirm2_Shift = 0;      // Confirm2 Shift in Bars
input double Confirm2_input0 = 0.;  // Confirm2 input 0
input double Confirm2_input1 = 0.;  // Confirm2 input 1
input double Confirm2_input2 = 0.;  // Confirm2 input 2
input double Confirm2_input3 = 0.;  // Confirm2 input 3
input double Confirm2_input4 = 0.;  // Confirm2 input 4
input double Confirm2_input5 = 0.;  // Confirm2 input 5
input double Confirm2_input6 = 0.;  // Confirm2 input 6
input double Confirm2_input7 = 0.;  // Confirm2 input 7
input double Confirm2_input8 = 0.;  // Confirm2 input 8
input double Confirm2_input9 = 0.;  // Confirm2 input 9
input double Confirm2_input10 = 0.; // Confirm2 input 10
input double Confirm2_input11 = 0.; // Confirm2 input 11
input double Confirm2_input12 = 0.; // Confirm2 input 12
input double Confirm2_input13 = 0.; // Confirm2 input 13
input double Confirm2_input14 = 0.; // Confirm2 input 14
double Confirm2_inputs[15];
input int Confirm2_buffer0 = -1;
input int Confirm2_buffer1 = -1;
input int Confirm2_buffer2 = -1;
input int Confirm2_buffer3 = -1;
input int Confirm2_buffer4 = -1;
uint Confirm2_buffer[5];
input double Confirm2_param0 = 0.;
input double Confirm2_param1 = 0.;
input double Confirm2_param2 = 0.;
input double Confirm2_param3 = 0.;
input double Confirm2_param4 = 0.;
double Confirm2_param[5];

input string Exit_Indicator = ""; // Name of Exit Indicator to use
input ENUM_SIGNAL_CLASS Exit_SignalClass = Preset; // Type|Class of Indicator
input uint Exit_Shift = 0;                         // Exit Shift in Bars
input double Exit_input0 = 0.;                     // Exit input 0
input double Exit_input1 = 0.;                     // Exit input 1
input double Exit_input2 = 0.;                     // Exit input 2
input double Exit_input3 = 0.;                     // Exit input 3
input double Exit_input4 = 0.;                     // Exit input 4
input double Exit_input5 = 0.;                     // Exit input 5
input double Exit_input6 = 0.;                     // Exit input 6
input double Exit_input7 = 0.;                     // Exit input 7
input double Exit_input8 = 0.;                     // Exit input 8
input double Exit_input9 = 0.;                     // Exit input 9
input double Exit_input10 = 0.;                    // Exit input 10
input double Exit_input11 = 0.;                    // Exit input 11
input double Exit_input12 = 0.;                    // Exit input 12
input double Exit_input13 = 0.;                    // Exit input 13
input double Exit_input14 = 0.;                    // Exit input 14
double Exit_inputs[15];
input int Exit_buffer0 = -1;
input int Exit_buffer1 = -1;
input int Exit_buffer2 = -1;
input int Exit_buffer3 = -1;
input int Exit_buffer4 = -1;
uint Exit_buffer[5];
input double Exit_param0 = 0.;
input double Exit_param1 = 0.;
input double Exit_param2 = 0.;
input double Exit_param3 = 0.;
input double Exit_param4 = 0.;
double Exit_param[5];

input string Baseline_Indicator = ""; // Name of Baseline Indicator to use
input ENUM_SIGNAL_CLASS Baseline_SignalClass = Preset; // Type|Class of Indicator
input uint Baseline_Shift = 0;      // Baseline Shift in Bars
input double Baseline_input0 = 0.;  // Baseline input 0
input double Baseline_input1 = 0.;  // Baseline input 1
input double Baseline_input2 = 0.;  // Baseline input 2
input double Baseline_input3 = 0.;  // Baseline input 3
input double Baseline_input4 = 0.;  // Baseline input 4
input double Baseline_input5 = 0.;  // Baseline input 5
input double Baseline_input6 = 0.;  // Baseline input 6
input double Baseline_input7 = 0.;  // Baseline input 7
input double Baseline_input8 = 0.;  // Baseline input 8
input double Baseline_input9 = 0.;  // Baseline input 9
input double Baseline_input10 = 0.; // Baseline input 10
input double Baseline_input11 = 0.; // Baseline input 11
input double Baseline_input12 = 0.; // Baseline input 12
input double Baseline_input13 = 0.; // Baseline input 13
input double Baseline_input14 = 0.; // Baseline input 14
double Baseline_inputs[15];
input int Baseline_buffer0 = -1;
input int Baseline_buffer1 = -1;
input int Baseline_buffer2 = -1;
input int Baseline_buffer3 = -1;
input int Baseline_buffer4 = -1;
uint Baseline_buffer[5];
input double Baseline_param0 = 0.;
input double Baseline_param1 = 0.;
input double Baseline_param2 = 0.;
input double Baseline_param3 = 0.;
input double Baseline_param4 = 0.;
double Baseline_param[5];

input string Volume_Indicator = ""; // Name of Volume Indicator to use
input ENUM_SIGNAL_CLASS Volume_SignalClass = Preset; // Type|Class of Indicator
input uint Volume_Shift = 0;                         // Volume Shift in Bars
input double Volume_input0 = 0.;                     // Volume input 0
input double Volume_input1 = 0.;                     // Volume input 1
input double Volume_input2 = 0.;                     // Volume input 2
input double Volume_input3 = 0.;                     // Volume input 3
input double Volume_input4 = 0.;                     // Volume input 4
input double Volume_input5 = 0.;                     // Volume input 5
input double Volume_input6 = 0.;                     // Volume input 6
input double Volume_input7 = 0.;                     // Volume input 7
input double Volume_input8 = 0.;                     // Volume input 8
input double Volume_input9 = 0.;                     // Volume input 9
input double Volume_input10 = 0.;                    // Volume input 10
input double Volume_input11 = 0.;                    // Volume input 11
input double Volume_input12 = 0.;                    // Volume input 12
input double Volume_input13 = 0.;                    // Volume input 13
input double Volume_input14 = 0.;                    // Volume input 14
double Volume_inputs[15];
input int Volume_buffer0 = -1;
input int Volume_buffer1 = -1;
input int Volume_buffer2 = -1;
input int Volume_buffer3 = -1;
input int Volume_buffer4 = -1;
uint Volume_buffer[5];
input double Volume_param0 = 0.;
input double Volume_param1 = 0.;
input double Volume_param2 = 0.;
input double Volume_param3 = 0.;
input double Volume_param4 = 0.;
double Volume_param[5];

input string Continue_Indicator = ""; // Name of Continue Indicator to use
input ENUM_SIGNAL_CLASS Continue_SignalClass = Preset; // Type|Class of Indicator
input uint Continue_Shift = 0;                         // Continue Shift in Bars
input double Continue_input0 = 0.;                     // Continue input 0
input double Continue_input1 = 0.;                     // Continue input 1
input double Continue_input2 = 0.;                     // Continue input 2
input double Continue_input3 = 0.;                     // Continue input 3
input double Continue_input4 = 0.;                     // Continue input 4
input double Continue_input5 = 0.;                     // Continue input 5
input double Continue_input6 = 0.;                     // Continue input 6
input double Continue_input7 = 0.;                     // Continue input 7
input double Continue_input8 = 0.;                     // Continue input 8
input double Continue_input9 = 0.;                     // Continue input 9
input double Continue_input10 = 0.;                    // Continue input 10
input double Continue_input11 = 0.;                    // Continue input 11
input double Continue_input12 = 0.;                    // Continue input 12
input double Continue_input13 = 0.;                    // Continue input 13
input double Continue_input14 = 0.;                    // Continue input 14
double Continue_inputs[15];
input int Continue_buffer0 = -1;
input int Continue_buffer1 = -1;
input int Continue_buffer2 = -1;
input int Continue_buffer3 = -1;
input int Continue_buffer4 = -1;
uint Continue_buffer[5];
input double Continue_param0 = 0.;
input double Continue_param1 = 0.;
input double Continue_param2 = 0.;
input double Continue_param3 = 0.;
input double Continue_param4 = 0.;
double Continue_param[5];

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
CisNewBar isNewBarCurrentChart; // instance of the CisNewBar class: current chart
CArrayString symbols;
CArrayString currencies;
bool CandleProcessed = false;

CDatabaseFrames DB_Frames;
ulong frames_received = 1;

#ifdef MUTEX
CMutexSync mutex;
#endif

datetime frame_time;
bool started_storing = false;

//+------------------------------------------------------------------+
//| Initialization function of the expert                            |
//+------------------------------------------------------------------+
int OnInit() {
  if (!SetupInputArrays())
    return (INIT_FAILED);

  SetupBacktestPreset();

  Experts = new CArrayObj;
  for (int i = 0; i < symbols.Total(); i++) {
    CBacktestExpert *expert = new CBacktestExpert;
    int ret;
    ret = InitExpert(GetPointer(expert), symbols.At(i));
    if (ret == INIT_SUCCEEDED)
      Experts.Add(expert);
    else
      return ret; // break fail
  }

  return INIT_SUCCEEDED;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int InitExpert(CBacktestExpert *ExtExpert, string symbol) {
  //--- Initializing expert
  if (!ExtExpert.Init(symbol, Period(), Expert_EveryTick, Expert_MagicNumber)) {
    //--- failed
    printf(__FUNCTION__ + ": error initializing expert");
    ExtExpert.Deinit();
    return (INIT_FAILED);
  }

  // configure Money Management object
  ExtExpert.OnTradeProcess(true);
  ExtExpert.StopAtrMultiplier(Money_StopLevel);
  // do not set a take profit if we're only testing on a single trade
  double take_level = (Money_AddTakeProfit == true) ? Money_TakeLevel : 0.0;
  ExtExpert.TakeAtrMultiplier(take_level);

  // get the AggSignal from the Expert (It has been automatically created at Init())
  CAggSignal *signal = ExtExpert.Signal();
  signal.Expiration(Signal_Expiration);
  if (!signal.AddAtr()) {
    //--- failed
    printf(__FUNCTION__ + ": error creating ATR");
    ExtExpert.Deinit();
    return (INIT_FAILED);
  }

  // -------------- add confirmation indicator
  if (StringCompare(Confirm_Indicator, "") != 0) {
     CCustomSignal *confirm_signal = CSignalFactory::MakeSignal(
         Confirm_Indicator, Confirm_inputs, Confirm_buffer, Confirm_param,
         Confirm_SignalClass, PERIOD_CURRENT, Confirm_Shift);
   
     if (confirm_signal == NULL) {
       //--- failed
       printf(__FUNCTION__ + ": error creating signal " + Confirm_Indicator);
       ExtExpert.Deinit();
       return (INIT_FAILED);
     }
     signal.AddConfirmSignal(confirm_signal);
     printf("Added Confirmation Indicator " + Confirm_Indicator);
  }

  // -------------- add 2nd confirmation indicator -----------------------------
  if (StringCompare(Confirm2_Indicator, "") != 0) {
    CCustomSignal *confirm2_signal = CSignalFactory::MakeSignal(
        Confirm2_Indicator, Confirm2_inputs, Confirm2_buffer, Confirm2_param,
        Confirm2_SignalClass, PERIOD_CURRENT, Confirm2_Shift);

    if (confirm2_signal == NULL) {
      //--- failed
      printf(__FUNCTION__ + ": error creating signal " + Confirm2_Indicator);
      ExtExpert.Deinit();
      return (INIT_FAILED);
    }
    signal.AddConfirm2Signal(confirm2_signal);
    printf("Added 2nd Confirmation Indicator " + Confirm2_Indicator);
  }

  // -------------- add exit indicator --------------------------------
  if (StringCompare(Exit_Indicator, "") != 0) {
    CCustomSignal *exit_signal = CSignalFactory::MakeSignal(
        Exit_Indicator, Exit_inputs, Exit_buffer, Exit_param, Exit_SignalClass,
        PERIOD_CURRENT, Exit_Shift);

    if (exit_signal == NULL) {
      //--- failed
      printf(__FUNCTION__ + ": error creating signal " + Exit_Indicator);
      ExtExpert.Deinit();
      return (INIT_FAILED);
    }
    signal.AddExitSignal(exit_signal);
    printf("Added Exit Indicator " + Exit_Indicator);
  }

  // -------------- add baseline indicator --------------------------------
  if (StringCompare(Baseline_Indicator, "") != 0) {
    CCustomSignal *baseline_signal = CSignalFactory::MakeSignal(
        Baseline_Indicator, Baseline_inputs, Baseline_buffer, Baseline_param,
        Baseline_SignalClass, PERIOD_CURRENT, Baseline_Shift);

    if (baseline_signal == NULL) {
      //--- failed
      printf(__FUNCTION__ + ": error creating signal " + Baseline_Indicator);
      ExtExpert.Deinit();
      return (INIT_FAILED);
    }
    signal.AddBaselineSignal(baseline_signal);
    printf("Added Baseline Indicator " + Baseline_Indicator);
  }

  // -------------- add volume indicator --------------------------------
  if (StringCompare(Volume_Indicator, "") != 0) {
    CCustomSignal *volume_signal = CSignalFactory::MakeSignal(
        Volume_Indicator, Volume_inputs, Volume_buffer, Volume_param,
        Volume_SignalClass, PERIOD_CURRENT, Volume_Shift);

    if (volume_signal == NULL) {
      //--- failed
      printf(__FUNCTION__ + ": error creating signal " + Volume_Indicator);
      ExtExpert.Deinit();
      return (INIT_FAILED);
    }
    signal.AddVolumeSignal(volume_signal);
    printf("Added Volume Indicator " + Volume_Indicator);
  }

  // -------------- add continue indicator --------------------------------
  if (StringCompare(Continue_Indicator, "") != 0) {
    CCustomSignal *continue_signal = CSignalFactory::MakeSignal(
        Continue_Indicator, Continue_inputs, Continue_buffer, Continue_param,
        Continue_SignalClass, PERIOD_CURRENT, Continue_Shift);

    if (continue_signal == NULL) {
      //--- failed
      printf(__FUNCTION__ + ": error creating signal " + Continue_Indicator);
      ExtExpert.Deinit();
      return (INIT_FAILED);
    }
    signal.AddContinueSignal(continue_signal);
    printf("Added Continue Indicator " + Continue_Indicator);
  }

  //--- Creation of trailing object
  CExpertTrailing *trailing = NULL;
  switch (Money_TrailingMode) {
     case NoTrail:
        trailing = new CTrailingNone;  // init with default values which will be changed later
        CheckPointerOrAbort(trailing);
     break;
     case ATRTrail:
        trailing = new CTrailingAtr(Money_TrailingStopATRLevel, Money_TrailAtrPeriod);  // init with default values which will be changed later
        CheckPointerOrAbort(trailing);
        //dynamic_cast<CTrailingFixedPips *>(trailing).ProfitLevel(0);
     break;
  }

  CallCheckedOrAbort(ExtExpert.InitTrailing(trailing));

  //--- Set trailing parameters
  //--- Creation of money object
  CMoneyFixedRisk *money = new CMoneyFixedRisk;
  if (money == NULL) {
    //--- failed
    printf(__FUNCTION__ + ": error creating money");
    ExtExpert.Deinit();
    return (INIT_FAILED);
  }
  //--- Add money to expert (will be deleted automatically))
  if (!ExtExpert.InitMoney(money)) {
    //--- failed
    printf(__FUNCTION__ + ": error initializing money");
    ExtExpert.Deinit();
    return (INIT_FAILED);
  }
  //--- Set money parameters
  money.Percent(Money_Risk);
  // money.InitialBalance(TesterStatistics(STAT_INITIAL_DEPOSIT));
  // money.Lots(Money_FixLot_Lots);
  //--- Check all trading objects parameters
  if (!ExtExpert.ValidationSettings()) {
    //--- failed
    ExtExpert.Deinit();
    return (INIT_FAILED);
  }
  //--- Tuning of all necessary indicators
  if (!ExtExpert.InitIndicators()) {
    //--- failed
    printf(__FUNCTION__ + ": error initializing indicators");
    ExtExpert.Deinit();
    return (INIT_FAILED);
  }

  return INIT_SUCCEEDED;
}

//---------------------------------------------------------------------
//  The handler of the event of completion of another test pass:
//---------------------------------------------------------------------
double OnTester() {
  /*
  if (Expert_Store_Results == SideChanges) {
    CBacktestExpert *expert = Experts.At(0);
    expert.m_signal.m_confirm.AddSideChangesToFrame();
  }
  */

  switch (Backtest_Metric) {
        case Metric_VaR:
           return CalculateVaR(Backtest_Metric_VaR_Quantile);
        break;
        case Metric_CVaR:
           return CalculateCVaR(Backtest_Metric_VaR_Quantile);
        break;
        case Metric_WinRate:
           return CalculateWinRate();
        break;
        // case Metric_CalmarRatio:
        //    return CalculateCalmarRatio();
        // break;

     }
   return 0.0;
}

// NOTE write sides to csv
// void OnTesterDeinit(void) {
//    string        name;
//    ulong         pass;
//    long          id;
//    double        value;
//    datetime        date[];

//    string filename = "test.csv";
//    int file_handle=FileOpen(filename,FILE_READ|FILE_WRITE|FILE_CSV);
//    if(file_handle!=INVALID_HANDLE) {
//       FileWrite(file_handle, "symbol", "pass", "func", "date", "value");

//       FrameFirst();
//       // FrameFilter("", 0); // select frames with trading statistics for further work
//       while(FrameNext(pass, name, id, value, date)) {
//          PrintFormat("%s file is available for writing",filename);
//          PrintFormat("File path: %s\\Files\\",TerminalInfoString(TERMINAL_DATA_PATH));
//          FileWrite(file_handle, name, pass, id, (datetime) date[0], (int) value);
//          //--- close the file
//          PrintFormat("Data is written, %s file is closed",filename);
//       }
//       FileClose(file_handle);
//    }
//    else {
//       PrintFormat("Failed to open %s file, Error code = %d",filename,GetLastError());
//    }
// }

// NOTE write indi buffer values to csv
// void OnTesterDeinit(void) {
//    string        sybmol;
//    ulong         pass;
//    long          id;
//    double        value;
//    double        indi_buf[];

//    string filename = "test.csv";
//    int file_handle=FileOpen(filename,FILE_READ|FILE_WRITE|FILE_CSV);
//    if(file_handle!=INVALID_HANDLE) {
//       FileWrite(file_handle, "symbol", "pass", "func", "buf idx", "value");

//       FrameFirst();
//       // FrameFilter("", 0); // select frames with trading statistics for further work
//       while(FrameNext(pass, name, id, value, indi_buf)) {
//          PrintFormat("%s file is available for writing",filename);
//          PrintFormat("File path: %s\\Files\\",TerminalInfoString(TERMINAL_DATA_PATH));
//          for(int i=0;i<ArraySize(indi_buf);i++)
//             FileWrite(file_handle, symbol, pass, id, (uint) value, indi_buf[i]);
//          //--- close the file
//          PrintFormat("Data is written, %s file is closed",filename);
//       }
//       FileClose(file_handle);
//    }
//    else {
//       PrintFormat("Failed to open %s file, Error code = %d",filename,GetLastError());
//    }

// }

int OnTesterInit() {
   if (Expert_Store_Results == SideChanges) {
      // init the mutex with 0
      // if (!mutex.Create("Local\\" + Expert_Title)) {
      //    Print(__FUNCTION__, "MutexSync create ERROR!");
      //    return false;
      // }
      // Print(__FUNCTION__, "MutexSync created OK!");

      frame_time = TimeLocal();
      return(DB_Frames.OnTesterInit());
   }
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| "Timer" event handler function                                   |
//+------------------------------------------------------------------+
void OnTimer() {
  // for (int i = 0; i < Experts.Total(); i++) {
  //   CBacktestExpert *expert = Experts.At(i);
  //   expert.OnTimer();
  // }
}

void OnTesterDeinit() {
  // Print("OnTesterDeinit");
  if (Expert_Store_Results == SideChanges) {
     // CMutexLock lock(mutex, (DWORD)INFINITE);
     DB_Frames.StoreSideChangesArray(-1);
  }
}


//+------------------------------------------------------------------+
//| Deinitialization function of the expert                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
  for (int i = 0; i < Experts.Total(); i++) {
    CBacktestExpert *expert = Experts.At(i);
    expert.Deinit();
  }
}
//+------------------------------------------------------------------+
//| "Tick" event handler function                                    |
//+------------------------------------------------------------------+
void OnTick() {
  if (Expert_EveryTick && !IsCandleAlmostClosed())
    return;

  /*
  CExpertSignal *signal=ExtExpert.Signal();

  double atr_value=m_atr.GetData(0,Expert_EveryTick ? 0 : 1);
  //printf("ATR value: %f", atr_value);
  // SYMBOL_DIGITS
  signal.StopLevel(atr_value*Signal_StopLevel/ExtExpert.PriceLevelUnit());

  if(StringCompare(Exit_Indicator,"")==0) // we don't have an exit inidicator.
  so we set a TP
    {
     // we're not testing for an exit indicator
     signal.TakeLevel(atr_value*Signal_TakeLevel/ExtExpert.PriceLevelUnit());
    }
    */
  for (int i = 0; i < Experts.Total(); i++) {
    CBacktestExpert *expert = Experts.At(i);
    expert.OnTick();
  }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsCandleAlmostClosed() {
  // static datetime last_tick,last_tick_server;
  // static MqlDateTime  last_tick_struct,last_tick_server_struct;
  if (isNewBarCurrentChart.isNewBar()) {
    /*MqlDateTime new_tick_struct;
          datetime new_tick=TimeCurrent(new_tick_struct);
          Print("new candle: ",new_tick
                ,"(",new_tick_struct.day_of_week,")"
                ," previous closed: ",last_tick
                ,"(",last_tick_struct.day_of_week,")"
                ," server: ",last_tick_server
                ,"(",last_tick_server_struct.day_of_week,")");
                */
    CandleProcessed = false;
  }
  // last_tick=TimeCurrent(last_tick_struct);
  // last_tick_server=TimeTradeServer(last_tick_server_struct);
  //   datetime
  //   lastbar_time=SeriesInfoInteger(Symbol(),Period(),SERIES_LASTBAR_DATE);
  int leftTime = PeriodSeconds(Period()) -
                 (int)(TimeCurrent() - isNewBarCurrentChart.GetLastBarTime());

  if (!CandleProcessed && leftTime <= Expert_ProcessOnTimeLeft) {
    Print("almose closed candle");
    CandleProcessed = true;
    return true;
  }
  return false;
}
//+------------------------------------------------------------------+
//| "Trade" event handler function                                   |
//+------------------------------------------------------------------+
void OnTrade() {
  for (int i = 0; i < Experts.Total(); i++) {
    CBacktestExpert *expert = Experts.At(i);
    expert.OnTrade();
  }
}

//+------------------------------------------------------------------+
//| Copy the inputs into an array                                    |
//+------------------------------------------------------------------+
bool SetupInputArrays() {
  // init Confirm2 indicator inputs and params
  Confirm_inputs[0] = Confirm_input0;
  Confirm_inputs[1] = Confirm_input1;
  Confirm_inputs[2] = Confirm_input2;
  Confirm_inputs[3] = Confirm_input3;
  Confirm_inputs[4] = Confirm_input4;
  Confirm_inputs[5] = Confirm_input5;
  Confirm_inputs[6] = Confirm_input6;
  Confirm_inputs[7] = Confirm_input7;
  Confirm_inputs[8] = Confirm_input8;
  Confirm_inputs[9] = Confirm_input9;
  Confirm_inputs[10] = Confirm_input10;
  Confirm_inputs[11] = Confirm_input11;
  Confirm_inputs[12] = Confirm_input12;
  Confirm_inputs[13] = Confirm_input13;
  Confirm_inputs[14] = Confirm_input14;

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
  Confirm2_inputs[0] = Confirm2_input0;
  Confirm2_inputs[1] = Confirm2_input1;
  Confirm2_inputs[2] = Confirm2_input2;
  Confirm2_inputs[3] = Confirm2_input3;
  Confirm2_inputs[4] = Confirm2_input4;
  Confirm2_inputs[5] = Confirm2_input5;
  Confirm2_inputs[6] = Confirm2_input6;
  Confirm2_inputs[7] = Confirm2_input7;
  Confirm2_inputs[8] = Confirm2_input8;
  Confirm2_inputs[9] = Confirm2_input9;
  Confirm2_inputs[10] = Confirm2_input10;
  Confirm2_inputs[11] = Confirm2_input11;
  Confirm2_inputs[12] = Confirm2_input12;
  Confirm2_inputs[13] = Confirm2_input13;
  Confirm2_inputs[14] = Confirm2_input14;

  Confirm2_buffer[0] = Confirm2_buffer0;
  Confirm2_buffer[1] = Confirm2_buffer1;
  Confirm2_buffer[2] = Confirm2_buffer2;
  Confirm2_buffer[3] = Confirm2_buffer3;
  Confirm2_buffer[4] = Confirm2_buffer4;

  Confirm2_param[0] = Confirm2_param0;
  Confirm2_param[1] = Confirm2_param1;
  Confirm2_param[2] = Confirm2_param2;
  Confirm2_param[3] = Confirm2_param3;
  Confirm2_param[4] = Confirm2_param4;

  Exit_inputs[0] = Exit_input0;
  Exit_inputs[1] = Exit_input1;
  Exit_inputs[2] = Exit_input2;
  Exit_inputs[3] = Exit_input3;
  Exit_inputs[4] = Exit_input4;
  Exit_inputs[5] = Exit_input5;
  Exit_inputs[6] = Exit_input6;
  Exit_inputs[7] = Exit_input7;
  Exit_inputs[8] = Exit_input8;
  Exit_inputs[9] = Exit_input9;
  Exit_inputs[10] = Exit_input10;
  Exit_inputs[11] = Exit_input11;
  Exit_inputs[12] = Exit_input12;
  Exit_inputs[13] = Exit_input13;
  Exit_inputs[14] = Exit_input14;

  Exit_buffer[0] = Exit_buffer0;
  Exit_buffer[1] = Exit_buffer1;
  Exit_buffer[2] = Exit_buffer2;
  Exit_buffer[3] = Exit_buffer3;
  Exit_buffer[4] = Exit_buffer4;

  Exit_param[0] = Exit_param0;
  Exit_param[1] = Exit_param1;
  Exit_param[2] = Exit_param2;
  Exit_param[3] = Exit_param3;
  Exit_param[4] = Exit_param4;

  Baseline_inputs[0] = Baseline_input0;
  Baseline_inputs[1] = Baseline_input1;
  Baseline_inputs[2] = Baseline_input2;
  Baseline_inputs[3] = Baseline_input3;
  Baseline_inputs[4] = Baseline_input4;
  Baseline_inputs[5] = Baseline_input5;
  Baseline_inputs[6] = Baseline_input6;
  Baseline_inputs[7] = Baseline_input7;
  Baseline_inputs[8] = Baseline_input8;
  Baseline_inputs[9] = Baseline_input9;
  Baseline_inputs[10] = Baseline_input10;
  Baseline_inputs[11] = Baseline_input11;
  Baseline_inputs[12] = Baseline_input12;
  Baseline_inputs[13] = Baseline_input13;
  Baseline_inputs[14] = Baseline_input14;

  Baseline_buffer[0] = Baseline_buffer0;
  Baseline_buffer[1] = Baseline_buffer1;
  Baseline_buffer[2] = Baseline_buffer2;
  Baseline_buffer[3] = Baseline_buffer3;
  Baseline_buffer[4] = Baseline_buffer4;

  Baseline_param[0] = Baseline_param0;
  Baseline_param[1] = Baseline_param1;
  Baseline_param[2] = Baseline_param2;
  Baseline_param[3] = Baseline_param3;
  Baseline_param[4] = Baseline_param4;

  Volume_inputs[0] = Volume_input0;
  Volume_inputs[1] = Volume_input1;
  Volume_inputs[2] = Volume_input2;
  Volume_inputs[3] = Volume_input3;
  Volume_inputs[4] = Volume_input4;
  Volume_inputs[5] = Volume_input5;
  Volume_inputs[6] = Volume_input6;
  Volume_inputs[7] = Volume_input7;
  Volume_inputs[8] = Volume_input8;
  Volume_inputs[9] = Volume_input9;
  Volume_inputs[10] = Volume_input10;
  Volume_inputs[11] = Volume_input11;
  Volume_inputs[12] = Volume_input12;
  Volume_inputs[13] = Volume_input13;
  Volume_inputs[14] = Volume_input14;

  Volume_buffer[0] = Volume_buffer0;
  Volume_buffer[1] = Volume_buffer1;
  Volume_buffer[2] = Volume_buffer2;
  Volume_buffer[3] = Volume_buffer3;
  Volume_buffer[4] = Volume_buffer4;

  Volume_param[0] = Volume_param0;
  Volume_param[1] = Volume_param1;
  Volume_param[2] = Volume_param2;
  Volume_param[3] = Volume_param3;
  Volume_param[4] = Volume_param4;

  Continue_inputs[0] = Continue_input0;
  Continue_inputs[1] = Continue_input1;
  Continue_inputs[2] = Continue_input2;
  Continue_inputs[3] = Continue_input3;
  Continue_inputs[4] = Continue_input4;
  Continue_inputs[5] = Continue_input5;
  Continue_inputs[6] = Continue_input6;
  Continue_inputs[7] = Continue_input7;
  Continue_inputs[8] = Continue_input8;
  Continue_inputs[9] = Continue_input9;
  Continue_inputs[10] = Continue_input10;
  Continue_inputs[11] = Continue_input11;
  Continue_inputs[12] = Continue_input12;
  Continue_inputs[13] = Continue_input13;
  Continue_inputs[14] = Continue_input14;

  Continue_buffer[0] = Continue_buffer0;
  Continue_buffer[1] = Continue_buffer1;
  Continue_buffer[2] = Continue_buffer2;
  Continue_buffer[3] = Continue_buffer3;
  Continue_buffer[4] = Continue_buffer4;

  Continue_param[0] = Continue_param0;
  Continue_param[1] = Continue_param1;
  Continue_param[2] = Continue_param2;
  Continue_param[3] = Continue_param3;
  Continue_param[4] = Continue_param4;

  Expert_symbols[0] = Expert_symbol0;
  Expert_symbols[1] = Expert_symbol1;
  Expert_symbols[2] = Expert_symbol2;
  Expert_symbols[3] = Expert_symbol3;
  Expert_symbols[4] = Expert_symbol4;
  Expert_symbols[5] = Expert_symbol5;
  Expert_symbols[6] = Expert_symbol6;
  Expert_symbols[7] = Expert_symbol7;
  Expert_symbols[8] = Expert_symbol8;
  Expert_symbols[9] = Expert_symbol9;
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
  // Expert_symbols.Sort(); // TODO Sort Expert symbols here
  symbols.Sort();
  currencies.Sort();
  if (StringLen(Expert_symbols[0]) == 0)
    // no symbols configured .. only set currenty Symbol()
    Expert_symbols[0] = Symbol();

  for (int i = 0; i < ArraySize(Expert_symbols); i++) {
    if (StringLen(Expert_symbols[i]) == 0)
      break;

    if (!symbols.InsertSort(Expert_symbols[i])) {
      Print("insert Symbol failed");
      return (false);
    }

    // this asserts that currencies have 3 letters!!
    string cur[2];
    cur[0] = StringSubstr(Expert_symbols[i], 0, 3);
    cur[1] = StringSubstr(Expert_symbols[i], 3, -1);

    for (int j = 0; j < 2; j++) {
      if (currencies.Search(cur[j]) == -1) {
        if (!currencies.InsertSort(cur[j])) {
          Print("insert currency failed");
          return (false);
        }
      }
    }
  }

#ifdef _DEBUG
  if (!MQL5InfoInteger(MQL5_OPTIMIZATION)) {
    for (int n = 0; n < symbols.Total(); n++) {
      PrintFormat("symbols[%d]=\"%s\"", n, symbols.At(n));
    }
    for (int n = 0; n < currencies.Total(); n++) {
      PrintFormat("currencies[%d]=\"%s\"", n, currencies.At(n));
    }
  }
#endif

  return true;
}
//+------------------------------------------------------------------+


void SetupBacktestPreset() {
   if (Backtest_ModeSelect != Manual) {
      UpdateBacktestParamsFromPreset();
   }
   PrintBacktestMode();
}

void UpdateBacktestParamsFromPreset() {
   BACKTEST_MODE_CONFIG mode_config = Backtest_ModeConfigs[Backtest_ModeSelect];
   Money_AddTakeProfit = mode_config.take_profit;
   Money_ScaleOut = mode_config.scale_out;
   Money_TrailingMode = mode_config.trailing_mode;
   Backtest_Metric = mode_config.metric;
}

void PrintBacktestMode() {
#ifdef _DEBUG
  if (!MQL5InfoInteger(MQL5_OPTIMIZATION)) {
     Print("We are running the following backtest mode:");
     PrintBacktestPresetMode();
     PrintTPMode();
     PrintTrailingMode();
     PrintScaleOutMode();
     PrintMetricMode();
  }
#endif
}

void PrintBacktestPresetMode() {
   Print("Backtest Preset: ", Backtest_ModeSelect, ": ", EnumToString(Backtest_ModeSelect));
}

void PrintTrailingMode() {
   Print("Trailing Stop: ",
         Money_TrailingMode ? "Yes " : "No ",
         Money_TrailingMode ? DoubleToString(Money_TrailingStopATRLevel) : ""
         );
}

void PrintTPMode() {
   Print("Take Profit: ",
         Money_AddTakeProfit ? "Yes " : "No ",
         Money_AddTakeProfit ? DoubleToString(Money_TakeLevel) : "" );
}

void PrintScaleOutMode() {
   Print("Scaling Out: ", Money_ScaleOut ? "Yes " : "No ");
}

void PrintMetricMode() {
   Print("Metric Mode: ", Backtest_Metric, ": ", EnumToString(Backtest_Metric));
}

/* goes through the deal history and calculates the return for each trade
 * returns a sorted list of the reaturns -> used for calculating Value at Risk */
void CalculateReturnHistory(double &return_history[]) {
   double balance = 0;
   // get all Deals from the trading history
   HistorySelect(0,TimeCurrent());   // load deals
   int deals_cnt=HistoryDealsTotal();
   ArrayResize(return_history, deals_cnt);

   // calculate the return for each trade(deal)
   for(int i=0; i < deals_cnt; i++) {
      ulong  deal_ticket = HistoryDealGetTicket(i);
      double profit = HistoryDealGetDouble(deal_ticket,DEAL_PROFIT);
      double swap = HistoryDealGetDouble(deal_ticket,DEAL_SWAP);
      double fee = HistoryDealGetDouble(deal_ticket,DEAL_FEE);
      double comission = HistoryDealGetDouble(deal_ticket,DEAL_COMMISSION);
      double net_profit = profit + swap + fee + comission;
      if (balance != 0.0)
         return_history[i] = net_profit / balance;

      // update realized balance
      balance += net_profit;
   }
   ArraySort(return_history);
}

double CalculateVaR(double quant_level) {
   double return_history[];
   CalculateReturnHistory(return_history);

   int deals_cnt=HistoryDealsTotal();
   double quantile = MathCeil((double) deals_cnt * (1 - quant_level));
   double VaR = return_history[(int) quantile];
   return MathIsValidNumber(VaR) ? VaR : -1;
}

double CalculateCVaR(double quant_level) {
   double return_history[];
   CalculateReturnHistory(return_history);

   int deals_cnt=HistoryDealsTotal();
   double quantile = MathCeil((double) deals_cnt * (1 - quant_level));
   double return_history_trunc[];
   ArrayCopy(return_history_trunc, return_history, 0, 0, (int) quantile);
   double CVaR = MathSum(return_history_trunc) / quantile;
   return MathIsValidNumber(CVaR) ? CVaR : -1;
}

double CalculateWinRate() {
   long num_trades = (long) TesterStatistics(STAT_TRADES);
   int tp_cnt = 0;
   int sl_cnt = 0;
   int reason_client_cnt = 0;

   HistorySelect(0,TimeCurrent());   // load deals
   int deals_cnt=HistoryDealsTotal();
   for(int i=0; i < deals_cnt; i++) {
      ulong  deal_ticket = HistoryDealGetTicket(i);
      ENUM_DEAL_REASON reason = ENUM_DEAL_REASON(HistoryDealGetInteger(deal_ticket,DEAL_REASON));
      if (reason == DEAL_REASON_TP) {
         tp_cnt++;
      } else if (reason == DEAL_REASON_SL) {
         sl_cnt++;
      } else if (reason == DEAL_REASON_CLIENT) {
         // - the first deal is "Balance"
         // - if the last trade is cancled due to end-of-test
         reason_client_cnt++;
      }
   }

   num_trades -= (reason_client_cnt - 1);
   if (num_trades <= 0) return 0.0;

   double win_rate = tp_cnt / (double) num_trades;
   long strike_out = num_trades - tp_cnt - sl_cnt;  // all trades that did not hit sl/tp
#ifdef _DEBUG
   PrintFormat("Number of trades: %l (%d)\nWin rate: %.3f\tStrike: %d\nClosed due to end of test: %d",
              TesterStatistics(STAT_TRADES), num_trades, win_rate, strike_out, reason_client_cnt - 1);
   Print("%profitable: ", TesterStatistics(STAT_TRADES) == 0. ? 0.
         : TesterStatistics(STAT_PROFIT_TRADES) / TesterStatistics(STAT_TRADES));
#endif
   return win_rate;
}


