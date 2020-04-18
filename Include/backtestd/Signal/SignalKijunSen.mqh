//+------------------------------------------------------------------+
//|                                     Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include <..\Experts\BacktestExpert\Signal\PriceCrossSignal.mqh>

#define PRODUCE_SignalKijunSen  PRODUCE("kijunsen", CSignalKijunSen)

//+------------------------------------------------------------------+
class CSignalKijunSen : public CPriceCrossSignal
  {
public:
                     CSignalKijunSen(void);
   virtual void      CSignalKijunSen::ParamsFromInput(double &Signal_double[]);

  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSignalKijunSen::CSignalKijunSen(void)
  {
   m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
   m_buffers[0] = 1;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CSignalKijunSen::ParamsFromInput(double &Signal_double[])
  {
   m_indicator_type = IND_ICHIMOKU;
   
   m_params_size = 3;
   ArrayResize(m_params, m_params_size);
   m_params[0].type=TYPE_INT;
   m_params[0].integer_value=Signal_double[0];
   m_params[1].type=TYPE_INT;
   m_params[1].integer_value=Signal_double[1];
   m_params[2].type=TYPE_INT;
   m_params[2].integer_value=Signal_double[2];
  }

//+------------------------------------------------------------------+
