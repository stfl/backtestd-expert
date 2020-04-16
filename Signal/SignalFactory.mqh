//+------------------------------------------------------------------+
//|                                                    SignalTCT.mqh |
//|                                     Copyright 2019, Stefan Lendl |
//|                                                                  |
//+------------------------------------------------------------------+
#include "CustomSignal.mqh"
#include <IndiSignals\AllSignals.mqh>

#define assert_signal \
if(!signal) { \
    Alert("Signal creation failed! "+name); \
return NULL; \
}

enum ENUM_SIGNAL_CLASS {
   ZeroLineCross,
   Other,
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CSignalFactory
  {
public:
   static CCustomSignal *MakeSignal(string name,
                                    double &inputs[],
                                    double &buffers[],
                                    double &params[],
                                    ENUM_SIGNAL_CLASS signal_class=Other,
                                    ENUM_TIMEFRAMES time_frame=PERIOD_CURRENT,
                                    uint shift=0);
};


CCustomSignal* CSignalFactory::MakeSignal(string name,
                                          double &inputs[],
                                          double &buffers[],
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
      param[0].string_value="Indi\Trend Counter Trend.ex5";
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
      case ZeroLineCross:
         signal=new CZeroLineCrossSignal();
         ((CZeroLineCrossSignal *)signal).Buffer(buffers[0]);
         // TODO add buffers and other signal class specific parameters
         break;
      case Other:
      default:
         printf(__FUNCTION__+"Wrong signal class. Cannot produce Signal "+name);
         return NULL;
      break;
   }

   assert_signal;
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
