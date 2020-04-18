//+------------------------------------------------------------------+
//|                                 Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include <backtestd\SignalClass\ColorChangeSignal.mqh>
#define PRODUCE_SignalCOG PRODUCE("COG", CSignalCOG)

class CSignalCOG : public CColorChangeSignal {
public:
  CSignalCOG(void);
  virtual void      CSignalCOG::ParamsFromInput(double &Input[]);
};

CSignalCOG::CSignalCOG(void) {
  m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
  m_buffers[0] = 1;
  m_config[0] = 0;
  m_config[1]    = 1;
  m_config[2]  = 2;
  }

void CSignalCOG::ParamsFromInput(double &Input[]) {
  m_params_size = 4;
  ArrayResize(m_params, m_params_size);
  m_params[0].type=TYPE_STRING;
  m_params[0].string_value="center-of-gravity-extended-indicator.ex5";
  m_params[1].type=TYPE_INT;
  m_params[1].integer_value=Input[0];
  m_params[2].type=TYPE_INT;
  m_params[2].integer_value=Input[1];
  m_params[3].type=TYPE_INT;
  m_params[3].integer_value=Input[2];
  }
