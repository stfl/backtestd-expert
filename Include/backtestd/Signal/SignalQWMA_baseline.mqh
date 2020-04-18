//+------------------------------------------------------------------+
//|                                 Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include <backtestd\SignalClass\PriceCrossSignal.mqh>
#define PRODUCE_SignalQWMA_baseline PRODUCE("QWMA_baseline", CSignalQWMA_baseline)

class CSignalQWMA_baseline : public CPriceCrossSignal {
public:
  CSignalQWMA_baseline(void);
  virtual void      CSignalQWMA_baseline::ParamsFromInput(double &Input[]);
};

CSignalQWMA_baseline::CSignalQWMA_baseline(void) {
  m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
  m_buffers[0] = 4;
  }

void CSignalQWMA_baseline::ParamsFromInput(double &Input[]) {
  m_params_size = 10;
  ArrayResize(m_params, m_params_size);
  m_params[0].type=TYPE_STRING;
  m_params[0].string_value="QWMA_ca.ex5";
  m_params[1].type=TYPE_INT;
  m_params[1].integer_value=Input[0];
  m_params[2].type=TYPE_INT;
  m_params[2].integer_value=Input[1];
  m_params[3].type=TYPE_DOUBLE;
  m_params[3].double_value=Input[2];
  m_params[4].type=TYPE_INT;
  m_params[4].integer_value=Input[3];
  m_params[5].type=TYPE_INT;
  m_params[5].integer_value=Input[4];
  m_params[6].type=TYPE_INT;
  m_params[6].integer_value=Input[5];
  m_params[7].type=TYPE_INT;
  m_params[7].integer_value=Input[6];
  m_params[8].type=TYPE_DOUBLE;
  m_params[8].double_value=Input[7];
  m_params[9].type=TYPE_DOUBLE;
  m_params[9].double_value=Input[8];
  }
