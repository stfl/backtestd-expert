//+------------------------------------------------------------------+
//|                                     Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include "SaturationSignal.mqh"
//+------------------------------------------------------------------+

class CSaturationLevelsSignal : public CSaturationSignal {
protected:
  CIndicatorBuffer *m_buf_up;
  double m_level_up_enter;
  double m_level_down_enter;

protected:
  virtual bool InitIndicatorBuffers();
  virtual ENUM_REGION UpdateRegion();
};

ENUM_REGION CSaturationLevelsSignal::UpdateRegion() {
  int idx = StartIndex();
  if (m_buf_up.At(idx) > m_level_up_enter) {
     m_region = LongRegion;
  } else if (m_buf_up.At(idx) <= m_level_down_enter) {
     m_region = ShortRegion;
  } else {
     m_region = NeutralRegion;
  }
  return m_region;
}

bool CSaturationLevelsSignal::InitIndicatorBuffers() {
  m_buf_up = m_indicator.At(m_buffers[0]);
  m_level_up_enter = m_config[0];
  m_level_down_enter = m_config[1];
  m_signal_on_region_leave = (bool)m_config[2];
  return true;
}
