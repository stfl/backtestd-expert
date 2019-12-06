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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CSignalFactory
  {
public:
   static CCustomSignal *MakeSignal(string name,
                                    double &Signal_double[],
                                    ENUM_TIMEFRAMES Signal_TimeFrame=PERIOD_CURRENT,
                                    uint Signal_Shift=0);

  };

CCustomSignal* CSignalFactory::MakeSignal(string name,
                                         double &Signal_double[],
                                         ENUM_TIMEFRAMES Signal_TimeFrame,
                                         uint Signal_Shift)
  {
   if(StringCompare(name,"TCT",false)==0)
     {
      CSignalTCT *signal=new CSignalTCT;
      assert_signal;

      MqlParam param[2];
      param[0].type=TYPE_STRING;
      param[0].string_value="Indi\Trend Counter Trend.ex5";
      param[1].type=TYPE_INT;
      param[1].integer_value=Signal_double[0];  // Period
      signal.Params(param,2);
      return signal;

     }
   else if(StringCompare(name,"Go",false)==0)
     {
      CGoSignal *signal=new CGoSignal;
      assert_signal;
      signal.Ind_Timeframe(Signal_TimeFrame);
      signal.EveryTick(Expert_EveryTick);
      signal.period(Signal_double[0]);
      signal.SignalBar(Signal_Shift+(Expert_EveryTick ? 0 : 1));
      return signal;

     }
   else if(StringCompare(name,"SuperTrend",false)==0)
     {
      CSuperTrendSignal *signal=new CSuperTrendSignal;
      assert_signal;
      signal.Ind_Timeframe(Signal_TimeFrame);
      signal.EveryTick(Expert_EveryTick);
      signal.SignalBar(Signal_Shift+(Expert_EveryTick ? 0 : 1));

      signal.CCIPeriod(Signal_double[0]);
      signal.ATRPeriod(Signal_double[1]);
      signal.Level(Signal_double[2]);

      return signal;

     }
   else if(StringCompare(name,"ASCtrend",false)==0)
     {
      CASCtrendSignal *signal=new CASCtrendSignal;
      assert_signal;
      signal.Ind_Timeframe(Signal_TimeFrame);
      signal.EveryTick(Expert_EveryTick);
      signal.RISK(Signal_double[0]);
      signal.SignalBar(Signal_Shift+(Expert_EveryTick ? 0 : 1));
      return signal;

     }
   else if(StringCompare(name,"JFatl",false)==0)
     {
      CJFatlSignal *signal=new CJFatlSignal;
      assert_signal;
      signal.Ind_Timeframe(Signal_TimeFrame);
      signal.EveryTick(Expert_EveryTick);
      signal.SignalBar(Signal_Shift+(Expert_EveryTick ? 0 : 1));

      signal.Length_(Signal_double[0]);
      signal.Phase_(Signal_double[1]);
      signal.IPC(Signal_double[2]);

      return signal;
     }
   else if(StringCompare(name,"nonlagdot",false)==0)
     {
      CNonLagDotSignal *signal=new CNonLagDotSignal;
      assert_signal;
      signal.Ind_Timeframe(Signal_TimeFrame);
      signal.EveryTick(Expert_EveryTick);
      signal.SignalBar(Signal_Shift+(Expert_EveryTick ? 0 : 1));

      signal.Price(ENUM_APPLIED_PRICE(Signal_double[0]));
      signal.Type(ENUM_MA_METHOD(Signal_double[1]));
      signal.Length(Signal_double[2]);
      signal.Filter(Signal_double[3]);
      signal.Swing(Signal_double[4]);   // offset on the chart >> only cosmetic

      return signal;
     }
   else if(StringCompare(name,"sidus",false)==0)
     {
      CSidusSignal *signal=new CSidusSignal;
      assert_signal;

      signal.Ind_Timeframe(Signal_TimeFrame);
      signal.EveryTick(Expert_EveryTick);
      signal.SignalBar(Signal_Shift+(Expert_EveryTick ? 0 : 1));

      signal.FastEMA(Signal_double[0]);
      signal.SlowEMA(Signal_double[1]);
      signal.FastLWMA(Signal_double[2]);
      signal.SlowLWMA(Signal_double[3]);
      signal.IPC(Signal_double[4]);
      signal.Digit(Signal_double[5]);

      return signal;
     }
   else if(StringCompare(name,"karacatica",false)==0)
     {
      CKaracaticaSignal *signal=new CKaracaticaSignal;
      assert_signal;

      signal.Ind_Timeframe(Signal_TimeFrame);
      signal.EveryTick(Expert_EveryTick);
      signal.SignalBar(Signal_Shift+(Expert_EveryTick ? 0 : 1));

      signal.iPeriod(Signal_double[0]);

      return signal;
     }
    else if(StringCompare(name,"ma",false)==0)
     {
      CSignalMA *signal=new CSignalMA;
      assert_signal;

      signal.Period(Signal_TimeFrame);

      signal.PeriodMA(Signal_double[0]);
      signal.Shift(Signal_double[1]);
      signal.Method(ENUM_MA_METHOD(Signal_double[2]));  // [0..3]
      signal.Applied(ENUM_APPLIED_PRICE(Signal_double[3])); // [0..6]

      return signal;
     }
     
     PRODUCE_SIGNALS();
     


   printf(__FUNCTION__+"Factory cannot produce Signal "+name);
   return NULL;
  }
//+------------------------------------------------------------------+
