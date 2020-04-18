//+------------------------------------------------------------------+
//|                                 Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include <..\Experts\BacktestExpert\Signal\PriceCrossInvertedSignal.mqh>
#define PRODUCE_SignalPlombiers PRODUCE("Plombiers", CSignalPlombiers)

class CSignalPlombiers : public CPriceCrossInvertedSignal {
public:
  CSignalPlombiers(void);
  virtual void      CSignalPlombiers::ParamsFromInput(double &Input[]);
};

CSignalPlombiers::CSignalPlombiers(void) {
  m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
  m_buffers[0] = 5;
  }

void CSignalPlombiers::ParamsFromInput(double &Input[]) {
  m_params_size = 14;
  ArrayResize(m_params, m_params_size);
  m_params[0].type=TYPE_STRING;
  m_params[0].string_value="Indi\plombiers-indicator.ex5";
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
  m_params[8].type=TYPE_INT;
  m_params[8].integer_value=Input[7];
  m_params[9].type=TYPE_INT;
  m_params[9].integer_value=Input[8];
  m_params[10].type=TYPE_INT;
  m_params[10].integer_value=Input[9];
  m_params[11].type=TYPE_INT;
  m_params[11].integer_value=Input[10];
  m_params[12].type=TYPE_INT;
  m_params[12].integer_value=Input[11];
  m_params[13].type=TYPE_INT;
  m_params[13].integer_value=Input[12];
  }
