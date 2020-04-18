//+------------------------------------------------------------------+
//|                                 Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include <..\Experts\BacktestExpert\Signal\PriceCrossSignal.mqh>
#define PRODUCE_SignalALF2_baseline PRODUCE("ALF2_baseline", CSignalALF2_baseline)

class CSignalALF2_baseline : public CPriceCrossSignal {
public:
  CSignalALF2_baseline(void);
  virtual void      CSignalALF2_baseline::ParamsFromInput(double &Input[]);
};

CSignalALF2_baseline::CSignalALF2_baseline(void) {
  m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
  m_buffers[0] = 0;
  }

void CSignalALF2_baseline::ParamsFromInput(double &Input[]) {
  m_params_size = 5;
  ArrayResize(m_params, m_params_size);
  m_params[0].type=TYPE_STRING;
  m_params[0].string_value="Indi\Adaptive_Laguerre_filter_2.ex5";
  m_params[1].type=TYPE_INT;
  m_params[1].integer_value=Input[0];
  m_params[2].type=TYPE_DOUBLE;
  m_params[2].double_value=Input[1];
  m_params[3].type=TYPE_DOUBLE;
  m_params[3].double_value=Input[2];
  m_params[4].type=TYPE_INT;
  m_params[4].integer_value=Input[3];
  }
