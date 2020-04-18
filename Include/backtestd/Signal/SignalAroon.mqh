//+------------------------------------------------------------------+
//|                                 Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include <..\Experts\BacktestExpert\Signal\TwoLinesCrossSignal.mqh>
#define PRODUCE_SignalAroon PRODUCE("Aroon", CSignalAroon)

class CSignalAroon : public CTwoLinesCrossSignal {
public:
  CSignalAroon(void);
  virtual void      CSignalAroon::ParamsFromInput(double &Input[]);
};

CSignalAroon::CSignalAroon(void) {
  m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
  m_buffers[0] = 0;
  m_buffers[1] = 1;
  }

void CSignalAroon::ParamsFromInput(double &Input[]) {
  m_params_size = 2;
  ArrayResize(m_params, m_params_size);
  m_params[0].type=TYPE_STRING;
  m_params[0].string_value="Indi\Aroon_Up_Down.ex5";
  m_params[1].type=TYPE_INT;
  m_params[1].integer_value=Input[0];
  }
