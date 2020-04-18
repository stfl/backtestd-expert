//+------------------------------------------------------------------+
//|                                 Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include <backtestd\SignalClass\TwoLevelsCrossSignal.mqh>
#define PRODUCE_SignalSTC PRODUCE("STC", CSignalSTC)

class CSignalSTC : public CTwoLevelsCrossSignal {
public:
  CSignalSTC(void);
  virtual void      CSignalSTC::ParamsFromInput(double &Input[]);
};

CSignalSTC::CSignalSTC(void) {
  m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
  m_buffers[0] = 0;
  m_config[0]   = 75;
  m_config[1]    = 25;
  m_config[2] = 25;
  m_config[3]  = 75;
  m_stateful_side = true;
  }

void CSignalSTC::ParamsFromInput(double &Input[]) {
  m_params_size = 4;
  ArrayResize(m_params, m_params_size);
  m_params[0].type=TYPE_STRING;
  m_params[0].string_value="SchaffTrendCycle.ex5";
  m_params[1].type=TYPE_INT;
  m_params[1].integer_value=Input[0];
  m_params[2].type=TYPE_INT;
  m_params[2].integer_value=Input[1];
  m_params[3].type=TYPE_INT;
  m_params[3].integer_value=Input[2];
  }
