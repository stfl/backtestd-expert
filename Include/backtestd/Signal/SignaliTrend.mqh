//+------------------------------------------------------------------+
//|                                 Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include <..\Experts\BacktestExpert\Signal\ColorChangeSignal.mqh>
#define PRODUCE_SignaliTrend PRODUCE("iTrend", CSignaliTrend)

class CSignaliTrend : public CColorChangeSignal {
public:
  CSignaliTrend(void);
  virtual void      CSignaliTrend::ParamsFromInput(double &Input[]);
};

CSignaliTrend::CSignaliTrend(void) {
  m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
  m_buffers[0] = 7;
  m_config[0] = 0;
  m_config[1]    = 1;
  m_config[2]  = 2;
  }

void CSignaliTrend::ParamsFromInput(double &Input[]) {
  m_params_size = 7;
  ArrayResize(m_params, m_params_size);
  m_params[0].type=TYPE_STRING;
  m_params[0].string_value="Indi\iTrend.ex5";
  m_params[1].type=TYPE_DOUBLE;
  m_params[1].integer_value=Input[0];
  m_params[2].type=TYPE_DOUBLE;
  m_params[2].double_value=Input[1];
  m_params[3].type=TYPE_DOUBLE;
  m_params[3].double_value=Input[2];
  m_params[4].type=TYPE_DOUBLE;
  m_params[4].integer_value=Input[3];
  m_params[5].type=TYPE_DOUBLE;
  m_params[5].integer_value=Input[4];
  m_params[6].type=TYPE_DOUBLE;
  m_params[6].double_value=Input[5];
  }
