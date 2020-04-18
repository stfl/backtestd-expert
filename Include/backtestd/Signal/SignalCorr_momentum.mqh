//+------------------------------------------------------------------+
//|                                 Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include <..\Experts\BacktestExpert\Signal\ColorChangeSignal.mqh>
#define PRODUCE_SignalCorr_momentum PRODUCE("Corr_momentum", CSignalCorr_momentum)

class CSignalCorr_momentum : public CColorChangeSignal {
public:
  CSignalCorr_momentum(void);
  virtual void      CSignalCorr_momentum::ParamsFromInput(double &Input[]);
};

CSignalCorr_momentum::CSignalCorr_momentum(void) {
  m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
  m_buffers[0] = 8;
  m_config[0] = 0;
  m_config[1]    = 1;
  m_config[2]  = 2;
  }

void CSignalCorr_momentum::ParamsFromInput(double &Input[]) {
  m_params_size = 8;
  ArrayResize(m_params, m_params_size);
  m_params[0].type=TYPE_STRING;
  m_params[0].string_value="Indi\Corr_momentum.ex5";
  m_params[1].type=TYPE_INT;
  m_params[1].integer_value=Input[0];
  m_params[2].type=TYPE_INT;
  m_params[2].integer_value=Input[1];
  m_params[3].type=TYPE_INT;
  m_params[3].integer_value=Input[2];
  m_params[4].type=TYPE_INT;
  m_params[4].integer_value=Input[3];
  m_params[5].type=TYPE_INT;
  m_params[5].integer_value=Input[4];
  m_params[6].type=TYPE_INT;
  m_params[6].integer_value=Input[5];
  m_params[7].type=TYPE_INT;
  m_params[7].integer_value=Input[6];
  }
