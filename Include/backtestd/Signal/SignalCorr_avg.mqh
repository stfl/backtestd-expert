//+------------------------------------------------------------------+
//|                                 Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include <backtestd\SignalClass\ColorChangeSignal.mqh>
#define PRODUCE_SignalCorr_avg PRODUCE("Corr_avg", CSignalCorr_avg)

class CSignalCorr_avg : public CColorChangeSignal {
public:
  CSignalCorr_avg(void);
  virtual void      CSignalCorr_avg::ParamsFromInput(double &Input[]);
};

CSignalCorr_avg::CSignalCorr_avg(void) {
  m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
  m_buffers[0] = 6;
  m_config[0] = 0;
  m_config[1]    = 1;
  m_config[2]  = 2;
  }

void CSignalCorr_avg::ParamsFromInput(double &Input[]) {
  m_params_size = 10;
  ArrayResize(m_params, m_params_size);
  m_params[0].type=TYPE_STRING;
  m_params[0].string_value="Corr_average.ex5";
  m_params[1].type=TYPE_INT;
  m_params[1].integer_value=Input[0];
  m_params[2].type=TYPE_INT;
  m_params[2].integer_value=Input[1];
  m_params[3].type=TYPE_INT;
  m_params[3].integer_value=Input[2];
  m_params[4].type=TYPE_INT;
  m_params[4].integer_value=Input[3];
  m_params[5].type=TYPE_DOUBLE;
  m_params[5].double_value=Input[4];
  m_params[6].type=TYPE_INT;
  m_params[6].integer_value=Input[5];
  m_params[7].type=TYPE_INT;
  m_params[7].integer_value=Input[6];
  m_params[8].type=TYPE_DOUBLE;
  m_params[8].double_value=Input[7];
  m_params[9].type=TYPE_DOUBLE;
  m_params[9].double_value=Input[8];
  }
