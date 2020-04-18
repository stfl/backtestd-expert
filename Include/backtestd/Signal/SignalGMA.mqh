//+------------------------------------------------------------------+
//|                                 Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include <..\Experts\BacktestExpert\Signal\PriceCrossSignal.mqh>
#define PRODUCE_SignalGMA PRODUCE("GMA", CSignalGMA)

class CSignalGMA : public CPriceCrossSignal {
public:
  CSignalGMA(void);
  virtual void      CSignalGMA::ParamsFromInput(double &Input[]);
};

CSignalGMA::CSignalGMA(void) {
  m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
  m_buffers[0] = 1;
  }

void CSignalGMA::ParamsFromInput(double &Input[]) {
  m_params_size = 3;
  ArrayResize(m_params, m_params_size);
  m_params[0].type=TYPE_STRING;
  m_params[0].string_value="Indi\YGMA.ex5";
  m_params[1].type=TYPE_INT;
  m_params[1].integer_value=Input[0];
  m_params[2].type=TYPE_INT;
  m_params[2].integer_value=Input[1];
  }
