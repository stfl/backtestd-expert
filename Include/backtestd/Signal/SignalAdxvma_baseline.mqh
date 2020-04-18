//+------------------------------------------------------------------+
//|                                 Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include <..\Experts\BacktestExpert\Signal\PriceCrossSignal.mqh>
#define PRODUCE_SignalAdxvma_baseline PRODUCE("Adxvma_baseline", CSignalAdxvma_baseline)

class CSignalAdxvma_baseline : public CPriceCrossSignal {
public:
  CSignalAdxvma_baseline(void);
  virtual void      CSignalAdxvma_baseline::ParamsFromInput(double &Input[]);
};

CSignalAdxvma_baseline::CSignalAdxvma_baseline(void) {
  m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
  m_buffers[0] = 0;
  }

void CSignalAdxvma_baseline::ParamsFromInput(double &Input[]) {
  m_params_size = 3;
  ArrayResize(m_params, m_params_size);
  m_params[0].type=TYPE_STRING;
  m_params[0].string_value="Indi\adxvma_1_1.ex5";
  m_params[1].type=TYPE_INT;
  m_params[1].integer_value=Input[0];
  m_params[2].type=TYPE_INT;
  m_params[2].integer_value=Input[1];
  }
