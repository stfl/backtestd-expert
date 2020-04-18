//+------------------------------------------------------------------+
//|                                 Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include <backtestd\SignalClass\ColorChangeSignal.mqh>
#define PRODUCE_SignalALF2 PRODUCE("ALF2", CSignalALF2)

class CSignalALF2 : public CColorChangeSignal {
public:
  CSignalALF2(void);
  virtual void      CSignalALF2::ParamsFromInput(double &Input[]);
};

CSignalALF2::CSignalALF2(void) {
  m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
  m_buffers[0] = 1;
  m_config[0] = 0;
  m_config[1] = 1;
  m_config[2] = 2;
  }

void CSignalALF2::ParamsFromInput(double &Input[]) {
  m_params_size = 5;
  ArrayResize(m_params, m_params_size);
  m_params[0].type=TYPE_STRING;
  m_params[0].string_value="Adaptive_Laguerre_filter_2.ex5";
  m_params[1].type=TYPE_INT;
  m_params[1].integer_value=Input[0];
  m_params[2].type=TYPE_DOUBLE;
  m_params[2].double_value=Input[1];
  m_params[3].type=TYPE_DOUBLE;
  m_params[3].double_value=Input[2];
  m_params[4].type=TYPE_INT;
  m_params[4].integer_value=Input[3];
  }
