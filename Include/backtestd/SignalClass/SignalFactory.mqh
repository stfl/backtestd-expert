//+------------------------------------------------------------------+
//|                                                    SignalTCT.mqh |
//|                                     Copyright 2019, Stefan Lendl |
//|                                                                  |
//+------------------------------------------------------------------+
#include "CustomSignal.mqh"
#include <backtestd\Signal\PresetSignals.mqh>

#include <backtestd\SignalClass\AggSignal.mqh>
#include <backtestd\SignalClass\BothLinesLevelCrossSignal.mqh>
#include <backtestd\SignalClass\BothLinesTwoLevelsCrossSignal.mqh>
#include <backtestd\SignalClass\ColorChangeSignal.mqh>
#include <backtestd\SignalClass\CustomSignal.mqh>
#include <backtestd\SignalClass\PriceCrossInvertedSignal.mqh>
#include <backtestd\SignalClass\PriceCrossSignal.mqh>
#include <backtestd\SignalClass\SemaphoreSignal.mqh>
#include <backtestd\SignalClass\SignalFactory.mqh>
#include <backtestd\SignalClass\TwoLevelsCrossSignal.mqh>
#include <backtestd\SignalClass\TwoLinesColorChangeSignal.mqh>
#include <backtestd\SignalClass\TwoLinesCrossSignal.mqh>
#include <backtestd\SignalClass\TwoLinesTwoLevelsCrossSignal.mqh>
#include <backtestd\SignalClass\ZeroLineCrossSignal.mqh>
#include <backtestd\SignalClass\SaturationLevelsSignal.mqh>
#include <backtestd\SignalClass\BothLinesSaturationLevelsSignal.mqh>

#define assert_signal \
if(!signal) { \
    Alert("Signal creation failed! "+name); \
return NULL; \
}

enum ENUM_SIGNAL_CLASS {
    Preset = 0,
    ZeroLineCross = 1,
    TwoLinesCross = 2,
    TwoLinesTwoLevelsCross = 3,
    TwoLevelsCross = 4,
    PriceCross = 5,
    PriceCrossInverted = 6,
    Semaphore = 7,
    TwoLinesColorChange = 8,
    ColorChange = 9,
    BothLinesTwoLevelsCross = 10,
    BothLinesLevelCross = 11,
    SaturationLevels = 12,
    SaturationLines = 13,
    BothLinesSaturationLevels = 14,
    SlopeChange = 15,
    TwoLinesSlopeChange = 16,
}

/*
enum ENUM_SIGNAL_CLASS {
   Preset = 0,

   ZeroLineCross,
   // A single line that crosses 0

   TwoLinesCross,
   // Two lines that cross each other

   TwoLinesTwoLevelsCross,
   // Two lines may cross two levels

   TwoLevelsCross,
   // a single line may cross two levels

   PriceCross,
   // A line on the chart that is crossed by the price

   PriceCrossInverted,
   //    ... the signal is inverted

   Semaphore,
   // A signal like arrow or dot is displayed on the chart

   TwoLinesColorChange,
   //   ... only a single line is considred for color changes

   ColorChange,
   // A color change indicates a signal.

   BothLinesTwoLevelsCross,
   // both lines need to cross to give a signal
   BothLinesLevelCross,

   SaturationLevels,
   // SaturationLines,
   BothLinesSaturationLevels,

   // SlopeChange,
   // // Single line that changes its direction
  
   //  TwoLinesLevelLineCross,
   // // Two lines may cross a single level line
   // TwoLinesTwoLevelLinesCross,
   // // Two lines may cross multiple level lines
};
*/

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CSignalFactory
  {
public:
   static CCustomSignal *MakeSignal(string name,
                                    double &inputs[],
                                    uint &buffers[],
                                    double &params[],
                                    ENUM_SIGNAL_CLASS signal_class=Preset,
                                    ENUM_TIMEFRAMES time_frame=PERIOD_CURRENT,
                                    uint shift=0);
};


