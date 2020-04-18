//+------------------------------------------------------------------+
//|                                     Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include <..\Experts\BacktestExpert\Signal\TwoLinesCrossSignal.mqh>

#define PRODUCE_SignalWAE PRODUCE("wae", CSignalWAE)

//+------------------------------------------------------------------+
class CSignalWAE : public CTwoLinesCrossSignal
  {
public:
                     CSignalWAE(void);
   virtual void      CSignalWAE::ParamsFromInput(double &Signal_double[]);

  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSignalWAE::CSignalWAE(void)
  {
   m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
   m_buffers[0] = 0;
   m_buffers[1] = 2;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CSignalWAE::ParamsFromInput(double &Signal_double[])
  {
   m_params_size = 10;
   ArrayResize(m_params, m_params_size);
   m_params[0].type=TYPE_STRING;
   m_params[0].string_value="Indi\waddah_attar_explosion.ex5";

//input int Fast_MA = 20;       // Period of the fast MACD moving average
   m_params[1].type=TYPE_INT;
   m_params[1].integer_value=Signal_double[0];

//input int Slow_MA = 40;       // Period of the slow MACD moving average
   m_params[2].type=TYPE_INT;
   m_params[2].integer_value=Signal_double[1];

//input int BBPeriod=20;        // Bollinger period
   m_params[3].type=TYPE_INT;
   m_params[3].integer_value=Signal_double[2];

//input double BBDeviation=2.0; // Number of Bollinger deviations
   m_params[4].type=TYPE_DOUBLE;
   m_params[4].double_value=Signal_double[3];

//input int  Sensetive=150;
   m_params[5].type=TYPE_INT;
   m_params[5].integer_value=Signal_double[4];

//input int  DeadZonePip=400;
   m_params[6].type=TYPE_INT;
   m_params[6].integer_value=Signal_double[5];

//input int  ExplosionPower=15;
   m_params[7].type=TYPE_INT;
   m_params[7].integer_value=Signal_double[6];

//input int  TrendPower=150;
   m_params[8].type=TYPE_INT;
   m_params[8].integer_value=Signal_double[7];

//input bool AlertWindow=false;
//m_params[9].type=TYPE_BOOL;
//m_params[9].bool_value=false;

//input int  AlertCount=2;
   m_params[9].type=TYPE_INT;
   m_params[9].integer_value=Signal_double[8];

//      //input bool AlertLong=false;
//      m_params[11].type=TYPE_BOOL;
//      m_params[11].bool_value=false;
//
//      //input bool AlertShort=false;
//      m_params[5].type=TYPE_BOOL;
//      m_params[5].bool_value=false;
//
//      //input bool AlertExitLong=false;
//      m_params[5].type=TYPE_BOOL;
//      m_params[5].bool_value=false;
//
//      //input bool AlertExitShort=false;
//      m_params[5].type=TYPE_BOOL;
//      m_params[5].bool_value=false;
  }

//+------------------------------------------------------------------+
