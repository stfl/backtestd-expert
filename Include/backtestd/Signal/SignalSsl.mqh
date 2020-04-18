//+------------------------------------------------------------------+
//|                                 Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include <backtestd\SignalClass\SemaphoreSignal.mqh>
#define PRODUCE_SignalSsl PRODUCE("Ssl", CSignalSsl)

class CSignalSsl : public CSemaphoreSignal {
public:
  CSignalSsl(void);
  virtual void      CSignalSsl::ParamsFromInput(double &Input[]);
};

CSignalSsl::CSignalSsl(void) {
  m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
  m_buffers[0] = 2;
  m_buffers[1] = 3;
  }

void CSignalSsl::ParamsFromInput(double &Input[]) {
  m_params_size = 2;
  ArrayResize(m_params, m_params_size);
  m_params[0].type=TYPE_STRING;
  m_params[0].string_value="ssl.ex5";
  m_params[1].type=TYPE_INT;
  m_params[1].integer_value=Input[0];
  }