CCustomSignal* CSignalFactory::MakeSignal(string name,
                                          double &inputs[],
                                          uint &buffers[],
                                          double &params[],
                                          ENUM_SIGNAL_CLASS signal_class,
                                          ENUM_TIMEFRAMES time_frame,
                                          uint shift)
  {
   if(StringCompare(name,"TCT",false)==0)
     {
      CSignalTCT *signal=new CSignalTCT;
      assert_signal;

      MqlParam param[2];
      param[0].type=TYPE_STRING;
      param[0].string_value="Trend Counter Trend.ex5";
      param[1].type=TYPE_INT;
      param[1].integer_value=inputs[0];  // Period
      signal.Params(param,2);
      return signal;

     }
   else if(StringCompare(name,"Go",false)==0)
     {
      CGoSignal *signal=new CGoSignal;
      assert_signal;
      signal.Ind_Timeframe(time_frame);
      signal.EveryTick(Expert_EveryTick);
      signal.period(inputs[0]);
      signal.SignalBar(shift+(Expert_EveryTick ? 0 : 1));
      return signal;

     }
   else if(StringCompare(name,"SuperTrend",false)==0)
   {
      CSuperTrendSignal *signal=new CSuperTrendSignal;
      assert_signal;
      signal.Ind_Timeframe(time_frame);
      signal.EveryTick(Expert_EveryTick);
      signal.SignalBar(shift+(Expert_EveryTick ? 0 : 1));

      signal.CCIPeriod(inputs[0]);
      signal.ATRPeriod(inputs[1]);
      signal.Level(inputs[2]);

      return signal;

     }
   else if(StringCompare(name,"ASCtrend",false)==0)
     {
      CASCtrendSignal *signal=new CASCtrendSignal;
      assert_signal;
      signal.Ind_Timeframe(time_frame);
      signal.EveryTick(Expert_EveryTick);
      signal.RISK(inputs[0]);
      signal.SignalBar(shift+(Expert_EveryTick ? 0 : 1));
      return signal;

     }
   else if(StringCompare(name,"JFatl",false)==0)
     {
      CJFatlSignal *signal=new CJFatlSignal;
      assert_signal;
      signal.Ind_Timeframe(time_frame);
      signal.EveryTick(Expert_EveryTick);
      signal.SignalBar(shift+(Expert_EveryTick ? 0 : 1));

      signal.Length_(inputs[0]);
      signal.Phase_(inputs[1]);
      signal.IPC(inputs[2]);

      return signal;
     }
   else if(StringCompare(name,"nonlagdot",false)==0)
     {
      CNonLagDotSignal *signal=new CNonLagDotSignal;
      assert_signal;
      signal.Ind_Timeframe(time_frame);
      signal.EveryTick(Expert_EveryTick);
      signal.SignalBar(shift+(Expert_EveryTick ? 0 : 1));

      signal.Price(ENUM_APPLIED_PRICE(inputs[0]));
      signal.Type(ENUM_MA_METHOD(inputs[1]));
      signal.Length(inputs[2]);
      signal.Filter(inputs[3]);
      signal.Swing(inputs[4]);   // offset on the chart >> only cosmetic

      return signal;
     }
   else if(StringCompare(name,"sidus",false)==0)
     {
      CSidusSignal *signal=new CSidusSignal;
      assert_signal;

      signal.Ind_Timeframe(time_frame);
      signal.EveryTick(Expert_EveryTick);
      signal.SignalBar(shift+(Expert_EveryTick ? 0 : 1));

      signal.FastEMA(inputs[0]);
      signal.SlowEMA(inputs[1]);
      signal.FastLWMA(inputs[2]);
      signal.SlowLWMA(inputs[3]);
      signal.IPC(inputs[4]);
      signal.Digit(inputs[5]);

      return signal;
     }
   else if(StringCompare(name,"karacatica",false)==0)
     {
      CKaracaticaSignal *signal=new CKaracaticaSignal;
      assert_signal;

      signal.Ind_Timeframe(time_frame);
      signal.EveryTick(Expert_EveryTick);
      signal.SignalBar(shift+(Expert_EveryTick ? 0 : 1));

      signal.iPeriod(inputs[0]);

      return signal;
     }
    else if(StringCompare(name,"ma",false)==0)
     {
      CSignalMA *signal=new CSignalMA;
      assert_signal;

      signal.Period(time_frame);

      signal.PeriodMA(inputs[0]);
      signal.Shift(inputs[1]);
      signal.Method(ENUM_MA_METHOD(inputs[2]));  // [0..3]
      signal.Applied(ENUM_APPLIED_PRICE(inputs[3])); // [0..6]

      return signal;
     }
     
   PRODUCE_SIGNALS();

   CCustomSignal *signal;
   switch (signal_class) {
      case ZeroLineCross: signal=new CZeroLineCrossSignal(); break;
      case TwoLinesCross: signal=new CTwoLinesCrossSignal(); break;
      case TwoLinesTwoLevelsCross: signal=new CTwoLinesTwoLevelsCrossSignal(); break;
      case TwoLevelsCross: signal=new CTwoLevelsCrossSignal(); break;
      case PriceCross: signal=new CPriceCrossSignal(); break;
      case PriceCrossInverted: signal=new CPriceCrossInvertedSignal(); break;
      case Semaphore: signal=new CSemaphoreSignal(); break;
      case TwoLinesColorChange: signal=new CTwoLinesColorChangeSignal(); break;
      case ColorChange: signal=new CColorChangeSignal(); break;
      case BothLinesTwoLevelsCross: signal=new CBothLinesTwoLevelsCrossSignal(); break;
      case BothLinesLevelCross: signal=new CBothLinesLevelCrossSignal(); break;
      case SaturationLevels: signal=new CSaturationLevelsSignal(); break;
      case BothLinesSaturationLevels: signal=new CBothLinesSaturationLevelsSignal(); break;

      //case TwoLinesLevelLineCross: signal=new CTwoLinesLevelLineCrossSignal(); break;
      //case TwoLinesTwoLevelLinesCross: signal=new CTwoLinesTwoLevelLinesCrossSignal(); break;
      case Preset:
      default:
         printf(__FUNCTION__+"Wrong signal class. Cannot produce Signal "+name);
         return NULL;
      break;
   }

   assert_signal;
   signal.Buffers(buffers);
   signal.Config(params);
   // if (!signal.ValidationInputs(double))  // TODO can this even be done for this type of initialization?
   //    return NULL;
   signal.IndicatorFile(name);
   signal.ParamsFromInput(inputs);
   signal.Shift(shift);
   signal.Ind_Timeframe(time_frame);
   return signal;

   printf(__FUNCTION__+"Factory cannot produce Signal "+name);
   return NULL;

  }
//+------------------------------------------------------------------+
