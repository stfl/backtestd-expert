//+------------------------------------------------------------------+
//|                                 Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include <backtestd\SignalClass\ZeroLineCrossSignal.mqh>
#define PRODUCE_SignalChaikin PRODUCE("Chaikin", CSignalChaikin)

class CSignalChaikin : public CZeroLineCrossSignal {
public:
  CSignalChaikin(void);
  virtual void      CSignalChaikin::ParamsFromInput(double &Input[]);
  virtual bool      ValidationInputs(double &Signal_double[]);
};

CSignalChaikin::CSignalChaikin(void) {
  m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
  m_buffers[0] = 0;
  }

bool CSignalChaikin::ValidationInputs(double &Input[]) {
  // SlowMA    - FastMA 
  if (Input[1] - Input[0] <= 2)
    return false;
  return true;
}

void CSignalChaikin::ParamsFromInput(double &Input[]) {
  m_indicator_type = IND_CHAIKIN;
   
  m_params_size = 4;
  ArrayResize(m_params, m_params_size);
  m_params[0].type=TYPE_INT;
  m_params[0].integer_value=(int)Input[0];
  m_params[1].type=TYPE_INT;
  m_params[1].integer_value=(int)Input[1];
  m_params[2].type=TYPE_INT;
  m_params[2].integer_value=(int)Input[2];
  m_params[3].type=TYPE_INT;
  m_params[3].integer_value=(int)Input[3];
  }
