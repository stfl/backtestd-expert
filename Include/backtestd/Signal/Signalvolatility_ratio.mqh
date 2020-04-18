//+------------------------------------------------------------------+
//|                                 Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include <..\Experts\BacktestExpert\Signal\TwoLevelsCrossSignal.mqh>
#define PRODUCE_Signalvolatility_ratio PRODUCE("volatility_ratio", CSignalvolatility_ratio)

class CSignalvolatility_ratio : public CTwoLevelsCrossSignal {
public:
  CSignalvolatility_ratio(void);
  virtual void      CSignalvolatility_ratio::ParamsFromInput(double &Input[]);
};

CSignalvolatility_ratio::CSignalvolatility_ratio(void) {
  m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
  m_buffers[0] = 0;
  m_config[0]   = 1;
  m_config[1]    = 1;
  m_config[2] = 1;
  m_config[3]  = 1;
  m_stateful_side = false;
  }

void CSignalvolatility_ratio::ParamsFromInput(double &Input[]) {
  m_params_size = 3;
  ArrayResize(m_params, m_params_size);
  m_params[0].type=TYPE_STRING;
  m_params[0].string_value="Indi\Volatility_ratio.ex5";
  m_params[1].type=TYPE_INT;
  m_params[1].integer_value=Input[0];
  m_params[2].type=TYPE_INT;
  m_params[2].integer_value=Input[1];
  }
